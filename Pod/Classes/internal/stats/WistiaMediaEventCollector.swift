//
//  WistiaEventCollector.swift
//  Playback
//
//  Created by Daniel Spinosa on 12/31/15.
//  Copyright © 2015 Wistia, Inc. All rights reserved.
//
//  A WistiaMediaEventCollector should be associated with a single player-media tuple.  If the same piece
//  of media is loaded in a different player, a new WistiaMediaEventCollector should be used.  Similarly,
//  if a single player supports and loads multiple medias, a different WistiaMediaEventCollector should
//  be used for each different media.

import UIKit
import AdSupport

internal class WistiaMediaEventCollector : WistiaEventCollector {

    //MARK: - Private Constants

    //Update events will be spaced out between 1s and this (plus additional jitter of 0-1s)
    private let UpdateEventResolution = UInt32(4)
    //Seek events will only be recorded when the video delta is greater than this
    private let SeekEventDelta = Double(5)

    //MARK: - Internal State and Initializers

    internal var manager:WistiaStatsManager?

    internal private(set) var eventEndpoint:NSURL!
    internal private(set) var eventMetadata = [String: AnyObject]()

    internal init?(media:WistiaMedia, referrer:String?){
        self.initTime = NSDate()
        self.eventEndpoint = media.distilleryURL
        self.media = media
        self.eventMetadata = [
            //TODO: Get this from a module versions file
            "sdk_version": "iOS,0.1",
            "account_key": media.accountKey,
            "media_id": media.mediaKey,
            //on web, event_key is unique per media, per per player, per page, per page load
            "event_key": "\(self.dynamicType.guidPrefix())_\(NSUUID().UUIDString)",
            "media_duration": String(media.duration),
            "visitor_version": "1",
            //constant for this viewer (unless and until they reset their device)
            "session_id": self.dynamicType.sessionID()]
        if let ref = referrer {
            //on web, referrer is the url of the current page.
            //on iOS this should be a universal link to the point in the app where the video is played
            //but ultimately it's up to the developer
            eventMetadata["referrer"] = ref
        }

        //If we do not have a valid stats endpoint, don't collect events
        if self.eventEndpoint.host == nil {
            return nil
        }
    }

    internal func removeEventDetails() -> [[String: AnyObject]] {
        guard !eventDetails.isEmpty else { return [[String: AnyObject]]() }

        var eventDetailsJSONDict = [[String: AnyObject]]()
        for event in eventDetails {
            eventDetailsJSONDict.append(event.toJSON())
        }
        eventDetails.removeAll()
        return eventDetailsJSONDict
    }

    //MARK: - Public API

    var associatedEmail:String? {
        get {
            if let em = eventMetadata["email"] as? String {
                return em
            } else {
                return nil
            }
        }
        set(em) {
            eventMetadata["email"] = em
        }
    }

    var foreignData:String? {
        get {
            if let fd = eventMetadata["foreignData"] as? String {
                return fd
            } else {
                return nil
            }
        }
        set(fd) {
            eventMetadata["foreignData"] = fd
        }
    }

    func logEvent(event:EventType, value:String){
        //Reduce frequency of .Update and .Seek events
        guard shouldSendEvent(event, value: value) else { return }

        let lastAccount:String?
        let lastMedia:String?
        if event == .Initialized || event == .Play {
            //The IDs used for account and media cannot collide.  accountKey and hashedID satisfy that requirement.
            lastAccount = WistiaMediaEventCollector.recordTimeOfEvent(event, forID: media.accountKey) ?? "none"
            lastMedia = WistiaMediaEventCollector.recordTimeOfEvent(event, forID: media.hashedID) ?? "none"
        } else {
            lastAccount = nil
            lastMedia = nil
        }

        eventDetails.append(EventDetails(event: event, value: value, timeDelta: msSinceInit(), lastAccountInstance: lastAccount, lastMediaInstance: lastMedia))
    }

    enum EventType : String {
        case Initialized = "initialized"
        case Play = "play"
        case Pause = "pause"
        case End = "end"
        case Seek = "seek"
        case PlaybackRateChange = "playbackRateChange"
        case Update = "update"
        case LookVector = "cameraPosition"
    }

    //MARK: - Private Data Structures

    private var initTime:NSDate!

    private var media:WistiaMedia!

    private var eventDetails = [EventDetails]()

    private struct EventDetails {
        private var event:EventType
        //value is generally the time at which the event took place
        private var value:String
        //on web this is time since page loaded
        private var timeDelta:String

        private var lastAccountInstance:String?
        private var lastMediaInstance:String?

        private func toJSON() -> [String: String] {
            var json = ["key" : event.rawValue,
                "value" : value,
                "timeDelta" : timeDelta]
            if let lastAccount = lastAccountInstance, lastMedia = lastMediaInstance {
                json["lastAccountInstance"] = lastAccount
                json["lastMediaInstance"] = lastMedia
            }
            return json
        }
    }

    private var nextUpdateEventOkayToSendAfter = NSDate()
    private var lastSeekValue:Double = 0

    //MARK: - Private Helpers

    // Cleaner to reduce the resolution of some events in here, instead of in the WistiaPlayer.
    // Reducing resolution of .Seek events to a delta of 5s
    // Reducing resultion of .Update events to a random amount of time between 1s and 5.999s, this introduces
    //  jitter to improve the look of heatmaps.
    private func shouldSendEvent(event:EventType, value:String) -> Bool {
        switch (event){
        case .Update:
            if (NSDate().timeIntervalSinceDate(nextUpdateEventOkayToSendAfter) > 0){
                nextUpdateEventOkayToSendAfter = NSDate(timeIntervalSinceNow: NSTimeInterval(Double(1 + arc4random_uniform(UpdateEventResolution)) + drand48()))
                return true
            } else {
                return false
            }

        case .Seek:
            if let seekTime = Double(value) where abs(seekTime - lastSeekValue) > SeekEventDelta {
                lastSeekValue = seekTime
                return true
            } else {
                return false
            }

        default:
            return true
        }
    }

    private func msSinceInit() -> String {
        let timeSinceInit = NSDate().timeIntervalSinceDate(initTime)
        return String(format: "%f", timeSinceInit*1000)
    }

    //MARK: Static

    private static let statsUserDefaults = NSUserDefaults(suiteName: "WistiaStats")

    //Returns the number of seconds since this was last called for the given id and event,
    //nil if never called for this event on the given ID.
    //Expect "id" to uniquely identify an account or a media without collision.
    private static func recordTimeOfEvent(event:EventType, forID id:String) -> String? {
        let now = NSDate()
        let key = "\(id)-\(event.rawValue)"
        var lastTimeInSeconds:String? = nil
        if let lastRecord = statsUserDefaults?.objectForKey(key) as? NSDate {
            lastTimeInSeconds = String(format:"%f", now.timeIntervalSinceDate(lastRecord))
        }
        statsUserDefaults?.setObject(now, forKey: key)
        return lastTimeInSeconds
    }

    private static func sessionID() -> String {
        let key = "sessionID"
        if let savedID = statsUserDefaults?.stringForKey(key) {
            return savedID
        }

        let newID:String
        if let adId = ASIdentifierManager.sharedManager().advertisingIdentifier where ASIdentifierManager.sharedManager().advertisingTrackingEnabled {
            //on web, this tracks user across all players on all pages in a single browser
            newID = "\(guidPrefix())_\(adId.UUIDString)"
        } else {
            newID = "\(guidPrefix())_\(NSUUID().UUIDString)"
        }
        statsUserDefaults?.setObject(newID, forKey: key)

        return newID
    }

    private static func guidPrefix() -> String {
        return "v\(guidPrefixDateFormatter.stringFromDate(NSDate()))"
    }

    private static let guidPrefixDateFormatter:NSDateFormatter = {
        let df = NSDateFormatter()
        df.dateFormat = "YYYMMDD"
        return df
    }()

}

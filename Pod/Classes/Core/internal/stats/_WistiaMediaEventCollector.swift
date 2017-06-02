//
//  _WistiaEventCollector.swift
//  WistiaKit internal
//
//  Created by Daniel Spinosa on 12/31/15.
//  Copyright © 2016 Wistia, Inc. All rights reserved.
//
//  A WistiaMediaEventCollector should be associated with a single player-media tuple.  If the same piece
//  of media is loaded in a different player, a new WistiaMediaEventCollector should be used.  Similarly,
//  if a single player supports and loads multiple medias, a different WistiaMediaEventCollector should
//  be used for each different media.

import UIKit
import AdSupport

public class WistiaMediaEventCollector : WistiaEventCollector {

    //MARK: - Private Constants

    //Update events will be spaced out between 1s and this (plus additional jitter of 0-1s)
    fileprivate let UpdateEventResolution = UInt32(4)
    //Seek events will only be recorded when the video delta is greater than this
    fileprivate let SeekEventDelta = Double(5)

    //MARK: - Internal State and Initializers

    internal var manager:WistiaStatsManager?

    internal fileprivate(set) var eventEndpoint: URL!
    internal fileprivate(set) var eventMetadata = [String: Any]()

    internal init?(media:WistiaMedia, referrer:String?){
        //If we do not have a valid stats endpoint, don't collect events
        guard let distilleryURL = media.distilleryURL else { return nil }

        self.initTime = Date()
        self.eventEndpoint = distilleryURL
        self.media = media
        self.eventMetadata = [
            //TODO: Get this from a module versions file
            "sdk_version": "iOS,0.1",
            //on web, event_key is unique per media, per per player, per page, per page load
            "event_key": "\(type(of: self).guidPrefix())_\(UUID().uuidString)",
            "media_duration": String(media.duration != nil ? media.duration! : Float(0.0)),
            "visitor_version": "1",
            //constant for this viewer (unless and until they reset their device)
            "session_id": type(of: self).sessionID()]
        if let ak = media.accountKey {
            eventMetadata["account_key"] = ak
        }
        if let mk = media.mediaKey {
            eventMetadata["media_id"] = mk
        }
        if let ref = referrer {
            //on web, referrer is the url of the current page.
            //on iOS this should be a universal link to the point in the app where the video is played
            //but ultimately it's up to the developer
            eventMetadata["referrer"] = ref
        }
    }

    internal func removeEventDetails() -> [[String: Any]] {
        guard !eventDetails.isEmpty else { return [[String: Any]]() }

        var eventDetailsJSONDict = [[String: Any]]()
        for event in eventDetails {
            eventDetailsJSONDict.append(event.toJSON() as [String : Any])
        }
        eventDetails.removeAll()
        return eventDetailsJSONDict
    }

    //MARK: - Public API

    public var associatedEmail:String? {
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

    public var foreignData:String? {
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

    public func log(_ event:EventType, withValue value:String){
        //Reduce frequency of .Update and .Seek events
        guard shouldSend(event, withValue: value) else { return }

        let lastAccount:String?
        let lastMedia:String?
        if let ak = media.accountKey , event == .initialized || event == .play {
            //The IDs used for account and media cannot collide.  accountKey and hashedID satisfy that requirement.
            lastAccount = WistiaMediaEventCollector.recordTimeOf(event, forID: ak) ?? "none"
            lastMedia = WistiaMediaEventCollector.recordTimeOf(event, forID: media.hashedID) ?? "none"
        } else {
            lastAccount = nil
            lastMedia = nil
        }

        eventDetails.append(EventDetails(event: event, value: value, timeDelta: msSinceInit(), lastAccountInstance: lastAccount, lastMediaInstance: lastMedia))
    }

    public enum EventType : String {
        case initialized = "initialized"
        case play = "play"
        case pause = "pause"
        case end = "end"
        case seek = "seek"
        case playbackRateChange = "playbackRateChange"
        case update = "update"
        case lookVector = "cameraPosition"
    }

    //MARK: - Private Data Structures

    fileprivate var initTime: Date!

    fileprivate var media: WistiaMedia!

    fileprivate var eventDetails = [EventDetails]()

    fileprivate struct EventDetails {
        fileprivate var event:EventType
        //value is generally the time at which the event took place
        fileprivate var value: String
        //on web this is time since page loaded
        fileprivate var timeDelta: String

        fileprivate var lastAccountInstance: String?
        fileprivate var lastMediaInstance: String?

        fileprivate func toJSON() -> [String: String] {
            var json = ["key" : event.rawValue,
                "value" : value,
                "timeDelta" : timeDelta]
            if let lastAccount = lastAccountInstance, let lastMedia = lastMediaInstance {
                json["lastAccountInstance"] = lastAccount
                json["lastMediaInstance"] = lastMedia
            }
            return json
        }
    }

    fileprivate var nextUpdateEventOkayToSendAfter = Date()
    fileprivate var lastSeekValue:Double = 0

    //MARK: - Private Helpers

    // Cleaner to reduce the resolution of some events in here, instead of in the WistiaPlayer.
    // Reducing resolution of .Seek events to a delta of 5s
    // Reducing resultion of .Update events to a random amount of time between 1s and 5.999s, this introduces
    //  jitter to improve the look of heatmaps.
    fileprivate func shouldSend(_ event:EventType, withValue value:String) -> Bool {
        switch (event){
        case .update:
            if (Date().timeIntervalSince(nextUpdateEventOkayToSendAfter) > 0){
                nextUpdateEventOkayToSendAfter = Date(timeIntervalSinceNow: TimeInterval(Double(1 + arc4random_uniform(UpdateEventResolution)) + drand48()))
                return true
            } else {
                return false
            }

        case .seek:
            if let seekTime = Double(value), abs(seekTime - lastSeekValue) > SeekEventDelta {
                lastSeekValue = seekTime
                return true
            } else {
                return false
            }

        default:
            return true
        }
    }

    fileprivate func msSinceInit() -> String {
        let timeSinceInit = Date().timeIntervalSince(initTime)
        return String(format: "%f", timeSinceInit*1000)
    }

    //MARK: Static

    fileprivate static let statsUserDefaults = UserDefaults(suiteName: "WistiaStats")

    //Returns the number of seconds since this was last called for the given id and event,
    //nil if never called for this event on the given ID.
    //Expect "id" to uniquely identify an account or a media without collision.
    fileprivate static func recordTimeOf(_ event:EventType, forID id:String) -> String? {
        let now = Date()
        let key = "\(id)-\(event.rawValue)"
        var lastTimeInSeconds:String? = nil
        if let lastRecord = statsUserDefaults?.object(forKey: key) as? Date {
            lastTimeInSeconds = String(format:"%f", now.timeIntervalSince(lastRecord))
        }
        statsUserDefaults?.set(now, forKey: key)
        return lastTimeInSeconds
    }

    fileprivate static func sessionID() -> String {
        let key = "sessionID"
        if let savedID = statsUserDefaults?.string(forKey: key) {
            return savedID
        }

        let newID:String
        if let adId = ASIdentifierManager.shared().advertisingIdentifier, ASIdentifierManager.shared().isAdvertisingTrackingEnabled {
            //on web, this tracks user across all players on all pages in a single browser
            newID = "\(guidPrefix())_\(adId.uuidString)"
        } else {
            newID = "\(guidPrefix())_\(UUID().uuidString)"
        }
        statsUserDefaults?.set(newID, forKey: key)

        return newID
    }

    fileprivate static func guidPrefix() -> String {
        return "v\(guidPrefixDateFormatter.string(from: Date()))"
    }

    fileprivate static let guidPrefixDateFormatter:DateFormatter = {
        let df = DateFormatter()
        df.dateFormat = "YYYMMDD"
        return df
    }()

}

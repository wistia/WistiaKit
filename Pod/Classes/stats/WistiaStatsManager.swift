//
//  WistiaStatsManager.swift
//  Playback
//
//  Created by Daniel Spinosa on 12/31/15.
//  Copyright © 2015 Wistia, Inc. All rights reserved.
//
//  Manages a set of WistiaEventCollectors.  Periodically queries the event collectors to see if they have
//  new event details, sending them to the given endpoint.
//
//  The WistiaEventCollector maintains its own event endpoint and top-level metadata to be included with
//  each set of event details.  If you create your own WistiaEventCollector, be sure to register it with a 
//  WistiaStatsManager if you wish the event to be sent.  Normally, you get a WistiaEventCollector through
//  an instance method on the sharedInstance singleton of WistiaStatsManager.
//
//  The manager assumes a few things:
//  1) Events should be sent to <collector.eventEndpoint> as the Base64 encoded JSON value for the 'data' paramater.
//     That is:  POST <collector.eventEndpoint>?data=Base64.encode(JSON)
//  2) The JSON dictionary returned by WistiaEventCollector.eventMetadata() will be copied and used to build the JSON to be sent.
//     NB: It should not include event_details.
//  3) The JSON array returned by WistiaEventCollector.removeEventDetails() will be set as the value for the
//     key "event_details" at the top level of the data sent to the event endpoint (overriding anything at they key
//     if included in the eventMetadata)
//
//  TODO: Persist unsent events when we are terminated without the chance to send them.

import UIKit
import Alamofire

class WistiaStatsManager {

    //MARK: - Private Constants

    private static let StatsSendInterval = NSTimeInterval(5)
    private let EventTTL = 5

    //MARK: - Internal State and Initializers

    private var eventCollectors = [WistiaEventCollector]()
    private var eventsPending = [StatsEvent]()

    private var statsTimer:NSTimer?

    //MARK: - Public API

    static let sharedInstance:WistiaStatsManager = {
        let mgr = WistiaStatsManager()
        mgr.startTimer(StatsSendInterval)
        mgr.restoreEvents()
        return mgr
    }()

    func newEventCollectorForMedia(media:WistiaMedia, referrer:String) -> WistiaMediaEventCollector? {
        guard let mediaCollector = WistiaMediaEventCollector(media: media, referrer: referrer) else { return nil }

        eventCollectors.append(mediaCollector)
        mediaCollector.manager = self
        return mediaCollector
    }

    //MARK: - Private API

    init() {
        //Resign/Become Active just stops/starts timers
        NSNotificationCenter.defaultCenter().addObserverForName(UIApplicationWillResignActiveNotification, object: nil, queue: nil) { (note) -> Void in
            self.collectAndSend()
            self.statsTimer?.invalidate()
            self.statsTimer = nil
        }
        NSNotificationCenter.defaultCenter().addObserverForName(UIApplicationDidBecomeActiveNotification, object: nil, queue: nil) { (note) -> Void in
            self.startTimer(self.dynamicType.StatsSendInterval)
        }

        //Background persists events; Foreground restores events
        //By capturing lifecycle this way, we can ignore termination event
        NSNotificationCenter.defaultCenter().addObserverForName(UIApplicationDidEnterBackgroundNotification, object: nil, queue: nil) { (note) -> Void in
            self.collectEventDetails()
            self.persistEvents()
        }
        NSNotificationCenter.defaultCenter().addObserverForName(UIApplicationWillEnterForegroundNotification, object: nil, queue: nil) { (note) -> Void in
            self.restoreEvents()
        }
    }

    private func startTimer(timeInterval:NSTimeInterval) {
        guard statsTimer == nil else { return }
        statsTimer = NSTimer.scheduledTimerWithTimeInterval(timeInterval, target: self, selector: #selector(WistiaStatsManager.collectAndSend), userInfo: nil, repeats: true)
    }

    @objc private func collectAndSend() {
        collectEventDetails()
        sendPendingEvents()
    }

    private func collectEventDetails() {
        for collector in eventCollectors {
            let eventDetails = collector.removeEventDetails()
            if eventDetails.count > 0 {
                var event = collector.eventMetadata
                event["event_details"] = eventDetails
                eventsPending.append(StatsEvent(url: collector.eventEndpoint, json: event, ttl: EventTTL))
            }
        }
    }

    private func sendPendingEvents() {
        let eventsToSend = eventsPending
        eventsPending.removeAll()
        for event in eventsToSend {
            do {
                let jsonData = try NSJSONSerialization.dataWithJSONObject(event.json, options: NSJSONWritingOptions(rawValue: 0))

                Alamofire.request(.POST, event.url, parameters: nil, encoding: .Custom({ (requestConvertable, params) -> (NSMutableURLRequest, NSError?) in
                    let mutableRequest = requestConvertable.URLRequest.copy() as! NSMutableURLRequest
                    mutableRequest.HTTPBody = jsonData.base64EncodedDataWithOptions(NSDataBase64EncodingOptions(rawValue: 0))
                    return (mutableRequest, nil)
                }), headers: nil)
                    .response { request, response, data, error in
                        if error != nil {
                            print("ERROR sending stats: \(error)")
                            if event.ttl > 0 {
                                self.eventsPending.append(StatsEvent(url: event.url, json: event.json, ttl: event.ttl-1))
                            } else {
                                print("TTL=0, dropping event: \(event)")
                            }
                        }
                }
            } catch {
                print("ERROR: \(error)")
            }
        }
    }

    //MARK: Event Persistence

    static let persistenceFilename = "\(NSSearchPathForDirectoriesInDomains(.DocumentDirectory, .UserDomainMask, true)[0])/StatsManager.EventsPending"

    private func persistEvents() {
        NSKeyedArchiver.archiveRootObject(eventsPending, toFile: self.dynamicType.persistenceFilename)
        eventsPending.removeAll()
    }

    private func restoreEvents() {
        if let events = NSKeyedUnarchiver.unarchiveObjectWithFile(self.dynamicType.persistenceFilename) as? [StatsEvent] {
            do {
                try NSFileManager.defaultManager().removeItemAtPath(self.dynamicType.persistenceFilename)
                self.eventsPending.appendContentsOf(events)
            } catch {
                //how could this happen? not a critical error
            }
        }
    }
}

protocol WistiaEventCollector : class {
    //The manager that will process events held by this collector
    weak var manager:WistiaStatsManager? { get set }

    //Where all events are sent.  Should be constant for the life of a WistiaEventCollector.
    var eventEndpoint:NSURL! { get }

    //Top level metadata sent with all event details.  Should not include "event_details" key.
    var eventMetadata:[String: AnyObject] { get }

    //Array to populate event_details.  This array may be broken into multiple sub-arrays
    //and/or combined with other arrays from the same WistiaEventCollector before being sent.
    func removeEventDetails() -> [[String: AnyObject]]
}

//I used to use a nice simple tuple.  But that can't be easily persisted.  So now we have this big ugly ass class.
//
// It just stores the tupe of url-json-ttl.
//
// By making it an NSObject that conforms to NSCoding, it's easy to archive and unarchive.
// Cant' wait until they update that sort of stuff for Swift.  but until then, we get bonus LOC...
private class StatsEvent: NSObject, NSCoding {
    let url:NSURL
    let json:[String: AnyObject]
    let ttl: Int

    @objc init(url:NSURL, json:[String: AnyObject], ttl:Int) {
        self.url = url
        self.json = json
        self.ttl = ttl
    }

    // MARK: NSCoding

    @objc required convenience init?(coder decoder: NSCoder) {
        guard let url = decoder.decodeObjectForKey("url") as? NSURL,
            json = decoder.decodeObjectForKey("json") as? [String: AnyObject]
            else { return nil }
        let ttl = decoder.decodeInt32ForKey("ttl")
        self.init(url:url, json:json, ttl:Int(ttl))
    }

    @objc func encodeWithCoder(coder: NSCoder) {
        coder.encodeObject(self.url, forKey: "url")
        coder.encodeObject(self.json, forKey: "json")
        coder.encodeInt32(Int32(self.ttl), forKey: "ttl")
    }

}
//
//  _WistiaStatsManager.swift
//  WistiaKit internal
//
//  Created by Daniel Spinosa on 12/31/15.
//  Copyright © 2016 Wistia, Inc. All rights reserved.
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

import UIKit
import Alamofire

public class WistiaStatsManager {

    //MARK: - Private Constants

    fileprivate static let StatsSendInterval = TimeInterval(5)
    fileprivate let EventTTL = 5

    //MARK: - Internal State and Initializers

    fileprivate var eventCollectors = [WistiaEventCollector]()
    fileprivate var eventsPending = [StatsEvent]()

    fileprivate var statsTimer:Timer?

    //MARK: - Public API

    public static let sharedInstance:WistiaStatsManager = {
        let mgr = WistiaStatsManager()
        mgr.startTimer(withInterval: StatsSendInterval)
        mgr.restoreEvents()
        return mgr
    }()

    public func newEventCollector(forMedia media:WistiaMedia, withReferrer referrer: String) -> WistiaMediaEventCollector? {
        guard let mediaCollector = WistiaMediaEventCollector(media: media, referrer: referrer) else { return nil }

        eventCollectors.append(mediaCollector)
        mediaCollector.manager = self
        startTimer(withInterval: WistiaStatsManager.StatsSendInterval)
        return mediaCollector
    }

    public func removeEventCollector(_ eventCollector: WistiaMediaEventCollector?) {
        guard let collector = eventCollector else { return }

        if let removeIdx = eventCollectors.index(where: { $0 === collector }) {
            eventCollectors.remove(at: removeIdx)
            if eventCollectors.count == 0 {
                stopTimer()
            }
        }
    }

    //MARK: - Private API

    init() {
        //Resign/Become Active just stops/starts timers
        NotificationCenter.default.addObserver(forName: NSNotification.Name.UIApplicationWillResignActive,
                                               object: nil,
                                               queue: nil) { [weak self] (note) -> Void in
            self?.collectAndSend()
            self?.stopTimer()
        }
        NotificationCenter.default.addObserver(forName: NSNotification.Name.UIApplicationDidBecomeActive,
                                               object: nil,
                                               queue: nil) { [weak self] (note) -> Void in
            self?.startTimer(withInterval: WistiaStatsManager.StatsSendInterval)
        }

        //Background persists events; Foreground restores events
        //By capturing lifecycle this way, we can ignore termination event
        NotificationCenter.default.addObserver(forName: NSNotification.Name.UIApplicationDidEnterBackground,
                                               object: nil,
                                               queue: nil) { [weak self] (note) -> Void in
            self?.collectEventDetails()
            self?.persistEvents()
        }
        NotificationCenter.default.addObserver(forName: NSNotification.Name.UIApplicationWillEnterForeground,
                                               object: nil,
                                               queue: nil) { [weak self] (note) -> Void in
            self?.restoreEvents()
        }
    }

    fileprivate func startTimer(withInterval timeInterval:TimeInterval) {
        guard statsTimer == nil else { return }

        /*
         //When we remove ios 9 support...
        if #available(iOS 10.0, *) {
            statsTimer = Timer.scheduledTimer(withTimeInterval: timeInterval, repeats: true) { _ in
                self.collectEventDetails()
                self.sendPendingEvents()
            }
        }
         */
        statsTimer = Timer.scheduledTimer(timeInterval: timeInterval, target: self, selector: #selector(WistiaStatsManager.collectAndSend), userInfo: nil, repeats: true)
    }

    fileprivate func stopTimer() {
        statsTimer?.invalidate()
        statsTimer = nil
    }

    @objc private func collectAndSend() {
        collectEventDetails()
        sendPendingEvents()
    }

    fileprivate func collectEventDetails() {
        for collector in eventCollectors {
            let eventDetails = collector.removeEventDetails()
            if eventDetails.count > 0 {
                var event = collector.eventMetadata
                event["event_details"] = eventDetails
                eventsPending.append(StatsEvent(url: collector.eventEndpoint, json: event, ttl: EventTTL))
            }
        }
    }

    fileprivate func sendPendingEvents() {
        let eventsToSend = eventsPending
        eventsPending.removeAll()
        for event in eventsToSend {
            Alamofire.request(event.url, method: .post, parameters: event.json, encoding: JsonToBase64InBodyEncoder(json: event.json), headers: nil)
                .response(completionHandler: { (dataResponse) in
                    if dataResponse.error != nil {
                        print("ERROR sending stats: \(String(describing: dataResponse.error))")
                        if event.ttl > 0 {
                            self.eventsPending.append(StatsEvent(url: event.url, json: event.json, ttl: event.ttl-1))
                        } else {
                            print("TTL=0, dropping event: \(event)")
                        }
                    }
                })
        }
    }

    //MARK: Event Persistence

    static let persistenceFilename = "\(NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)[0])/StatsManager.EventsPending"

    fileprivate func persistEvents() {
        NSKeyedArchiver.archiveRootObject(eventsPending, toFile: type(of: self).persistenceFilename)
        eventsPending.removeAll()
    }

    fileprivate func restoreEvents() {
        do {
            if let events = try NSKeyedUnarchiver.unarchiveObject(withFile: WistiaStatsManager.persistenceFilename) as? [StatsEvent] {
                self.eventsPending.append(contentsOf: events)
            }
        }
        catch {
            //tho it's not marked as such, NSKeyedUnarchiver.unarchiveObject can throw
        }

        //delete that file every time, especially if it couldn't be unarchived
        do {
            try FileManager.default.removeItem(atPath: WistiaStatsManager.persistenceFilename)
        }
        catch {
            //ignore
        }
    }
}

internal protocol WistiaEventCollector : class {
    //The manager that will process events held by this collector
    weak var manager: WistiaStatsManager? { get set }

    //Where all events are sent.  Should be constant for the life of a WistiaEventCollector.
    var eventEndpoint: URL! { get }

    //Top level metadata sent with all event details.  Should not include "event_details" key.
    var eventMetadata: [String: Any] { get }

    //Array to populate event_details.  This array may be broken into multiple sub-arrays
    //and/or combined with other arrays from the same WistiaEventCollector before being sent.
    func removeEventDetails() -> [[String: Any]]
}

//I used to use a nice simple tuple.  But that can't be easily persisted.  So now we have this big ugly ass class.
//
// It just stores the tupe of url-json-ttl.
//
// By making it an NSObject that conforms to NSCoding, it's easy to archive and unarchive.
// Cant' wait until they update that sort of stuff for Swift.  but until then, we get bonus LOC...
fileprivate class StatsEvent: NSObject, NSCoding {
    let url: URL
    let json: [String: Any]
    let ttl: Int

    @objc init(url: URL, json: [String: Any], ttl:Int) {
        self.url = url
        self.json = json
        self.ttl = ttl
    }

    // MARK: NSCoding

    @objc required convenience init?(coder decoder: NSCoder) {
        guard let url = decoder.decodeObject(forKey: "url") as? URL,
            let json = decoder.decodeObject(forKey: "json") as? [String: AnyObject]
            else { return nil }
        let ttl = decoder.decodeInt32(forKey: "ttl")
        self.init(url:url, json:json, ttl:Int(ttl))
    }

    @objc func encode(with coder: NSCoder) {
        coder.encode(self.url, forKey: "url")
        coder.encode(self.json, forKey: "json")
        coder.encode(Int32(self.ttl), forKey: "ttl")
    }

}

// Stats endpoint expects payload in body, base64 encoded
private class JsonToBase64InBodyEncoder : ParameterEncoding {

    let json: [String: Any]

    init(json: [String: Any]) {
        self.json = json
    }

    func encode(_ urlRequest: URLRequestConvertible, with parameters: Parameters?) throws -> URLRequest {
        var urlReq = try urlRequest.asURLRequest()
        let jsonData = try JSONSerialization.data(withJSONObject: json, options: JSONSerialization.WritingOptions(rawValue: 0))
        urlReq.httpBody = jsonData.base64EncodedData()
        return urlReq
    }
    
}

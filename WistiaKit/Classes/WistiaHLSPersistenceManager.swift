//
//  WistiaHLSPersistenceManager.swift
//  WistiaKit
//
//  Created by Daniel Spinosa on 11/14/17.
//

import AVKit

public protocol WistiaHLSPersistenceDownloadObserver {
    func download(forHashedID hashedID: HashedID, hasState state: Media.DownloadState, withProgress progress: Double?)
}

public class WistiaHLSPersistenceManager: NSObject, PersistenceManager {

    private var didRestorePersistenceManager = false

    private var assetDownloadURLSession: AVAssetDownloadURLSession!

    private struct DownloadMetadata {
        let hashedID: HashedID

        var progress: Double
        mutating func setProgress(_ newProgress: Double) {
            self.progress = newProgress
        }

        var observers: [WistiaHLSPersistenceDownloadObserver]
        mutating func add(observer: WistiaHLSPersistenceDownloadObserver) {
            self.observers.append(observer)
        }

        init(hashedID: HashedID) {
            self.hashedID = hashedID
            self.progress = 0
            self.observers = [WistiaHLSPersistenceDownloadObserver]()
        }
    }
    private var activeDownloads = [AVAggregateAssetDownloadTask: DownloadMetadata]()

    // Download destination is updated async, so we need to track it
    private var willDownloadToUrlMap = [AVAggregateAssetDownloadTask: URL]()

    //MARK: - Initialization

    public static var `default`: WistiaHLSPersistenceManager = {
        return WistiaHLSPersistenceManager()
    }()

    private override init() {
        super.init()

        let backgroundConfiguration = URLSessionConfiguration.background(withIdentifier: "WistiaHLSPersistenceManager-BackgroundURLSessionIdentifier")

        //NB: if you don't specify the delegate queue, need to make sure any shared state (ie. activeDownloads)
        //is synchronized for parallel access
        self.assetDownloadURLSession =
            AVAssetDownloadURLSession(configuration: backgroundConfiguration,
                                      assetDownloadDelegate: self, delegateQueue: OperationQueue.main)

        restorePersistenceManager()
    }

    //MARK: - Public API

    public func downloadState(forMedia media: Media) -> Media.DownloadState {
        precondition(media.id != nil, "Media must have HashedID")
        guard media.id != nil else { return .persistenceNotConfigured }

        if localAsset(forMedia: media) != nil {
            return .downloaded
        }
        if asset(forMedia: media) != nil {
            return .downloading
        }
        return .notDownloaded
    }

    /// Observe an active download for the given `Media`.
    /// The result of this method will be a call to the observer with the current download progress - if
    /// the `Media` is downloading.  If it isn't, the observer will be notified of `.persistenceNotConfigured`, indicating
    /// that a download could be started and the subsequently observerd.
    /// On error, the observer will be notified of `.persistenceNotAvailable`.
    public func addObserver(_ observer: WistiaHLSPersistenceDownloadObserver, forMedia media: Media) {
        precondition(media.id != nil, "Media must have HashedID")
        guard let id = media.id else {
            observer.download(forHashedID: "", hasState: .persistenceNotAvailable, withProgress: nil)
            return
        }

        if downloadState(forMedia: media) == .downloaded {
            observer.download(forHashedID: id, hasState: .downloaded, withProgress: 1.0)
            return
        }

        for (task, downloadMetadata) in activeDownloads where downloadMetadata.hashedID == id {
            activeDownloads[task]?.add(observer: observer)
            observer.download(forHashedID: id, hasState: .downloading, withProgress: downloadMetadata.progress)
            return
        }
        observer.download(forHashedID: id, hasState: .persistenceNotConfigured, withProgress: nil)
    }

    /// Returns the percentage complete of the download.  `nil` if there is no download in in progress for the given Media.
    public func downloadProgress(forMedia media: Media) -> Double? {
        precondition(media.id != nil, "Media must have HashedID")
        guard let id = media.id else { return nil }

        for (_, downloadMetadata) in activeDownloads where downloadMetadata.hashedID == id {
            return downloadMetadata.progress
        }

        return nil
    }

    /// returns a completed download, stored on-disk, for the given Media
    public func localAsset(forMedia media: Media) -> AVURLAsset? {
        precondition(media.id != nil, "Media must have HashedID")
        guard let id = media.id else { return nil }
        guard let localAssetUrl = localAssetUrl(forHashedId: id) else { return nil }

        return AVURLAsset(url: localAssetUrl)
    }

    /// returns an in-progress or completed download for the given Media.
    public func asset(forMedia media: Media) -> AVURLAsset? {
        precondition(media.id != nil, "Media must have HashedID")
        guard let id = media.id else { return nil }

        for (task, downloadMetadata) in activeDownloads where downloadMetadata.hashedID == id {
            return task.urlAsset
        }

        return localAsset(forMedia: media)
    }

    /// Idempotently begins a download of the HLS asset for the given media
    public func download(media: Media) -> Media.DownloadState {
        precondition(media.id != nil, "Media must have HashedID")
        guard let id = media.id else { return .persistenceNotAvailable }
        let dlState = downloadState(forMedia: media)
        guard dlState == .notDownloaded else { return dlState }

        guard let asset = media.hlsAsset(usingClient: nil, assetPlaybackOptions: [.stream]) as? AVURLAsset else {
            print("AVURLAsset not available for \(media)")
            return .persistenceNotAvailable
        }

        guard let task =
            assetDownloadURLSession.aggregateAssetDownloadTask(with: asset,
                                                               mediaSelections: [asset.preferredMediaSelection],
                                                               assetTitle: "[WistiaHLSPersistence] Download of \(media.attributes?.name ?? id)",
                assetArtworkData: nil,
                options:nil) else {
                    print("ERROR: Couldn't create download task for \(media)")
                    return .persistenceNotAvailable
        }

        task.taskDescription = id
        activeDownloads[task] = DownloadMetadata(hashedID: id)
        task.resume()

        return downloadState(forMedia: media)
    }

    public func cancelDownload(media: Media) -> Media.DownloadState {
        precondition(media.id != nil, "Media must have HashedID")
        guard let id = media.id else { return .persistenceNotAvailable }
        let dlState = downloadState(forMedia: media)
        guard dlState == .downloading else { return dlState }


        for (task, downloadMetadata) in activeDownloads where downloadMetadata.hashedID == id {
            task.cancel()
            return .notDownloaded
        }

        return .persistenceNotConfigured
    }

    public func removeDownload(forMedia media: Media) -> Media.DownloadState {
        precondition(media.id != nil, "Media must have HashedID")
        guard let id = media.id else { return .persistenceNotAvailable }

        if let assetUrl = localAssetUrl(forHashedId: id) {
            print("Removing asset for \(id) at location: \(assetUrl)")
            removeFile(atURL: assetUrl)
            UserDefaults.standard.removeObject(forKey: userDefaultsKey(forHashedId: id))
            return .notDownloaded
        }
        else {
            print("No downloaded asset to remove for \(id)")
            return .notDownloaded
        }
    }

    public func removeAllDownloads() {
        for (key, bookmark) in UserDefaults.standard.dictionaryRepresentation() where isHLSDownloadLocation(key: key)  {
            print("Removing download for key \(key)")
            guard let bookmark = bookmark as? Data,
                let assetUrl = localAssetUrl(forBookmark: bookmark) else { return }
            removeFile(atURL: assetUrl)
            UserDefaults.standard.removeObject(forKey: key)
        }
    }

    //MARK: - Private

    private func restorePersistenceManager() {
        guard !didRestorePersistenceManager else { return }

        didRestorePersistenceManager = true

        assetDownloadURLSession.getAllTasks { tasks in
            for task in tasks {
                guard let assetDownloadTask = task as? AVAggregateAssetDownloadTask, let hashedID = task.taskDescription else { break }
                self.activeDownloads[assetDownloadTask] = DownloadMetadata(hashedID: hashedID)
                print("Restoring task \(assetDownloadTask) with state \(assetDownloadTask.state) (running? \(assetDownloadTask.state == .running))")
                assetDownloadTask.resume()
            }
        }
    }

    private static let userDefaultsPrefix = "HLSDownloadLocationFor-"

    private func userDefaultsKey(forHashedId hashedID: HashedID) -> String {
        return "\(WistiaHLSPersistenceManager.userDefaultsPrefix)\(hashedID)"
    }

    private func isHLSDownloadLocation(key: String) -> Bool {
        return key.starts(with: WistiaHLSPersistenceManager.userDefaultsPrefix)
    }

    private func localAssetUrl(forHashedId hashedID: HashedID) -> URL? {
        guard let bookmark = bookmark(forHashedId: hashedID) else { return nil }
        return localAssetUrl(forBookmark: bookmark)
    }

    private func localAssetUrl(forBookmark bookmark: Data) -> URL? {
        do {
            var bookmarkDataIsStale = false
            guard let url = try URL(resolvingBookmarkData: bookmark,
                                    bookmarkDataIsStale: &bookmarkDataIsStale) else {
                                        fatalError("Failed to create URL from bookmark!")
            }

            if bookmarkDataIsStale {
                fatalError("Bookmark data is stale!")
            }
            return url
        }
        catch {
            fatalError("Failed to create URL from bookmark with error: \(error)")
        }
    }

    private func bookmark(forHashedId id: HashedID) -> Data? {
        return UserDefaults.standard.data(forKey: userDefaultsKey(forHashedId: id))
    }

    private func removeFile(atURL url: URL) {
        do {
            try FileManager.default.removeItem(at: url)
            print("Deleted file at \(url)")
        }
        catch {
            print("Error deleting file at \(url): \(error)")
        }
    }

}

//MARK: - AVAssetDownloadDelegate

extension WistiaHLSPersistenceManager: AVAssetDownloadDelegate {

    /// Tells the delegate that the task finished transferring data.
    public func urlSession(_ session: URLSession, task: URLSessionTask, didCompleteWithError error: Error?) {
        precondition(task.taskDescription != nil)
        precondition(activeDownloads[task as! AVAggregateAssetDownloadTask] != nil)
        guard let task = task as? AVAggregateAssetDownloadTask,
            let downloadMetadata = activeDownloads.removeValue(forKey: task),
            let downloadUrl = willDownloadToUrlMap.removeValue(forKey: task) else { return }
        print("**** Finished downloading \(downloadMetadata), with error? \(String(describing: error))")

        if error != nil {
            for observer in downloadMetadata.observers {
                observer.download(forHashedID: downloadMetadata.hashedID, hasState: .notDownloaded, withProgress: 1.0)
            }
            do {
                let bookmark = try downloadUrl.bookmarkData()
                var bookmarkDataIsStale = false
                guard let url = try URL(resolvingBookmarkData: bookmark,
                                        bookmarkDataIsStale: &bookmarkDataIsStale) else {
                                            fatalError("Failed to create URL from bookmark!")
                }
                removeFile(atURL: url)
                UserDefaults.standard.removeObject(forKey: userDefaultsKey(forHashedId: downloadMetadata.hashedID))
            } catch {
                print("Error trying to remove failed download at \(downloadUrl): \(error)")
            }
        }
        else {
            do {
                let bookmark = try downloadUrl.bookmarkData()
                UserDefaults.standard.set(bookmark, forKey: userDefaultsKey(forHashedId: downloadMetadata.hashedID))
                for observer in downloadMetadata.observers {
                    observer.download(forHashedID: downloadMetadata.hashedID, hasState: .downloaded, withProgress: 1.0)
                }
            } catch {
                print("Error creating bookmark for \(downloadUrl): \(error)")
            }
        }
    }

    public func urlSession(_ session: URLSession, aggregateAssetDownloadTask: AVAggregateAssetDownloadTask,
                           willDownloadTo location: URL) {

        //Comment From Apple:
        /*
         This delegate callback should only be used to save the location URL
         somewhere in your application. Any additional work should be done in
         `URLSessionTaskDelegate.urlSession(_:task:didCompleteWithError:)`.
         */
        willDownloadToUrlMap[aggregateAssetDownloadTask] = location
    }

    //XXX
    /// Method called when a child AVAssetDownloadTask completes.
    public func urlSession(_ session: URLSession, aggregateAssetDownloadTask: AVAggregateAssetDownloadTask,
                    didCompleteFor mediaSelection: AVMediaSelection) {
        /*
         This delegate callback provides an AVMediaSelection object which is now fully available for
         offline use. You can perform any additional processing with the object here.
         */

        print("??????????? task \(aggregateAssetDownloadTask) did complete for media selection: \(mediaSelection)")

        aggregateAssetDownloadTask.resume()
    }
    //XXX

    /// Method to adopt to subscribe to progress updates of an AVAggregateAssetDownloadTask.
    public func urlSession(_ session: URLSession, aggregateAssetDownloadTask: AVAggregateAssetDownloadTask,
                           didLoad timeRange: CMTimeRange, totalTimeRangesLoaded loadedTimeRanges: [NSValue],
                           timeRangeExpectedToLoad: CMTimeRange, for mediaSelection: AVMediaSelection) {
        precondition(aggregateAssetDownloadTask.taskDescription != nil)
        precondition(activeDownloads[aggregateAssetDownloadTask] != nil)

        var percentComplete = 0.0
        for value in loadedTimeRanges {
            let loadedTimeRange: CMTimeRange = value.timeRangeValue
            percentComplete +=
                CMTimeGetSeconds(loadedTimeRange.duration) / CMTimeGetSeconds(timeRangeExpectedToLoad.duration)
        }

        if var downloadMetadata = activeDownloads[aggregateAssetDownloadTask] {
            downloadMetadata.setProgress(percentComplete)
            for observer in downloadMetadata.observers {
                observer.download(forHashedID: downloadMetadata.hashedID, hasState: .downloading, withProgress: percentComplete)
            }
        }
        else {
            preconditionFailure("Received download task update for untracked task: \(aggregateAssetDownloadTask)")
        }
    }

}


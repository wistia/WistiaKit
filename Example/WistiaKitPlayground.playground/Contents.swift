import UIKit
import PlaygroundSupport
import AVKit
PlaygroundPage.current.needsIndefiniteExecution = true
/////////////////////////////////////////////////////////////////////////////////////
/////////////////////////////////////////////////////////////////////////////////////

/*
public class WistiaHlsPersistenceManager: NSObject, PersistenceManager {

    public static var `default`: WistiaHlsPersistenceManager = {
        return WistiaHlsPersistenceManager()
    }()

    private var didRestorePersistenceManager = false

    private var assetDownloadURLSession: AVAssetDownloadURLSession!

    private var activeDownloads = [HashedID: AVAggregateAssetDownloadTask]()

    // Download destination is updated async, so we need to track it
    private var willDownloadToUrlMap = [AVAggregateAssetDownloadTask: URL]()

    private override init() {
        super.init()

        let backgroundConfiguration = URLSessionConfiguration.background(withIdentifier: "WistiaHlsPersistenceManager-BackgroundURLSessionIdentifier")

        //NB: if you don't specify the delegate queue, need to make sure any shared state (ie. activeDownloads)
        //is synchronized for parallel access
        self.assetDownloadURLSession =
            AVAssetDownloadURLSession(configuration: backgroundConfiguration,
                                      assetDownloadDelegate: self, delegateQueue: OperationQueue.main)
    }

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

    /// returns a completed download, stored on-disk, for the given Media
    public func localAsset(forMedia media: Media) -> AVURLAsset? {
        //TODO: RETURN ON-DISK ASSET ONLY

        return nil
    }

    /// returns an in-progress or completed download for the given Media.
    public func asset(forMedia media: Media) -> AVURLAsset? {
        precondition(media.id != nil, "Media must have HashedID")
        guard let id = media.id else { return nil }

        if let asset = activeDownloads[id] {
            return asset.urlAsset
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
                                                               assetTitle: "[Download of] \(media.attributes?.name ?? id)",
                                                               assetArtworkData: nil,
                                                               options:nil) else {
            print("ERROR: Couldn't create download task for \(media)")
            return .persistenceNotAvailable
        }

        task.taskDescription = id
        activeDownloads[id] = task
        task.resume()

        return downloadState(forMedia: media)
    }

    private func restorePersistenceManager() {
        guard !didRestorePersistenceManager else { return }

        didRestorePersistenceManager = true

        assetDownloadURLSession.getAllTasks { tasks in
            for task in tasks {
                guard let assetDownloadTask = task as? AVAggregateAssetDownloadTask, let hashedID = task.taskDescription else { break }
                self.activeDownloads[hashedID] = assetDownloadTask
            }

        }
    }

}

extension WistiaHlsPersistenceManager: AVAssetDownloadDelegate {

    /// Tells the delegate that the task finished transferring data.
    public func urlSession(_ session: URLSession, task: URLSessionTask, didCompleteWithError error: Error?) {
        precondition(task.taskDescription != nil)
        precondition(activeDownloads[task.taskDescription!] != nil)
        guard let hashedId = task.taskDescription else { return }

        //TODO: PRETTY IMPORTANT ONE
        print("**** Finished downloading \(hashedId), with error? \(error)")
    }


    public func urlSession(_ session: URLSession, aggregateAssetDownloadTask: AVAggregateAssetDownloadTask,
                    willDownloadTo location: URL) {


        willDownloadToUrlMap[aggregateAssetDownloadTask] = location
    }

    /// Method to adopt to subscribe to progress updates of an AVAggregateAssetDownloadTask.
    public func urlSession(_ session: URLSession, aggregateAssetDownloadTask: AVAggregateAssetDownloadTask,
                    didLoad timeRange: CMTimeRange, totalTimeRangesLoaded loadedTimeRanges: [NSValue],
                    timeRangeExpectedToLoad: CMTimeRange, for mediaSelection: AVMediaSelection) {
        precondition(aggregateAssetDownloadTask.taskDescription != nil)
        precondition(activeDownloads[aggregateAssetDownloadTask.taskDescription!] != nil)
        guard let hashedId = aggregateAssetDownloadTask.taskDescription else { return }

        var percentComplete = 0.0
        for value in loadedTimeRanges {
            let loadedTimeRange: CMTimeRange = value.timeRangeValue
            percentComplete +=
                CMTimeGetSeconds(loadedTimeRange.duration) / CMTimeGetSeconds(timeRangeExpectedToLoad.duration)
        }

        print("Media \(hashedId) download progress: \(percentComplete)")
        //TODO: Maybe store a new struct called DownloadingMedia which can track progress
        // and update that here
    }

}

//TODO: Put this in WistiaObjects
typealias HashedID = String

//TODO: Put directly into media
extension Media {

    public struct AssetPlaybackOptions: OptionSet {
        public let rawValue: Int

        public init(rawValue: AssetPlaybackOptions.RawValue) {
            self.rawValue = rawValue
        }

        ///A .stream asset is not on disk nor in process of downloading (at time of return).
        ///There may be an equivalent asset available locally.  If you wish to allow playback
        ///using it (when available), pass .local in your asset playback options.
        public static let stream     = AssetPlaybackOptions(rawValue: 1 << 0)

        ///a local asset may be in the process of downloading or completely downloaded
        public static let local      = AssetPlaybackOptions(rawValue: 1 << 1)

        ///a downloaded asset is guaranteed to be on disk (such assets are a subset of .local assets)
        public static let downloaded = AssetPlaybackOptions(rawValue: 1 << 2)

        ///allow playback from streaming, local (downloading/downloaded), and fully downloaded assets
        public static let any: AssetPlaybackOptions = [.stream, .local, .downloaded]

        ///do not allow playback
        public static let none: AssetPlaybackOptions = []
    }

    public func hlsAsset(usingClient client: WistiaClient? = nil, assetPlaybackOptions: AssetPlaybackOptions = .any) -> AVAsset? {
        guard !assetPlaybackOptions.isEmpty, let id = self.id else { return nil }

        // .local (passed in any combination) will return an in process or completed downloaded
        if assetPlaybackOptions.contains(.local),
            let persistenceManager = (client ?? WistiaClient.default).persistenceManager,
            let asset = persistenceManager.asset(forMedia: self) {
            return asset
        }

        // .downloaded only returns a fully downloaded asset (a subset of .local)
        if assetPlaybackOptions.contains(.downloaded),
            let persistenceManager = (client ?? WistiaClient.default).persistenceManager,
            let downloadedAsset = persistenceManager.localAsset(forMedia: self) {
            return downloadedAsset
        }

        if assetPlaybackOptions.contains(.stream),
            let hlsURL = URL(string: "https://fast.wistia.net/embed/medias/\(id).m3u8") {
            //TODO: Confirm this Media has HLS Assets instead of assuming
            // ...once API V2 returns a media's assets or has some other way to accomplish it
            return AVURLAsset(url: hlsURL)
        }

        return nil
    }

    public func hlsPlayerItem(usingClient client: WistiaClient? = nil, assetPlaybackOptions: AssetPlaybackOptions = .any) -> AVPlayerItem? {
        if let asset = hlsAsset(usingClient: client, assetPlaybackOptions: assetPlaybackOptions) {
            return AVPlayerItem(asset: asset)
        }
        return nil
    }
}

//Persistence Extensions
extension Media {
    public func downloadState(usingClient client: WistiaClient? = nil) -> DownloadState {
        guard let persistenceManager = (client ?? WistiaClient.default).persistenceManager else { return .persistenceNotConfigured }

        return persistenceManager.downloadState(forMedia: self)
    }

    public func download(usingClient client: WistiaClient? = nil) -> DownloadState {
        guard let persistenceManager = (client ?? WistiaClient.default).persistenceManager else { return .persistenceNotConfigured }

        return persistenceManager.download(media: self)
    }
}
*/



///// CLIENET CODE ///////////


let adamsToken = "d7ff46a1926d535a1de6f643915f8cca1a7c393f74815a923c0276e7dbce37d8"
let dansToken = "dcb0e1179609d1da5cf1698797fdb205ff783d428414bab13ec042102e53e159"

WistiaClient.default = WistiaClient(token: adamsToken, sessionConfiguration: nil, persistenceManager: WistiaHLSPersistenceManager.default)
let projectId = "32ko9arq7m"
let mediaId = "hs8pwc6hck" //Dad Therapy by 5 second films
let mediaId2 = "wr5469p7xa"//Big Buck Bunny
let mediaId3 = "8e4hexbdcn"//Bestpractice
let badMedia = "acvtbaj7ly"

let player = AVQueuePlayer(items: [Media(id: mediaId).hlsPlayerItem()!,
                                   Media(id: mediaId2).hlsPlayerItem()!,
                                   Media(id: mediaId3).hlsPlayerItem()!])
let playerVC = AVPlayerViewController()
playerVC.player = player
PlaygroundPage.current.liveView = playerVC

Media(id: mediaId2).download()

/*
Project.list { (projects, error) in
    if let projects = projects {
        for project in projects {
            Media.list(projectID: project.id!, { (medias, error) in
                if let medias = medias {
                    print("Project [\(project.id!)] contains \(project.attributes?.videoCount ?? 99) medias:")
                    for media in medias {
                        print("  media: \(media.id!)")
                    }
                }
                else if let error = error {
                    print("Project [\(project.id!)] had an error reading media: \(error)")
                }
            })

        }
    }
    else if let error = error {
        print("Error reading project: \(error)")
    }
}

Media.list(projectID: projectId) { (medias, error) in
    if let medias = medias {
        print("Listing medias: \(String(describing: medias))")
    } else {
        print("Error listing medias: \(error!)")
    }
}

Media(id: mediaId).show { (media, error) in
    if let media = media {
        print("Showing one media: \(String(describing: media))")
    } else {
        print("Error showing media: \(error!)")
    }
}







/////////////////////////////////////////////////////////////////////////////////////
/////////////////////////////////////////////////////////////////////////////////////
DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + 3.0) {
    PlaygroundPage.current.finishExecution()
}
*/

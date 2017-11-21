//
//  ViewController.swift
//  WistiaKit
//
//  Created by spinosa on 10/17/2017.
//  Copyright (c) 2017 spinosa. All rights reserved.
//

import UIKit
import WistiaKit
import AVKit

class ViewController: UIViewController {

    let id1 = "a74mrwu4wi"
    let id2 = "nc6pv4kpul"

    override func viewDidLoad() {
        super.viewDidLoad()

        WistiaClient.default = WistiaClient(token: nil, sessionConfiguration: nil, persistenceManager: WistiaHLSPersistenceManager.default)
    }

    @IBAction func downloadStuff(_ sender: Any) {
        let m1 = Media(id: id1)
        let res = m1.download()
        WistiaHLSPersistenceManager.default.addObserver(self, forMedia: m1)
        print("downloading? \(res)")

        print("downloading bad media? \(Media(id: "xxx").download())")
        WistiaHLSPersistenceManager.default.addObserver(self, forMedia: Media(id: "xxx"))

        print("downloading Long media? \(Media(id: id2).download())")
        WistiaHLSPersistenceManager.default.addObserver(self, forMedia: Media(id: id2))
    }

    @IBAction func deleteAll(_ sender: Any) {
        WistiaHLSPersistenceManager.default.removeAllDownloads()
    }

    @IBAction func deleteOneFile(_ sender: Any) {
        Media(id: id1).removeDownload()
    }

    @IBAction func cancelThemDownloads(_ sender: Any) {
        print("cancelling \(id1) : \(Media(id: id1).cancelDownload())")
        print("cancelling xxx : \(Media(id: "xxx").cancelDownload())")
        print("cancelling \(id2) : \(Media(id: id2).cancelDownload())")
    }

    let playerVC = AVPlayerViewController()

    @IBAction func playThatOne(_ sender: Any) {
        let m = Media(id: id1)
        print("Going to play media with download state: \(m.downloadState())")

        playerVC.player = AVPlayer(playerItem: m.hlsPlayerItem())

        self.present(playerVC, animated: true, completion: nil)
    }

}

extension ViewController: WistiaHLSPersistenceDownloadObserver {
    func download(forHashedID hashedID: HashedID, hasState state: Media.DownloadState, withProgress progress: Double?) {
        print("Observer of \(hashedID) notified of state \(state) @ \((progress ?? -1)*100.0)%")
    }
}


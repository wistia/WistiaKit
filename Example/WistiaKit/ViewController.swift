//
//  ViewController.swift
//  WistiaKit
//
//  Created by spinosa on 04/05/2016.
//  Copyright © 2016 Wistia, Inc. All rights reserved.
//

import UIKit
import WistiaKit

class ViewController: UIViewController {

    let wistiaPlayerVC = WistiaPlayerViewController(referrer: "WistiaKitDemo", requireHLS: false)

    @IBOutlet weak var hashedIDTextField: UITextField!

    @IBAction func playTapped(_ sender: AnyObject) {
        if let hashedID = hashedIDTextField.text {
            let _ = wistiaPlayerVC.replaceCurrentVideoWithVideo(forHashedID: hashedID)
            self.present(wistiaPlayerVC, animated: true, completion: nil)
        }
    }
}


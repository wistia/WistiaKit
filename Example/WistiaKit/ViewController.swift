//
//  ViewController.swift
//  WistiaKit
//
//  Created by spinosa on 04/05/2016.
//  Copyright (c) 2016 spinosa. All rights reserved.
//

import UIKit
import WistiaKit

class ViewController: UIViewController {

    let wistiaPlayerVC = WistiaPlayerViewController(referrer: "WistiaKitDemo", requireHLS: false)

    @IBOutlet weak var hashedIDTextField: UITextField!

    @IBAction func playTapped(sender: AnyObject) {
        if let hashedID = hashedIDTextField.text {
            wistiaPlayerVC.replaceCurrentVideoWithVideoForHashedID(hashedID)
            self.presentViewController(wistiaPlayerVC, animated: true, completion: nil)
        }
    }
}


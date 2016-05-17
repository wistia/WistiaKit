//
//  UIColorExtensions.swift
//  WistiaKit
//
//  Created by Daniel Spinosa on 4/13/16.
//  Copyright © 2016 Wistia, Inc. All rights reserved.
//

import UIKit

extension UIColor {
    static func wk_fromHexString(hex:String) -> UIColor {
        var rgbValue:UInt32 = 0
        let scanner = NSScanner(string: hex.stringByReplacingOccurrencesOfString("#", withString: ""))
        scanner.scanHexInt(&rgbValue)
        return UIColor(red: CGFloat((rgbValue & 0xFF0000) >> 16)/255.0, green: CGFloat((rgbValue & 0xFF00) >> 8)/255.0, blue: CGFloat(rgbValue & 0xFF)/255.0, alpha: 1.0)
    }
}


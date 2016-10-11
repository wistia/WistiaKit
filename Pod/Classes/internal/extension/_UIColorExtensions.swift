//
//  _UIColorExtensions.swift
//  WistiaKit internal
//
//  Created by Daniel Spinosa on 4/13/16.
//  Copyright © 2016 Wistia, Inc. All rights reserved.
//

import UIKit

extension UIColor {
    
    static func wk_from(hexString hex:String) -> UIColor {
        var rgbValue:UInt32 = 0
        let scanner = Scanner(string: hex.replacingOccurrences(of: "#", with: ""))
        scanner.scanHexInt32(&rgbValue)
        return UIColor(red: CGFloat((rgbValue & 0xFF0000) >> 16)/255.0, green: CGFloat((rgbValue & 0xFF00) >> 8)/255.0, blue: CGFloat(rgbValue & 0xFF)/255.0, alpha: 1.0)
    }

    func wk_toHexString() -> String {
        var r: CGFloat = 0
        var g: CGFloat = 0
        var b: CGFloat = 0
        var a: CGFloat = 0
        if self.getRed(&r, green: &g, blue: &b, alpha: &a) {
            return String(format: "#%02X%02X%02X", Int(r * 255), Int(g * 255), Int(b * 255))
        } else {
            return "#7b796a"
        }
    }
}


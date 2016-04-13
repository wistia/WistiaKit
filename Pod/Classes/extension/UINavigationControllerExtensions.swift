//
//  UINavigationControllerExtensions.swift
//  Stargazer
//
//  Created by Daniel Spinosa on 2/10/16.
//  Copyright © 2016 Wistia, Inc. All rights reserved.
//

import UIKit

extension UINavigationController {

    func wk_pushViewController(viewController: UIViewController, animated: Bool, completion: () -> Void) {
            CATransaction.begin()
            CATransaction.setCompletionBlock(completion)
            pushViewController(viewController, animated: animated)
            CATransaction.commit()
    }

    func wk_popViewController(animated: Bool, completion: () -> Void) {
            CATransaction.begin()
            CATransaction.setCompletionBlock(completion)
            popViewControllerAnimated(animated)
            CATransaction.commit()
    }
    
}

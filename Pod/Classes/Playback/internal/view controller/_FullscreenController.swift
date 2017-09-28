//
//  FullscreenController.swift
//  Pods
//
//  Created by Adam Jensen on 5/15/17.
//
//

import UIKit

class FullscreenController: NSObject {
    fileprivate var fullscreenWindow: UIWindow?
    fileprivate var fullscreenView: UIView?
    fileprivate var originalContainerViewController: UIViewController?
    fileprivate var originalSuperview: UIView?
    fileprivate var viewController: UIViewController?
    fileprivate var placeholderView: UIView?
    fileprivate var originalSuperviewConstraints: [NSLayoutConstraint]?
    
    override init() {
        let fullscreenWindow = UIWindow(frame: UIScreen.main.bounds)
        fullscreenWindow.windowLevel = UIWindowLevelNormal
        self.fullscreenWindow = fullscreenWindow

        super.init()
    }
    
    func presentFullscreen(viewController vc: UIViewController, view: UIView?) {
        guard
            let fullscreenWindow = fullscreenWindow,
            let parentVC = vc.parent,
            let superview = vc.view.superview,
            let view = view ?? vc.view
        else {
            assert(false, "Couldn't get ancestral views/VCs for fullscreen")
            return
        }
        
        originalContainerViewController = parentVC
        originalSuperview = superview
        originalSuperviewConstraints = superview.constraints
        viewController = vc
        fullscreenView = view
        
        fullscreenWindow.isHidden = false
        let originalFrame = view.convert(view.bounds, to: nil)
        fullscreenWindow.frame = originalFrame
        configureChildViewController(vc)
        
        fullscreenWindow.layoutIfNeeded()
        UIView.animate(withDuration: 0.3, delay: 0, options: .curveEaseInOut, animations: {
            fullscreenWindow.frame = UIScreen.main.bounds
            fullscreenWindow.layoutIfNeeded()
        }, completion: nil)
    }
    
    func dismiss(completion: (() -> Void)?) {
        guard
            let fullscreenWindow = fullscreenWindow,
            let placeholderView = placeholderView
        else {
            assert(false, "Couldn't get container view")
            return
        }
        
        fullscreenWindow.layoutIfNeeded()
        UIView.animate(withDuration: 0.3, delay: 0, options: .curveEaseInOut, animations: {
            fullscreenWindow.frame = placeholderView.convert(placeholderView.bounds, to: nil)
            fullscreenWindow.layoutIfNeeded()
        }, completion: { _ in
            self.returnChildViewControllerToOriginalState()
            placeholderView.removeFromSuperview()
            self.teardown()
            completion?()
        })
    }
}

private extension FullscreenController {
    func configureChildViewController(_ vc: UIViewController) {
        guard
            let fullscreenWindow = fullscreenWindow,
            let fullscreenView = fullscreenView,
            let originalSuperview = originalSuperview
        else {
            assert(false, "Couldn't configure child VC")
            return
        }
        
        vc.willMove(toParentViewController: nil)
        vc.removeFromParentViewController()
        originalSuperviewConstraints = vc.view.superview?.constraints
        vc.view.removeFromSuperview()
        fullscreenWindow.addSubview(fullscreenView)
        fullscreenView.constrainTo(view: fullscreenWindow)
        
        fullscreenWindow.rootViewController = viewController
        
        let placeholderView = UIView()
        placeholderView.translatesAutoresizingMaskIntoConstraints = false
        originalSuperview.addSubview(placeholderView)
        placeholderView.constrainTo(view: originalSuperview)
        self.placeholderView = placeholderView
    }
    
    func returnChildViewControllerToOriginalState() {
        guard
            let fullscreenWindow = fullscreenWindow,
            let fullscreenView = fullscreenView,
            let originalContainerViewController = originalContainerViewController,
            let originalSuperview = originalSuperview,
            let viewController = viewController
        else {
            assert(false, "Couldn't get original container view/VC for exiting fullscreen")
            return
        }
        
        fullscreenWindow.rootViewController = nil
        viewController.willMove(toParentViewController: nil)
        viewController.removeFromParentViewController()
        fullscreenView.removeFromSuperview()
        
        originalContainerViewController.addChildViewController(viewController)
        originalSuperview.addSubview(fullscreenView)
        originalSuperviewConstraints?.forEach({ (originalConstraint) in
            if !originalSuperview.constraints.contains(originalConstraint) {
                originalSuperview.addConstraint(originalConstraint)
                originalConstraint.isActive = true
            }
        })
        viewController.didMove(toParentViewController: originalContainerViewController)
        fullscreenView.frame = originalSuperview.frame
    }
    
    func teardown() {
        fullscreenWindow?.isHidden = true
        fullscreenWindow = nil
        placeholderView = nil
        originalSuperview = nil
        originalContainerViewController = nil
        viewController = nil
    }
}

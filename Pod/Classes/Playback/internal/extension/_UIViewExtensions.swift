//
//  _UIViewExtensions.swift
//  Pods
//
//  Created by Adam Jensen on 4/21/17.
//
//

import UIKit

extension UIView {
    func constrainTo(view: UIView) -> [NSLayoutConstraint] {
        let constraints = [
            topAnchor.constraint(equalTo: view.topAnchor),
            bottomAnchor.constraint(equalTo: view.bottomAnchor),
            leadingAnchor.constraint(equalTo: view.leadingAnchor),
            trailingAnchor.constraint(equalTo: view.trailingAnchor)
        ]
        constraints.forEach { $0.isActive = true }
        return constraints
    }
}

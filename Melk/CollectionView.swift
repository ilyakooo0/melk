//
//  CollectionView.swift
//  Melk
//
//  Created by Ilya Kos on 7/6/17.
//  Copyright © 2017 Ilya Kos. All rights reserved.
//

import UIKit

class CollectionView: UIView {
    var arrangedSubviews: [UIView] = []{
        didSet {
            setNeedsLayout()
        }
    }
    /// Padding between content
    var horizontalPadding: CGFloat = 0 {
        didSet {
            setNeedsLayout()
        }
    }
    /// Padding between content
    var verticalPadding: CGFloat = 0 {
        didSet {
            setNeedsLayout()
        }
    }
    /// Padding around content
    var padding: CGPoint = CGPoint.zero {
        didSet {
            setNeedsLayout()
        }
    }
    var maxWidth: CGFloat = 200 {
        didSet {
            setNeedsLayout()
        }
    }
    /// Alignment of elements inside a row
    ///
    /// Valid values: .top, .center, .bottom
    ///
    /// Default value: .top
    var alignment: Alignment = .top
    
    /// Alignment of rows
    ///
    /// Valid values: .left, .center, .right
    ///
    /// Default value: .left
    var rowAlignment: Alignment = .left

    func addArrangedSubview(_ view: UIView) {
        arrangedSubviews.append(view)
    }
    
    override func layoutSubviews() {
        subviews.map {$0.removeFromSuperview()}
        
        let largeStack = StackView(axis: .vertical, alignment: rowAlignment)
        largeStack.padding = padding
        
        var lastStack = StackView(axis: .horizontal, alignment: alignment)
        let contentWidth = maxWidth - padding.x*2
        var width = contentWidth
        var firstView = true
        var firstStack = true
        
        for view in arrangedSubviews {
//            print("new view")
            if firstView {
                lastStack.addArrangedSubview(.view(view))
                firstView = false
                width -= view.width
            } else {
                if width >= horizontalPadding + view.width {
                    lastStack.addArrangedSubview(.spacer(horizontalPadding))
                    lastStack.addArrangedSubview(.view(view))
                    width -= horizontalPadding + view.width
                } else {
                    if !firstStack {
                        largeStack.addArrangedSubview(.spacer(verticalPadding))
                    } else {
                        firstStack = false
                    }
                    lastStack.layoutIfNeeded()
                    largeStack.addArrangedSubview(.view(lastStack))
                    
                    lastStack = StackView(axis: .horizontal, alignment: alignment)
                    lastStack.addArrangedSubview(.view(view))
                    width = contentWidth - view.width
                }
            }
        }
        lastStack.layoutIfNeeded()
        if !firstStack {
            largeStack.addArrangedSubview(.spacer(verticalPadding))
        }
        largeStack.addArrangedSubview(.view(lastStack))
        largeStack.frame.origin = CGPoint.zero
        largeStack.layoutIfNeeded()
        addSubview(largeStack)
        frame.size = largeStack.frame.size
    }
}

fileprivate extension UIView {
    var width: CGFloat {
        return self.frame.width
    }
}

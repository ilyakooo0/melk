//
//  StackView.swift
//  Melk
//
//  Created by Ilya Kos on 7/5/17.
//  Copyright © 2017 Ilya Kos. All rights reserved.
//

import UIKit

class StackView: UIView {
    var axis: Axis = .horizontal {
        didSet {
            setNeedsLayout()
        }
    }
    var alignment: Alignment = .center {
        didSet {
            setNeedsLayout()
        }
    }
    var padding: CGPoint = CGPoint.zero {
        didSet {
            setNeedsLayout()
        }
    }
    var arrangedSubviews: [StackViewElement] = [] {
        didSet {
            setNeedsLayout()
        }
    }
    
    func addArrangedSubview(_ element: StackViewElement) {
        arrangedSubviews.append(element)
    }
    
    convenience init(axis: Axis, alignment: Alignment) {
        self.init()
        self.axis = axis
        self.alignment = alignment
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        print("laying out subviews")
        
        subviews.map({$0.removeFromSuperview()}) // TODO: There must be a better way!
        
        var height: CGFloat = 0
        var width: CGFloat = 0
        switch axis {
        case .horizontal:
            width = padding.x
        case .vertical:
            height = padding.y
        }
        for element in arrangedSubviews {
            switch element {
            case .spacer(let a):
                switch axis {
                case .horizontal:
                    width += a
                case .vertical:
                    height += a
                }
            case .view(let view):
                view.layoutIfNeeded()
                switch axis {
                case .horizontal:
                    view.frame.origin.x = width
                    width += view.frame.width
                    height = max(height, view.frame.height)
                    if alignment == .top {
                        view.frame.origin.y = padding.y
                    }
                case .vertical:
                    view.frame.origin.y = height
                    height += view.frame.height
                    width = max(width, view.frame.width)
                    if alignment == .left {
                        view.frame.origin.x = padding.x
                    }
                }
                addSubview(view)
            }
        }
        switch axis {
        case .horizontal:
            frame.size = CGSize(width: width + padding.x, height: height + 2*padding.y)
            switch alignment {
            case .top:
                break
            case .bottom:
                for element in arrangedSubviews {
                    switch element {
                    case .view(let view):
                        view.frame.origin.y = height - view.frame.height + padding.y
                    default:
                        break
                    }
                }
            default:
                for element in arrangedSubviews {
                    switch element {
                    case .view(let view):
                        view.center.y = height/2 + padding.y
                    default:
                        break
                    }
                }
            }
        case .vertical:
            frame.size = CGSize(width: width + 2*padding.x, height: height + padding.y)
            switch alignment {
            case .left:
                break
            case .right:
                for element in arrangedSubviews {
                    switch element {
                    case .view(let view):
                        view.frame.origin.x = width - view.frame.width + padding.x
                    default:
                        break
                    }
                }
            default:
                for element in arrangedSubviews {
                    switch element {
                    case .view(let view):
                        view.center.x = width/2 + padding.x
                    default:
                        break
                    }
                }
            }
        }
    }
}

enum StackViewElement {
    case spacer(CGFloat)
    case view(UIView)
}

enum Axis {
    case horizontal
    case vertical
}

enum Alignment {
    case center
    case top
    case right
    case bottom
    case left
}

//
//  CardContainer.swift
//  Melk
//
//  Created by Ilya Kos on 7/22/17.
//  Copyright © 2017 Ilya Kos. All rights reserved.
//

import UIKit

class CardContainer: UIView {
    
    func animate() {
        blurView.effect = blur
        card.transform = smallTransform
        card.layer.opacity = 0
        UIView.animate(withDuration: 0.5, delay: 0, options: [.curveEaseInOut], animations: {
            self.card.transform = self.normalTransform
            self.blurView.effect = nil
            self.card.layer.opacity = 1
        }, completion: nil)
    }
    
    // MARK: Passthrough to CardView
    var post: WallPost? {
        get {
            return card.post
        }
        set {
            card.post = newValue
        }
    }
    
    var minWidth: CGFloat {
        get {
            return card.minWidth
        }
        set {
            card.minWidth = newValue
        }
    }

    
    var height: CGFloat {
        get {
            return card.height
        }
        set {
            card.height = newValue
        }
    }

    private let card: CardView
    private let blurView = UIVisualEffectView()
    private let blur = UIBlurEffect(style: UIBlurEffectStyle.light)
    private let scale: CGFloat = 0.35
    private let smallTransform: CGAffineTransform
    private let normalTransform = CGAffineTransform(scaleX: 1, y: 1)
    
    override init(frame: CGRect) {
        card = CardView(frame: frame)
        smallTransform = CGAffineTransform(scaleX: scale, y: scale)
        super.init(frame: frame)
        addSubview(card)
        addSubview(blurView)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        card.layoutIfNeeded()
        self.frame = card.frame
        blurView.frame = card.frame
    }

}

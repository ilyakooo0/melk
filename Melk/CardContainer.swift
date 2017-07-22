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
        shadowView.layer.opacity = 0
        shadowView.transform = smallTransform
        shadowView.layer.shadowRadius = 0
        UIView.animate(withDuration: 0.5, delay: 0, options: [.curveEaseInOut], animations: {
            self.card.transform = self.normalTransform
            self.shadowView.transform = self.normalTransform
            self.shadowView.layer.shadowRadius = self.shadowRadius
            self.shadowView.layer.opacity = 1
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
    private let shadowView = UIView()
    private let blur = UIBlurEffect(style: UIBlurEffectStyle.light)
    private let scale: CGFloat = 0.5
    private let smallTransform: CGAffineTransform
    private let normalTransform = CGAffineTransform(scaleX: 1, y: 1)
    private let shadowRadius: CGFloat = 12
    private let shadowOpacity: Float = 0.3
    
    override init(frame: CGRect) {
        card = CardView(frame: frame)
        smallTransform = CGAffineTransform(scaleX: scale, y: scale)
        super.init(frame: frame)
        shadowView.layer.shadowColor = #colorLiteral(red: 0, green: 0, blue: 0, alpha: 1).cgColor
        shadowView.layer.shadowRadius = shadowRadius
        shadowView.layer.shadowOpacity = shadowOpacity
        shadowView.backgroundColor = UIColor.clear
        shadowView.clipsToBounds = false
        shadowView.layer.shadowOffset = CGSize.zero
        addSubview(shadowView)
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
        shadowView.layer.shadowPath = CGPath(roundedRect: card.frame, cornerWidth: card.layer.cornerRadius, cornerHeight: card.layer.cornerRadius, transform: nil)
        shadowView.frame = card.frame
        blurView.frame = card.frame
    }

}

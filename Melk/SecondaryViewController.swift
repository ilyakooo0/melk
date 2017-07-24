//
//  SecondaryViewController.swift
//  Melk
//
//  Created by Ilya Kos on 7/5/17.
//  Copyright © 2017 Ilya Kos. All rights reserved.
//

import UIKit

class SecondaryViewController: UIViewController {
    
    init() {
        super.init(nibName: nil, bundle: nil)
        self.view = sView
    }
    
    func add(result: StreamingServiceResult) {
        sView.add(result: result)
    }
    
    func present(tag: String) {
        sView.present(tag: tag)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private let sView = SecondaryView()
}

class SecondaryView: UIView {
    
    var mainTag: String? {
        get {
            return tagLabel.text
        }
        set {
            tagLabel.text = newValue
            
        }
    }

    
    private let spacer: CGFloat = 32
    private let bottomSpacer: CGFloat = 64
    private let tagSpacer: CGFloat = 32
    private let tagLabel = UILabel()
    private let melkLabel = UILabel()
    
    func present(tag: String) {
        UIView.perform(.delete, on: [melkLabel], options: [], animations: nil) { (_) in
            self.melkLabel.removeFromSuperview()
            self.mainTag = tag
            self.tagLabel.sizeToFit()
            self.layoutIfNeeded(animated: true)
        }
    }
    
    func add(result: StreamingServiceResult) {
        switch result {
        case .post(let post):
            let card = CardContainer()
            card.minWidth = min(bounds.width / 2.3, 550)
            card.height = cardHeight
            card.post = post
            cards.addArrangedSubview(.spacer(spacer))
            cards.addArrangedSubview(.view(card))
            card.animate()
        }
        self.layoutIfNeeded(animated: true)
//        self.setNeedsLayout(animated: true) // Doesn't work for some reason
    }
    
//    private let card = CardView()
    private let cards = StackView(axis: .horizontal, alignment: .top)
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        backgroundColor = #colorLiteral(red: 1, green: 1, blue: 1, alpha: 1)
        addSubview(cards)
        
        melkLabel.text = "Melk"
        melkLabel.font = UIFont.systemFont(ofSize: 200, weight: UIFontWeightHeavy)
        melkLabel.textColor = #colorLiteral(red: 0.9601849914, green: 0.9601849914, blue: 0.9601849914, alpha: 1)
        addSubview(melkLabel)
        
        tagLabel.font = UIFont.systemFont(ofSize: 69, weight: UIFontWeightBold)
        tagLabel.textColor = #colorLiteral(red: 0.3176470588, green: 0.3179988265, blue: 0.3179988265, alpha: 1)
        addSubview(tagLabel)
    }
    
    func setNeedsLayout(animated: Bool) {
        self.animate = animated
        self.setNeedsLayout()
    }
    func layoutIfNeeded(animated: Bool) {
        self.animate = animated
        self.layoutIfNeeded()
    }
    private var animate: Bool = false
    
    private func cleanCards() {
        var offset = 0
        outLoop: for (i, element) in cards.arrangedSubviews.enumerated() {
            switch element {
            case .view(let card):
                let cardFrame = convert(card.frame, from: cards)
                if cardFrame.intersects(bounds) {
                   break outLoop
                } else {
                    cards.arrangedSubviews.remove(at: i-1-offset)
                    cards.arrangedSubviews.remove(at: i-1-offset)
                    offset += 2
                }
            case .spacer(_):
                break
            }
        }
    }
    
    private let padding = CGPoint(x: 32, y: 16)
    private var cardHeight: CGFloat = 400
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        melkLabel.sizeToFit()
        melkLabel.center = center
        
        let updates = {
            self.tagLabel.sizeToFit()
            self.tagLabel.center.x = self.center.x
            self.tagLabel.frame.origin.y = self.tagSpacer
            self.cards.frame.origin.y = self.tagLabel.frame.maxY + self.padding.y
            self.cards.layoutIfNeeded()
            self.cards.frame.origin.x = self.frame.width - self.padding.x - self.cards.frame.width
        }
        if animate {
            UIView.animate(withDuration: 0.7, delay: 0, usingSpringWithDamping: 0.8, initialSpringVelocity: 0.6, options: [], animations: updates, completion: { _ in
                self.cleanCards()
            })
//            UIView.animate(withDuration: 0.4, delay: 0.0, options: [.curveEaseOut], animations: updates, completion: nil)
        } else {
            updates()
            self.cleanCards()
        }
        cardHeight = bounds.height - tagLabel.frame.height - padding.y - tagSpacer - bottomSpacer
        animate = false
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

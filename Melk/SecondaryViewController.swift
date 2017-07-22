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
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private let sView = SecondaryView()
}

class SecondaryView: UIView {
    
    
    private let spacer: CGFloat = 16
    
    func add(result: StreamingServiceResult) {
        switch result {
        case .post(let post):
            let card = CardContainer()
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
        addSubview(cards)
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
    
    private let padding = CGPoint(x: 32, y: 32)
    
    override func layoutSubviews() {
        super.layoutSubviews()
        let updates = {
            self.cards.layoutIfNeeded()
            self.cards.frame.origin.y = self.padding.y
            self.cards.frame.origin.x = self.frame.width - self.padding.x - self.cards.frame.width
        }
        if animate {
            UIView.animate(withDuration: 0.7, delay: 0, usingSpringWithDamping: 0.8, initialSpringVelocity: 0.6, options: [], animations: updates, completion: nil)
//            UIView.animate(withDuration: 0.4, delay: 0.0, options: [.curveEaseOut], animations: updates, completion: nil)
        } else {
            updates()
        }
        animate = false
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

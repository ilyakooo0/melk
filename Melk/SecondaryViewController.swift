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
            let card = CardView()
            card.post = post
            cards.addArrangedSubview(.spacer(spacer))
            cards.addArrangedSubview(.view(card))
        }
    }
    
//    private let card = CardView()
    private let cards = StackView(axis: .horizontal, alignment: .top)
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        addSubview(cards)
    }
    
    
    private let padding = CGPoint(x: 32, y: 32)
    
    override func layoutSubviews() {
        super.layoutSubviews()
        UIView.animate(withDuration: 0.4, delay: 0.0, options: [.curveEaseOut], animations: { 
            self.cards.layoutIfNeeded()
            self.cards.frame.origin.y = self.padding.y
            self.cards.frame.origin.x = self.frame.width - self.padding.x - self.cards.frame.width
        }, completion: nil)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

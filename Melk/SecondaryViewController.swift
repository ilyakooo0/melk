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
    func add(result: StreamingServiceResult) {
        switch result {
        case .post(let post):
            card.post = post
        }
    }
    
    let card = CardView()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        card.frame.origin = CGPoint(x: 20, y: 20)
        addSubview(card)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

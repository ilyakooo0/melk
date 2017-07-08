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
        self.view = SecondaryView(frame: view.bounds)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

class SecondaryView: UIView {
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        let card = CardView(frame: CGRect(x: 20, y: 20, width: 600, height: 300))
        let post = WallPost()
        post.owner = User()
        post.owner?.firstName = "David"
        post.owner?.avatar = RealmPhoto()
        post.owner?.avatar?.imageSURL = "https://static.independent.co.uk/s3fs-public/styles/article_small/public/thumbnails/image/2017/04/01/17/twitter-egg.jpg"
        card.post = post
        addSubview(card)
        
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

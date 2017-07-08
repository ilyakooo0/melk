//
//  CardView.swift
//  Melk
//
//  Created by Ilya Kos on 7/5/17.
//  Copyright © 2017 Ilya Kos. All rights reserved.
//

import UIKit

class CardView: UIView {
    
    var post: WallPost? {
        didSet {
            update()
        }
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        layer.masksToBounds = true
        layer.cornerRadius = 20
        backgroundColor = #colorLiteral(red: 0.8039215803, green: 0.8039215803, blue: 0.8039215803, alpha: 1)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
//    private let avatar = UIImage()
//    private let name = UIImage()
    
    private func update() {
        subviews.map {$0.removeFromSuperview()}
        
        let largeStack = StackView(axis: .vertical, alignment: .left)
        largeStack.padding = CGPoint(x: 32, y: 32)
        addSubview(largeStack)
        
        let userView = StackView(axis: .horizontal, alignment: .center)
//        userView.backgroundColor = #colorLiteral(red: 0.5568627715, green: 0.3529411852, blue: 0.9686274529, alpha: 1)

        
        let avatarDim: CGFloat = 50
        let avatar = UIImageView()
        post?.owner?.avatar?.load(into: avatar)
        avatar.layer.cornerRadius = avatarDim/2
        avatar.clipsToBounds = true
        avatar.contentMode = .scaleAspectFill
        avatar.layer.minificationFilter = kCAFilterTrilinear
        avatar.frame.size = CGSize(width: avatarDim, height: avatarDim)
        userView.addArrangedSubview(.view(avatar))
        
        userView.addArrangedSubview(.spacer(8))
        
        let userName = UILabel()
        let firstName = post?.owner?.firstName ?? ""
        let lastName = post?.owner?.lastName ?? ""
        userName.text = "\(firstName) \(lastName)"
        userName.font = UIFont.systemFont(ofSize: 28, weight: UIFontWeightHeavy)
        userName.sizeToFit()
        userView.addArrangedSubview(.view(userName))
        userView.frame.origin = CGPoint(x: 16, y: 16)
        
        largeStack.addArrangedSubview(.view(userView))
        
        largeStack.addArrangedSubview(.spacer(16))
        
        let body = UILabel()
        body.numberOfLines = 0
        let bodyWidth: Double = 300
        body.font = UIFont.systemFont(ofSize: 22, weight: UIFontWeightSemibold)
        body.text = post?.body ?? "Spicy jalapeno flank landjaeger sausage tongue tail fatback frankfurter. Meatball tongue tail short ribs pastrami. Short ribs chicken pig tenderloin sausage pork. Corned beef t-bone pancetta jerky chuck picanha venison, turducken tenderloin shoulder boudin drumstick hamburger. Pork meatball meatloaf prosciutto pig andouille. Sirloin bacon hamburger short ribs pork cupim shank biltong turducken bresaola kevin prosciutto shoulder meatball. Strip steak frankfurter pork chop biltong jowl beef rump venison pancetta turkey tongue."
        let size = body.textRect(forBounds: CGRect(x: 0, y: 0, width: bodyWidth, height: Double.infinity), limitedToNumberOfLines: 0).size
        body.frame.size = size
        
        largeStack.addArrangedSubview(.view(body))
        
    }
}

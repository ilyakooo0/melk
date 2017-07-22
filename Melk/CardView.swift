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
//            print(post?.owner)
            update()
        }
    }
    var minWidth: CGFloat = 300 {
        didSet {
            update()
        }
    }
    var height: CGFloat = 400 {
        didSet {
            update()
        }
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        layer.masksToBounds = true
        layer.cornerRadius = 20
        backgroundColor = #colorLiteral(red: 0.9638966278, green: 0.9734401588, blue: 0.9734401588, alpha: 1)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private let padding = CGPoint(x: 32, y: 32)
    private let vPadding1: CGFloat = 16
    private let vPadding2: CGFloat = 16
    private let minTextHeight: CGFloat = 50
    
//    private let avatar = UIImage()
//    private let name = UIImage()
    
    private func update() {
        subviews.map {$0.removeFromSuperview()}
        
        let largeStack = StackView(axis: .vertical, alignment: .left)
        largeStack.padding = padding
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
        
        userView.addArrangedSubview(.spacer(16))
        
        let userName = UILabel()
        let firstName = post?.owner?.firstName ?? ""
        let lastName = post?.owner?.lastName ?? ""
        userName.text = "\(firstName) \(lastName)"
        userName.font = UIFont.systemFont(ofSize: 28, weight: UIFontWeightHeavy)
        userName.sizeToFit()
        userView.addArrangedSubview(.view(userName))
        
        userView.layoutIfNeeded()
        
        largeStack.addArrangedSubview(.view(userView))
        
        largeStack.addArrangedSubview(.spacer(vPadding1))
        
        
        let width = max(minWidth - 2 * padding.x, userView.frame.width)
        
        
        let photoView = CollectionView()
        photoView.alignment = .top
        photoView.horizontalPadding = 8
        photoView.verticalPadding = 8
        photoView.padding = CGPoint.zero
        photoView.maxWidth = width
        var maxPhotoDim: CGFloat = 150
        if let attachments = post?.attachments {
            for attachment in attachments {
                if let v = attachment.value {
                    switch v {
                    case .photo(let photo):
                        if var pWidth = photo.width.value >>> {CGFloat($0)},
                            var pHeight = photo.height.value >>> {CGFloat($0)} {
                            let photoV = UIImageView()
                            photoV.layer.minificationFilter = kCAFilterTrilinear
                            photo.image?.load(into: photoV)
                            var k: CGFloat!
                            if pWidth > pHeight {
                                k = CGFloat(pWidth) / maxPhotoDim
                            } else {
                                k = CGFloat(pHeight) / maxPhotoDim
                            }
                            pWidth /= k
                            pHeight /= k
                            photoV.frame.size = CGSize(width: pWidth, height: pHeight)
                            photoView.addArrangedSubview(photoV)
                        }
                        
                    default:
                        break // TODO: Handle other data types
                    }
                }
            }
        }
        photoView.layoutIfNeeded()
        
        var textHeight = height
        textHeight -= padding.y + vPadding1 + userView.frame.height
        if let count = post?.attachments.count{
            if count > 0 {
                textHeight -= vPadding2 + photoView.frame.height + padding.y
            }
        }
        print(textHeight)
        textHeight = max(textHeight, minTextHeight)
        print(textHeight)
        
        let body = UILabel()
        body.numberOfLines = 0
        let bodyWidth: Double = Double(width)
        body.font = UIFont.systemFont(ofSize: 22, weight: UIFontWeightSemibold)
        body.text = post?.body
        let size = body.textRect(forBounds: CGRect(x: 0, y: 0, width: bodyWidth, height: Double.infinity), limitedToNumberOfLines: 0).size
        body.frame.size.height = min(size.height, textHeight)
        body.frame.size.width = size.width
        
        largeStack.addArrangedSubview(.view(body))
        
        if let count = post?.attachments.count{
            if count > 0 {
                largeStack.addArrangedSubview(.spacer(vPadding2))
                largeStack.addArrangedSubview(.view(photoView))
            }
        }
        
        largeStack.layoutIfNeeded()
        
        frame.size = CGSize(width: width + padding.x * 2, height: min(height, largeStack.frame.height))
        
    }
}

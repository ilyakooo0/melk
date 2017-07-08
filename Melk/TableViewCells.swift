//
//  TableViewCells.swift
//  Melk
//
//  Created by Ilya Kos on 7/2/17.
//  Copyright © 2017 Ilya Kos. All rights reserved.
//

import UIKit

class TitleTableViewCell: UITableViewCell {
    
    var titleText: String = "" {
        didSet {
            title.text = titleText
            setNeedsLayout()
        }
    }
    
    private let title = UILabel()
    
    override init(style: UITableViewCellStyle, reuseIdentifier: String?) {
        title.font = UIFont.systemFont(ofSize: 28, weight: UIFontWeightHeavy) // UIFont.preferredFont(forTextStyle: .title1)
//        print(title.font.pointSize) // 28
        super.init(style: style, reuseIdentifier: TitleTableViewCell.identifier)
        contentView.addSubview(title)
        setNeedsLayout()
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        title.sizeToFit()
        title.frame.origin = CGPoint(x: 16, y: 16)
        print(title.frame.height)
    }
    
    override func prepareForReuse() {
        
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    static let identifier = "io.Melk.titleTableViewCell"
    static let height: CGFloat = 33.5 + 16 + 8
}

class TagTableViewCell: UITableViewCell {
    var tagString: String? {
        set {
            textField.text = newValue
            setNeedsLayout()
        }
        get {
            return textField.text
        }
    }
    
    var style: TagStyle = .normal {
        didSet {
            updateStyle()
        }
    }
    
    private let textField = UITextField()
    
    override init(style: UITableViewCellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        
        textField.borderStyle = .roundedRect
        textField.adjustsFontSizeToFitWidth = false
        
        contentView.addSubview(textField)
//        textField.delegate = self
//        textField.font
        
    }
    
    private func updateStyle() {
        textField.font = style.font
        setNeedsLayout()
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        let label = UILabel()
        label.text = "MH"
        label.font = style.font
        let height = label.textRect(forBounds:
            CGRect.infinite, limitedToNumberOfLines: 1)
            .height + 2*2
        
        let frame = CGRect(x: 16, y: 8, width: bounds.width - 16*2, height: height)
        textField.frame = frame
        print(textField.frame)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    
    static let identifier = "io.Melk.tagTableViewCell"
    static let largeHeight: CGFloat = 37.5 + 8*2
    static let normalHeight: CGFloat = 28.0 + 8*2
}

//extension TagTableViewCell: UITextFieldDelegate {
//    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
//        
//        return true
//    }
//}

enum TagStyle {
    case normal
    case large
    
    private static let largeFont = UIFont.systemFont(ofSize: 28, weight: UIFontWeightHeavy)
    private static let normalFont = UIFont.systemFont(ofSize: 20, weight: UIFontWeightSemibold)
    
    var font: UIFont {
        switch self {
        case .normal:
            return TagStyle.normalFont
        case .large:
            return TagStyle.largeFont
        }
    }
}





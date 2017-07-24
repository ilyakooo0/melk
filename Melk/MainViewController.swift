//
//  MainViewController.swift
//  Melk
//
//  Created by Ilya Kos on 7/1/17.
//  Copyright © 2017 Ilya Kos. All rights reserved.
//

import UIKit

class MainViewController: UIViewController {
    
    var present: (([String]) -> ())?
    
    private let mainView = MainView()
    
    init() {
        super.init(nibName: nil, bundle: nil)
        self.view = mainView
        let rightButton = UIBarButtonItem()
        rightButton.title = "Present"
        rightButton.target = self
        rightButton.action = #selector(MainViewController.presentTags)
        self.navigationItem.rightBarButtonItem = rightButton
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    @objc private func presentTags() {
        present?(
            mainView.tags.flatMap({$0}).filter({$0 != ""})
        )
    }
}

class MainView: UIView {
    let tableView = UITableView()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        addSubview(tableView)
        tableView.dataSource = self
        tableView.delegate = self
        tableView.estimatedRowHeight = 30
        tableView.rowHeight = UITableViewAutomaticDimension
        tableView.register(TitleTableViewCell.self, forCellReuseIdentifier: TitleTableViewCell.identifier)
        tableView.register(TagTableViewCell.self, forCellReuseIdentifier: TagTableViewCell.identifier)
        tableView.separatorStyle = .none
        tableView.allowsSelection = false
        setNeedsLayout()
    }
    
    override func layoutSubviews() {
        tableView.frame = bounds
    }
    
    fileprivate var tags: [String?] = [nil] {
        didSet {
            if tags.last! != nil && tags.last! != "" {
                if tags.count < 10 {
                    tags.append(nil)
                    tableView.insertRows(at: [IndexPath.init(row: tags.count - 1, section: 0)], with: .automatic)
                }
            }
        }
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

extension MainView: UITableViewDataSource {
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if let cell = tableView.dequeueReusableCell(withIdentifier: TagTableViewCell.identifier) as? TagTableViewCell {
//            cell.titleText = "Testing testing 1 2 3"
            cell.style = indexPath.item == 0 ? .large : .normal
            let index = indexPath.row
            cell.tagDidChange = { tag in
                self.tags[index] = tag
            }
            cell.tagString = tags[index]
            return cell
        }
        return UITableViewCell()
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return tags.count
    }
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return indexPath.item == 0 ? TagTableViewCell.largeHeight : TagTableViewCell.normalHeight
    }
    
}
 

extension MainView: UITableViewDelegate {
    
}

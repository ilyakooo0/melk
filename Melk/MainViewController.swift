//
//  MainViewController.swift
//  Melk
//
//  Created by Ilya Kos on 7/1/17.
//  Copyright © 2017 Ilya Kos. All rights reserved.
//

import UIKit

class MainViewController: UIViewController {
    
    let mainView = MainView()
    
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
    
    func presentTags() {
        
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
        setNeedsLayout()
    }
    
    override func layoutSubviews() {
        tableView.frame = bounds
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
            return cell
        }
        return UITableViewCell()
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 3
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

//
//  Coordinator.swift
//  Melk
//
//  Created by Ilya Kos on 7/1/17.
//  Copyright © 2017 Ilya Kos. All rights reserved.
//

import UIKit

class MainCoordinator {
    let window: UIWindow
    let mainVC = MainViewController()
    let navC: UINavigationController!
    let secondaryCoord = SecondaryCoordinator()
    init(window: UIWindow) {
        self.window = window
        navC = UINavigationController(rootViewController: mainVC)
        window.rootViewController = navC
        updateScreens()
    }
    
    func updateScreens() {
        secondaryCoord.updateScreens()
    }
}

//
//  SecondaryCoordinator.swift
//  Melk
//
//  Created by Ilya Kos on 7/1/17.
//  Copyright © 2017 Ilya Kos. All rights reserved.
//

import UIKit

class SecondaryCoordinator {
    
    var windows: [UIWindow] = []
    
    func add(result: StreamingServiceResult) {
        for vc in VCs {
            vc.add(result: result)
        }
    }
    
    init() {
        
    }
    
    private var VCs: [SecondaryViewController] = []
    
    func updateScreens() {
        windows.removeAll()
        VCs.removeAll()
        for screen in UIScreen.screens.dropFirst() {
            let window = UIWindow(frame: screen.bounds)
            window.backgroundColor = #colorLiteral(red: 1, green: 1, blue: 1, alpha: 1)
            window.screen = screen
            window.isHidden = false
            let VC = SecondaryViewController()
            VCs.append(VC)
            window.rootViewController = VC
            windows.append(window)
        }
    }
}

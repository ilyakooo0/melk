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
    
    private var didStartPresenting = false
    private var tag: String = ""
    
    func add(result: StreamingServiceResult) {
        for vc in VCs {
            vc.add(result: result)
        }
    }
    
    func present(tag newTag: String) {
        didStartPresenting = true
        self.tag = newTag
        VCs.map({ $0.present(tag: newTag) })
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
            if didStartPresenting {
                VC.present(tag: tag)
            }
        }
    }
}

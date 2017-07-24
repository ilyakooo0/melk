//
//  Coordinator.swift
//  Melk
//
//  Created by Ilya Kos on 7/1/17.
//  Copyright © 2017 Ilya Kos. All rights reserved.
//

import UIKit
import RealmSwift
//import SwiftyVK

class MainCoordinator {
    let window: UIWindow
    let mainVC = MainViewController()
    let loadingVC = UIViewController() // TODO: An actual loading VC
    let navC: UINavigationController!
    let secondaryCoord = SecondaryCoordinator()
    let stream = StreamingService()
    init(window: UIWindow) {
        self.window = window
        window.rootViewController = loadingVC
        
        Realm.Configuration.defaultConfiguration = Realm.Configuration
            .init(inMemoryIdentifier: "com.ilyakooo0.Melk.realm",
                  readOnly: false,
                  deleteRealmIfMigrationNeeded: true)
        
        navC = UINavigationController(rootViewController: mainVC)
        
        mainVC.present = { tags in
            if tags.count > 0 {
                self.secondaryCoord.present(tag: tags.first!)
                self.stream.rules = tags
                self.stream.connect()
            }
        }
        updateScreens()
        stream.handleResult = { result in
            self.secondaryCoord.add(result: result)
//            switch result {
//            case .post(let post):
//                
//            }
        }
    }
    
    func start() {
//        VK.configure(withAppId: appID, delegate: self)
//        if VK.state != .authorized {
//            VK.logIn()
//        }
        print("didAuthorize")
        window.rootViewController = navC
    }
    
    func updateScreens() {
        secondaryCoord.updateScreens()
    }
}
/*
extension MainCoordinator: VKDelegate {
    /** ---DEPRECATED. TOKEN NOW STORED IN KEYCHAIN--- Called when SwiftyVK need know where a token is located
     - returns: Path to save/read token or nil if should save token to UserDefaults*/
    func vkShouldUseTokenPath() -> String? {
        return nil
    }
    
    func vkWillAuthorize() -> Set<VK.Scope> {
        //Called when SwiftyVK need authorization permissions.
        return permissions
    }
    
    func vkDidAuthorizeWith(parameters: Dictionary<String, String>) {
        //Called when the user is log in.
        //Here you can start to send requests to the API.
        print("authorized")
        mainSync {
            self.window.rootViewController = self.navC
        }
        authorized()
    }
    
    func vkAutorizationFailedWith(error: AuthError) {
        //Called when SwiftyVK could not authorize. To let the application know that something went wrong.
        print("failed auth with error \(error.errorCode): \(error.description)")
        mainSync {
            self.window.rootViewController = self.navC
        }
    }
    
    func vkDidUnauthorize() {
        print("did unauthorize")
        mainSync {
            self.window.rootViewController = self.navC
        }
        //Called when user is log out.
    }
        
    func vkWillPresentView() -> UIViewController {
        //Only for iOS!
        //Called when need to display a view from SwiftyVK.
        let authController = UIViewController()
        mainSync {
            self.window.rootViewController = authController
        }
        return authController //UIViewController that should present authorization view controller
    }
    
}
 */

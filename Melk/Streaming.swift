//
//  Streaming.swift
//  Melk
//
//  Created by Ilya Kos on 7/9/17.
//  Copyright © 2017 Ilya Kos. All rights reserved.
//

import Foundation
import SwiftWebSocket
import Alamofire
import SwiftyJSON

class Streaming {
    
    let streamingServerSurl = "https://api.vk.com/method/streaming.getServerUrl"
    let params: [String: String] = [
        "access_token": accessKey,
        "v": vkAPIVersion
    ]
    
    private var key: String?
    private var server: String?
    let ws = WebSocket()
    
    var processItem: ((Any) -> ())?
    
    func getServer(completion: (() -> ())? = nil) {
        Alamofire.request(streamingServerSurl, parameters: params).validate().responseData { (response) in
            switch response.result {
            case .success(let data):
                let json = JSON.init(data: data)["response"]
                self.key = json["key"].string
                self.server = json["endpoint"].string
            case .failure(let error):
                print(error)
            }
            DispatchQueue.main.async {
                completion?()
            }
        }
    }
    
    func add(rule: Rule, completion: (() -> ())? = nil) {
        if let key = key,
            let server = server {
            let url = "https://\(server)/rules?key=\(key)"
            let request: [String: Any] = [
                "rule": [
                    "value": rule.rule,
                    "tag": rule.tag
                ]
            ]
            print(try? JSONSerialization.data(withJSONObject: request, options: .prettyPrinted) =>> {String.init(data: $0, encoding: .utf8)})
            Alamofire.request(url, method: .post, parameters: request, encoding: JSONEncoding.default)
                .validate().responseData(completionHandler: { (response) in
                switch response.result {
                case .success(let data):
                    let json = JSON.init(data: data)
                    print(json) // TODO: Handle error
                case .failure(let error):
                    print(error)
                }
                DispatchQueue.main.async {
                    completion?()
                }
            })
        } else {
            getServer() {
                self.add(rule: rule, completion: completion)
            }
        }
    }
    func add(rules: [Rule], completion: (() -> ())? = nil) {
        if let server = server,
            let key = key {
            var numOfCompletions = rules.count + 1
            let complete: (() -> ()) = {
                numOfCompletions -= 1
                if numOfCompletions == 0 {
                    completion?()
                }
            }
            
            complete()
            
            for rule in rules {
                add(rule: rule, completion: complete)
            }
        } else {
            getServer() {
                self.add(rules: rules, completion: completion)
            }
        }
    }
    func getRules(completion: @escaping (([Rule]?) -> ())) {
        if let server = server,
            let key = key {
            let url = "https://\(server)/rules?key=\(key)"
            Alamofire.request(url, method: .get).validate().responseData { (response) in
                switch response.result {
                case .success(let data):
                    let json = JSON.init(data: data)
                    print(json)
                    if json["code"].int == 200 {
                        var resultRules: [Rule] = []
                        if let rules = json["rules"].array {
                            for rule in rules {
                                if let tag = rule["tag"].string,
                                    let value = rule["value"].string {
                                    resultRules.append((rule: value, tag: tag))
                                }
                            }
                        }
                        completion(resultRules)
                    } // TODO" Handle errors
                case .failure(let error):
                    print(error) // TODO: HAndl;e error
                }
            }
        } else {
            getServer() {
                self.getRules(completion: completion)
            }
        }
    }
    func remove(rule: Rule, completion: (() -> ())? = nil) {
        if let server = server,
            let key = key {
            let url = "https://\(server)/rules?key=\(key)"
            let request: [String: Any] = [
                "tag": rule.tag
            ]
            Alamofire.request(url, method: .delete, parameters: request, encoding: JSONEncoding.default).validate().responseData { response in
                switch response.result {
                case .success(let data):
                    let json = JSON.init(data: data)
                    print(json) // TODO: HAndle error
                    completion?()
                case .failure(let error):
                    print(error) // TODO: HAndl;e error
                }
            }
        } else {
            getServer() {
                self.remove(rule: rule, completion: completion)
            }
        }
    }
    func removeAllRules(completion: (() -> ())? = nil) {
        getRules { (rules) in
            if let rules = rules {
                
                var numOfCompleted = rules.count + 1
                let complete : (() -> ()) = {
                    numOfCompleted -= 1
                    if numOfCompleted == 0 {
                        completion?()
                    }
                }
                
                complete()
                
                for rule in rules {
                    self.remove(rule: rule, completion: complete)
                }
            }
        }
    }
    func connect(completion: (() -> ())? = nil) {
        if let key = key,
            let server = server {
            let surl = "wss://\(server)/stream?key=\(key)"
            let url = URL(string: surl)!
            ws.event.message = { message in
                self.processItem?(message)
            }
            let request = NSMutableURLRequest(url: url)
            request.httpMethod = "GET"
            request.addValue("upgrade", forHTTPHeaderField: "Connection")
            request.addValue("websocket", forHTTPHeaderField: "Upgrade")
            request.addValue("13", forHTTPHeaderField: "Sec-Websocket-Version")
            ws.open(request: request as URLRequest)
            DispatchQueue.main.async {
                completion?()
            }
        } else {
            getServer() {
                self.connect(completion: completion)
            }
        }
    }
}

typealias Rule = (rule: String, tag: String)

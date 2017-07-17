//
//  StreamingService.swift
//  Melk
//
//  Created by Ilya Kos on 7/12/17.
//  Copyright © 2017 Ilya Kos. All rights reserved.
//

import Foundation

class StreamingService {
    init() {
        streaming.processItem = { item in
            if let string = item as? String,
                let data = string.data(using: .utf8),
                let json = try? JSONSerialization.jsonObject(with: data, options: []) {
                StreamingParser.parse(json: json, completion: { (result) in
                    switch result {
                    case .post(let post):
                        self.handleResult?(.post(post))
                    case .service:
                        break // TODO: HAndle servoce message
                    }
                })
            }
        }
    }
    var rules: [String] = [] {
        didSet {
            updateRules()
        }
    }
    
    func connect() {
        streaming.connect()
    }
    
    var handleResult: ((StreamingServiceResult) -> ())?
    
    
    
    private let streaming = Streaming()

    private func updateRules() {
        streaming.removeAllRules {
            var outRules: [Rule] = []
            var i = 1
            for rule in self.rules {
                if i <= 10 {
                    outRules.append((rule: rule, tag: String(i)))
                    i += 1
                }
            }
            self.streaming.add(rules: outRules)
        }
    }
}

enum StreamingServiceResult {
    case post(WallPost)
}

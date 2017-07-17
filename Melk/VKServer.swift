//
//  VKServer.swift
//  Melk
//
//  Created by Ilya Kos on 7/12/17.
//  Copyright © 2017 Ilya Kos. All rights reserved.
//

import Foundation
import Alamofire

class VKServer {
    static func get(photo: Photo, completion: @escaping ((Data) -> ())) {
        func string(`for` photo: Photo) -> String? {
            if let ownerID = photo.owner?.id {
                let id = photo.id
                var out = "\(ownerID)_\(id)"
                if let accessKey = photo.accessKey {
                    out.append("_\(accessKey)")
                }
                return out
            }
            return nil
        }
        let params: Parameters = [
            "photos": string(for: photo)!
        ]
        Alamofire.request(url(for: "photos.getById"), parameters: params)
            .validate().responseData { (response) in
                switch response.result {
                case .success(let data):
                    completion(data)
                case .failure(let error):
                    print(error)
                }
        }
    }
    static func get(video: Video, completion: @escaping ((Data) -> ())) {
        func string(`for` video: Video) -> String? {
            if let ownerID = video.owner?.id {
                let id = video.id
                var out = "\(ownerID)_\(id)"
                if let accessKey = video.accessKey {
                    out.append("_\(accessKey)")
                }
                return out
            }
            return nil
        }
        let params: Parameters = [
            "videos": string(for: video)!
        ]
        Alamofire.request(url(for: "videos.get"), parameters: params)
            .validate().responseData { (response) in
                switch response.result {
                case .success(let data):
                    completion(data)
                case .failure(let error):
                    print(error)
                }
        }
    }
    static func get(doc: Document, completion: @escaping ((Data) -> ())) {
        if let userID = doc.owner?.id {
            let id = doc.id
            let params: Parameters = [
                "docs": "\(userID)_\(id)"
            ]
            Alamofire.request(url(for: "docs.getById"), parameters: params)
                .validate().responseData(completionHandler: { (response) in
                    switch response.result {
                    case .success(let data):
                        completion(data)
                    case .failure(let error):
                        print(error)
                    }
                })
        }
    }
    static func get(user: User, completion: @escaping ((Data) -> ())) {
        let id = user.id
        let params: Parameters = [
            "user_ids": id
        ]
        Alamofire.request(url(for: "users.get"), parameters: params)
            .validate().responseData { (response) in
                switch response.result {
                case .success(let data):
                    completion(data)
                case .failure(let error):
                    print(error)
                }
        }
    }
    static func get(wallPost: WallPost, completion: @escaping ((Data) -> ())) {
        if let userID = wallPost.owner?.id {
            let id = wallPost.id
            let params: Parameters = [
                "posts": "\(userID)_\(id)"
            ]
            Alamofire.request(url(for: "wall.getById"), parameters: params)
            .validate().responseData(completionHandler: { (response) in
                switch response.result {
                case .success(let data):
                    completion(data)
                case .failure(let error):
                    print(error)
                }
            })
        }
    }
    
    static func get(wallPostReply: WallPostReply, completion: @escaping ((Data) -> ())) {
        // TODO: Get wallPostReply
    }
    
}

fileprivate func url(`for` method: String) -> URL {
    let surl = "https://api.vk.com/method/\(method)?access_token=\(accessKey)&v=\(vkAPIVersion)"
    return URL.init(string: surl)!
}

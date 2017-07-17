//
//  StreamingParser.swift
//  Melk
//
//  Created by Ilya Kos on 7/12/17.
//  Copyright © 2017 Ilya Kos. All rights reserved.
//

import Foundation
import Decodable

class StreamingParser {
    static func parse(json: DJSON, completion: @escaping ((StreamingResponse) -> ())) {
        do {
            let code: Int = try json => "code"
            switch code {
            case 100:
                let event = try json => "event"
                let eventType: String = try event => "event_type"
                let eventID = try event => "event_id"
                let postID: WallPostID = try eventID => "post_id"
                let ownerID: UserID = try eventID => "post_owner_id"
                //                let
                realmWrite { _ in
                    let post = WallPost.by(id: postID)
                    post.owner = User.by(id: ownerID)
                    var comp = 2
                    let complete = {
                        comp -= 1
                        if comp == 0 {
                            completion(.post(post))
                        }
                    }
                    switch eventType {
                    case "post":
                        break
                    case "comment":
                        /*
                        if let id: Int = try? eventID => "comment_id" {
                            let comment = WallPostReply.by(id: id)
                            comment.wallPost = post
                            comp += 1
                            comment // TODO: get comment
                        }
 */
                        print("comment not implemented")
                        
                    case "share":
                        break
                    default:
                        print("error:\n\(json)")
                    }
                    post.owner?.get(completion: { (_) in
                        complete()
                    })
                    post.get(completion: { (_) in
                        complete()
                    })
                }
            break // handle event
            case 300:
            break // handle service message
            default:
                print("Not implemented:\n\(json)\n")
            }
        } catch let error {
            print(error)
        }
    }
}

enum StreamingResponse {
    case service
    case post(WallPost)
}

typealias DJSON = Any

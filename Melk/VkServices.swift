//
//  VkServices.swift
//  golos
//
//  Created by Ilya Kos on 7/24/16.
//  Copyright © 2016 Ilya Kos. All rights reserved.
//

import UIKit
import Alamofire
import SwiftyVK

// let realm = try! Realm()

class VkServices {
    class func getDialogs(offset: Int = 0, count: Int = 200, completion: (() -> ())? = nil) { // Messages
        VK.API.remote(method: Methods.getDialogs, parameters:
            [VK.Arg.offset: String(offset),
             VK.Arg.count: String(count)])
            .send(onSuccess: { (response) in
            if let usersJSON = response[1].array,
                let chatUsersJSON = response[2].array,
                let dialogs = response[0]["items"].array,
                let chatUserInvitersJSON = response[3].array,
                let multichatsJSON = response[4].array { // TODO: Catch error from vk
                userQueue.async {
                    let _ = usersJSON.map(VKData.processUser)
                    let _ = chatUsersJSON.map(VKData.processUser)
                    let _ = chatUserInvitersJSON.flatMap(VKData.processUser)
                    let _ = multichatsJSON.map(VKData.processMultichat)
                    let _ = dialogs.map(VKData.processDialog)
                    print("DONEZO")
                    DispatchQueue.main.async {
                        completion?()
                    }
                }
            }
        }, onError: { error in
            print(error)
        }) // TODO: Handle error
    }
    
    
    /// - Parameters:
    ///   - dialog: in the `200000000` and `-` fomat
    ///   - count: count
    ///   - offset: offset
    ///   - completion: completion handler
    class func getMessages(forDialog dialog: DialogID, count: Int = 20, offset: Int = 0, completion: (() -> ())? = nil) {
        var params: [VK.Arg: String] = [
            VK.Arg.peerId: String(dialog),
            VK.Arg.offset: String(offset),
            VK.Arg.count: String(count)]
        var request = VK.API.Messages.getHistory()
        request.add(parameters: params)
        request.send(onSuccess: { (response) in
            userQueue.async {
                realmWrite { _ in
                    let rDialog = RealmDialog.by(peerID: dialog)
                    var f = rDialog.value
                    f <- response["items"].array?.flatMap(VKData.processMessage)
                    f?.lastReadMessageID = max(response["out_read"].intValue, response["in_read"].intValue) // TODO: Probrably should use seperate things for readin and readout
                    response["count"].int >>> { rDialog.value?.count.value = $0 }
                }
            }
        }, onError: nil) // TODO: Handle error
        
        completion?()
    }
    
    class func send(_ message: Message, to dialog: RealmDialog, completion: (() -> ())? = nil) {
        let date = Date()
        let time = Int(date.timeIntervalSince1970) * 100
        var params: [VK.Arg: String] = [:]
        if let d = dialog.value {
            switch d {
            case let chat as Chat:
                params[VK.Arg.peerId] = String(chat.userID)
            case let mchat as Multichat:
                params[VK.Arg.chatId] = String(mchat.id)
            default:
                break
            }
        }
        if dialog.dateLastSent == date {
            realmWrite({ (_) in
                dialog.dateSentNumber += 1
            })
        } else {
            realmWrite({ (_) in
                dialog.dateSentNumber = 1
                dialog.dateLastSent = date
            })
        }
        
        var i = 0
        func photoUploadRequest() {
            if i < message.outPhotos.count {
                if let data = UIImagePNGRepresentation(message.outPhotos[i]) {
                    let request = VK.API.Upload.Photo.toMessage(SwiftyVK.Media.init(imageData: data, type: .PNG))
                    request.send(onSuccess: { (response) in
                        if let photo = VKData.processPhoto(response) { // TODO: this probrably shouldnt happen on the main queue
                            message.attachments.append(RealmMedia(value: Media.photo(photo)))
                        }
                        i += 1
                        photoUploadRequest()
                    }, onError: nil) // TODO: Handle error
                } else {
                    i += 1
                    photoUploadRequest()
                }
            }
        }
        
        
        
        params[VK.Arg.randomId] = String(time + dialog.dateSentNumber)
        params[VK.Arg.message] = String(message.body)
        message.geolocation?.geoCoordinates?.coordinate.latitude >>> {params[VK.Arg.lat] = String($0)}
        message.geolocation?.geoCoordinates?.coordinate.longitude >>> {params[VK.Arg.long] = String($0)}
        var att = ""
        var stickerID: Int?
        for m in message.attachments {
            m.string >>> { att.append("\($0),") }
            if stickerID == nil {
                if let v = m.value {
                    switch v {
                    case .sticker(let s):
                        stickerID = s.id
                    default:
                        break
                    }
                }
            }
        }
        params[VK.Arg.attachments] = att
        var fm = ""
        for m in message.forwardedMessages {
            m.id >>> {fm.append("\($0),")}
        }
        params[VK.Arg.forwardMessages] = fm
        stickerID >>> {params[VK.Arg.stickerId] = String($0)}
        VK.API.Messages.send(params).send(onSuccess: { (response) in
            if let id = response.int {
                realmWrite({ (_) in
                    message.id = id
                    dialog.value?.messages <~ message // TODO: Uncomment this
                })
            }
            completion?()
        }, onError: nil) // TODO: Handle error
    }
    class func getMultichat(for id: MultichatID) {
        let params: [VK.Arg: String] = [
            VK.Arg.chatId: String(id),
            VK.Arg.fields: "nickname, screen_name, sex, bdate, city, country, timezone, photo_50, photo_100, photo_200_orig, has_mobile, contacts, education, online, counters, relation, last_seen, status, can_write_private_message, can_see_all_posts, can_post, universities",
            
            ]
        VK.API.Messages.getChat(params).send(onSuccess: { (response) in
            VKData.processMultichat(response)
        }, onError: nil) // TODO: Handle error
    }
    
}

fileprivate extension RealmMedia {
    var string: String? {
        if let v = value {
            switch v {
            case .photo(let p):
                if let o = p.owner {
                    var out = "photo\(o.id)_\(p.id)"
                    p.accessKey >>> {out.append("_\($0)")}
                    return out
                }
            case .video(let p):
                if let o = p.owner {
                    var out = "video\(o.id)_\(p.id)"
                    p.accessKey >>> {out.append("_\($0)")}
                    return out
                }
            case .audio(let p):
                if let o = p.owner {
                    return "audio\(o.id)_\(p.id)"
                }
            case .doc(let p), .graffiti(let p):
                if let o = p.owner {
                    return "doc\(o.id)_\(p.id)"
                }
            case .wall(let p):
                if let o = p.owner {
                    return "photo\(o.id)_\(p.id)"
                }
            case .market(let p):
                if let o = p.owner {
                    return "photo\(o.id)_\(p.id)"
                }
            default: break
            }
        }
        return nil
    }
}

private func URLFor(method: String) -> String {
    return "https://api.vk.com/method/" + method
}

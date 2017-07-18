//
//  VKData.swift
//  golos
//
//  Created by Ilya Kos on 7/28/16.
//  Copyright © 2016 Ilya Kos. All rights reserved.
//

import Foundation
import SwiftyJSON
import CoreLocation
import RealmSwift
//import SwiftyVK

class VKData {
    //    var users: [UserID: User] = [:]
    //    var multichats: [MultichatID: Multichat] = [:]
    //    var chats: [UserID: Chat] = [:]
    //    var dialogs = SortedArray<Dialog>()
    //    var photos: [PhotoID: Photo] = [:]
    //    var videos: [VideoID: Video] = [:]
    //    var audio: [AudioID: Audio] = [:]
    //    var documents: [DocumentID: Document] = [:]
    //    var wallPosts: [WallPostID: WallPost] = [:]
    //    var wallPostReplys: [WallPostReplyID: WallPostReply] = [:]
    //    var stickers: [StickerID: Sticker] = [:]
    //    var gifts: [GiftID: Gift] = [:]
    //    var markets: [MarketID: Market] = [:]
    //    var marketAlbums: [MarketAlbumID: MarketAlbum] = [:]
    //    var notes: [NoteID: Note] = [:]
    //    var polls: [PollID: Poll] = [:]
    //    var photoAlbums: [PhotoAlbumID: PhotoAlbum] = [:]
    
    class func processUser(json: JSON) -> User? {
        print("in")
        if let id = json["id"].int, let firstName = json["first_name"].string, let lastName = json["last_name"].string {
            var user: User!
            realmWrite({_ in 
                user = User.by(id: id)
                user.firstName = firstName
                user.lastName = lastName
                
                if let birthday = json["bdate"].string {
                    let formatter = DateFormatter()
                    if birthday.characters.split(separator: ".").count == 3 {
                        formatter.dateFormat = "d.M.y"
                    } else {
                        formatter.dateFormat = "d.M"
                    }
                    user.birthday = formatter.date(from: birthday)
                }
                user.avatar = RealmPhoto.by(user.avatarID, surl: json["photo_max"].string)
                user.photo = RealmPhoto.by(user.photoID, surl: json["photo_max_orig"].string)
                if let friendStat = json["friend_status"].int {
                    user.friendStatus = FriendStatus(rawValue: friendStat)
                }
                if let online = json["online"].int {
                    user.online.value = Bool.from(num: online)
                }
                if let canSendIM = json["can_write_private_message"].int {
                    user.canSendPrivateMessage.value = Bool.from(num: canSendIM)
                }
                if let canSendRequest = json["can_send_friend_request"].int {
                    user.canSendFriendRequest.value = Bool.from(num: canSendRequest)
                }
                if let phone = json["mobile_phone"].string, isPhoneNumber(phone) {
                    user.mobilePhone = phone
                }
                if let phone = json["home_phone"].string, isPhoneNumber(phone) {
                    user.homePhone = phone
                }
                if let lastSeen = json["last_seen"].dictionary,
                    let time = lastSeen["time"]?.int {
                    user.lastSeen = Date(timeIntervalSince1970: TimeInterval(time))
                }
                if let deactivated = json["deactivated"].string, let foo = Deactivated(rawValue: deactivated) {
                    user.deactivated = foo
                }
                user.about = json["about"].string
                if let blacklisted = json["blacklisted_by_me"].int {
                    user.blacklisted.value = Bool.from(num: blacklisted)
                }
                user.mutualFriendCount.value = json["common_count"].int
                user.siteSURL = json["site"].string
                user.status = json["status"].string
                print("\(user.id): \(user.firstName ?? "") \(user.lastName ?? "")")
            })
            return user
        }
        return nil
    }
    
    class func processGeolocation(_ json: JSON) -> Geolocation? {
        if let coords = json["coordinates"].string{
            let nums = coords.characters.split(separator: " ").map({ (n) -> Double? in
                NumberFormatter().number(from: String(n))?.doubleValue
            })
            let place = json["place"]
            let geo = Geolocation()
            geo.title = place["title"].string
            geo.country = place["country"].string
            geo.city = place["city"].string
            if let slatt = nums.first,
                let slong = nums.last,
                let latt = slatt,
                let long = slong {
                geo.geoCoordinates = CLLocation(latitude: latt, longitude: long)
            }
            return geo
        } else {
            return nil
        }
    }
    
    class func processMedia(_ json: JSON) -> Media? {
        if let type = json["type"].string {
            switch type {
            case "photo":
                if let id = processPhoto(json["photo"]) {
                    return Media.photo(id)
                }
            case "video":
                if let id = processVideo(json["video"]) {
                    return Media.video(id)
                }
            case "audio":
                if let id = processAudio(json["audio"]) {
                    return Media.audio(id)
                }
            case "doc":
                if let id = processDocument(json["doc"]) {
                    if json["title"].string == "graffiti.png" {
                        return Media.graffiti(id)
                    } else {
                        return Media.doc(id)
                    }
                }
            case "wall":
                if let id = processWallPost(json["wall"]) {
                    return Media.wall(id)
                }
            case "wall_reply":
                if let id = processWallPostReply(json["wall_reply"]) {
                    return Media.wallReply(id)
                }
            case "sticker":
                if let id = processSticker(json["sticker"]) {
                    return Media.sticker(id)
                }
            case "link":
                if let link = processLink(json["link"]) {
                    return Media.link(link)
                }
            case "gift":
                if let id = processGift(json["gift"]) {
                    return Media.gift(id)
                }
            case "poll":
                if let id = processPoll(json["poll"]) {
                    return Media.poll(id)
                }
            case "note":
                if let id = processNote(json["note"]) {
                    return Media.note(id)
                }
            case "album":
                if let id = processPhotoAlbum(json["album"]) {
                    return Media.album(id)
                }
            default:
                break
            }
        }
        return nil
    }
    
    class func processPhotoAlbum(_ json: JSON) -> PhotoAlbum? {
        if let id = json["id"].int{
            var album: PhotoAlbum!
            realmWrite { _ in
                album = PhotoAlbum.by(id: id)
                album.thumb = processPhoto(json["thumb"])
                album.owner = json["owner_id"].int >>> {User.by(id: $0)}
                album.title = json["title"].string
                album.dateCreated = json["created"].int >>> {Date(timeIntervalSince1970: TimeInterval($0))}
                album.dateUpdated = json["updated"].int >>> {Date(timeIntervalSince1970: TimeInterval($0))}
                album.count.value = json["size"].int
                album.albumDescription = json["description"].string
            }
            return album
        }
        return nil
    }
    
    class func processNote(_ json:JSON) -> Note? {
        if let id = json["id"].int {
            var note: Note!
            realmWrite { _ in
                note = Note.by(id: id)
                note.owner = json["owner_id"].int >>> {User.by(id: $0)}
                note.title = json["title"].string
                note.body = json["text"].string
                note.date = json["date"].int >>> {Date(timeIntervalSince1970: TimeInterval($0))}
                note.commentCount.value = json["comments"].int
                note.surl = json["view_url"].string
            }
            return note
        }
        return nil
    }
    
    class func processGift(_ json: JSON) -> Gift? {
        if let id = json["id"].int {
            var gift: Gift!
            realmWrite({ _ in
                gift = Gift.by(id: id)
                gift.image = RealmPhoto.by(gift.imageID, surl: json["thumb_256"].string)
            })
            return gift
        }
        return nil
    }
    
    class func processWallPostReply(_ json: JSON) -> WallPostReply? {
        let likes = json["likes"]
        if let id = json["id"].int {
            var reply: WallPostReply!
            realmWrite { _ in
                reply = WallPostReply.by(id: id)
                reply.author = json["from_id"].int >>> {User.by(id: $0)}
                reply.date = json["date"].int >>> {Date(timeIntervalSince1970: TimeInterval($0))}
                reply.body = json["text"].string
                reply.wallPost = json["post_id"].int >>> {WallPost.by(id: $0)}
                reply.wallOwner = json["owner_id"].int >>> {User.by(id: $0)}
                reply.likeCount.value = likes["count"].int
                reply.didLike.value = likes["user_likes"].int?.bool
                reply.canLike.value = likes["can_like"].int?.bool
                if let attachmentsJSON = json["attachments"].array {
                    for att in attachmentsJSON {
                        processMedia(att)?.realm >>> {reply.attachments.append($0)}
                    }
                }
                reply.inReplyToUser = json["reply_to_user"].int >>> {User.by(id: $0)}
                reply.inReplyToComment = json["reply_to_comment"].int >>> {WallPostReply.by(id: $0)}
            }
            return reply
        }
        return nil
    }
    
    class func processPollAnswer(_ json: JSON) -> PollAnswer? {
        if let id = json["id"].int,
            let body = json["text"].string,
            let votes = json["votes"].int,
            let rate = json["rate"].int {
            return PollAnswer(id: id, body: body, votes: votes, rating: rate)
        }
        return nil
    }
    
    class func processPoll(_ json: JSON) -> Poll? {
        if let id = json["id"].int {
            var poll: Poll!
            realmWrite { _ in
            poll = Poll.by(id: id)
                    poll.owner = json["owner_id"].int >>> {User.by(id: $0)}
                    poll.date = json["created"].int >>> {Date(timeIntervalSince1970: TimeInterval($0))}
                    poll.question = json["question"].string
                    poll.votes.value = json["votes"].int
                    if let answersJSON = json["answers"].array {
                        for ans in answersJSON {
                            processPollAnswer(ans) >>> {poll.answers.append($0)}
                        }
                    }
                    poll.answerID.value = json["answer_id"].int
                }
            return poll
        }
        return nil
    }
    
    class func processPhoto(_ json: JSON) -> Photo? {
        if let id = json["id"].int {
            var photo: Photo!
            realmWrite { _ in
                photo = Photo.by(id: id)
                photo.owner = json["owner_id"].int >>> {User.by(id: $0)}
                photo.date = json["date"].int >>> {Date.init(timeIntervalSince1970: TimeInterval($0))}
                photo.width.value = json["width"].int
                photo.height.value = json["height"].int
                var surl: String?
                if let imageSurl = json["photo_2560"].string {
                    surl = imageSurl
                } else if let imageSurl = json["photo_1280"].string {
                    surl = imageSurl
                } else if let imageSurl = json["photo_807"].string {
                    surl = imageSurl
                } else if let imageSurl = json["photo_604"].string {
                    surl = imageSurl
                } else if let imageSurl = json["photo_130"].string {
                    surl = imageSurl
                } else if let imageSurl = json["photo_75"].string {
                    surl = imageSurl
                }
                photo.image = RealmPhoto.by(photo.imageID, surl: surl)
                photo.thumbnail = RealmPhoto.by(photo.thumbnailID, surl: json["photo_75"].string)
                photo.accessKey = json["access_key"].string
            }
            return photo
        } else {
            return nil
        }
    }
    
    class func processVideo(_ json: JSON) -> Video? {
        if let id = json["id"].int {
            var video: Video!
            realmWrite { _ in
                video = Video.by(id: id)
                video.owner = json["owner_id"].int >>> {User.by(id: $0)}
                video.title = json["title"].string
                video.duration.value = json["duartion"].int >>> {TimeInterval.init($0)}
                video.videoDescription = json["description"].string
                if let _ = json["live"].int {
                    video.isLive = true
                }
                if let _ = json["processing"].int {
                    video.isProcessing = true
                }
                video.accessKey = json["access_key"].string
                video.thumbnail = RealmPhoto.by(video.thumbnailID, surl: json["photo_320"].string)
                video.playerSURL = json["player"].string
            }
            return video
        } else {
            return nil
        }
    }
    
    class func processAudio(_ json: JSON) -> Audio? {
        if let id = json["id"].int {
            var audio: Audio!
            realmWrite { _ in
                audio = Audio.by(id: id)
                audio.owner = json["owner_id"].int >>> {User.by(id: $0)}
                audio.artist = json["artist"].string
                audio.title = json["title"].string
                audio.duration.value = json["duration"].int >>> {TimeInterval($0)}
                audio.surl = json["url"].string
            }
            return audio
        } else {
            return nil
        }
    }
    
    class func processDocument(_ json: JSON) -> Document? {
        if let id = json["id"].int {
            var doc: Document!
            realmWrite { _ in
                doc = Document.by(id: id)
                doc.owner = json["owner_id"].int >>> {User.by(id: $0)}
                doc.title = json["title"].string
                doc.size.value = json["size"].int
                doc.fileExtension = json["ext"].string
                doc.surl = json["url"].string
                doc.type = json["type"].int =>> {DocumentType(rawValue: $0)}
            }
            return doc
        }
        return nil
    }
    
    class func processSticker(_ json: JSON) -> Sticker? {
        if let id = json["id"].int,
            let pack = json["product_id"].int {
            var sticker: Sticker!
            realmWrite { _ in
                sticker = Sticker.by(id: id)
                sticker.packID = pack
                sticker.image = RealmPhoto.by(sticker.imageID, surl: json["photo_352"].string)
                sticker.width.value = json["width"].int
                sticker.height.value = json["height"].int
            }
            return sticker
        }
        return nil
    }
    
    class func processRating(_ json: JSON) -> Rating? {
        if let stars = json["stars"].int,
            let reviewCount = json["reviews_count"].int {
            return Rating(stars: stars, reviewCount: reviewCount)
        }
        return nil
    }
    
    class func processButton(_ json: JSON) -> LinkButton? {
        if let title = json["title"].string,
            let surl = json["url"].string,
            let url = URL(string: surl) {
            return LinkButton(title: title, url: url)
        }
        return nil
    }
    
    class func processLink(_ json: JSON) -> Link? {
        if let surl = json["url"].string {
            var link: Link!
            realmWrite({ (_) in
                link = Link.by(surl: surl)
                link.title = json["title"].string
                link.linkDescription = json["description"].string
                link.caption = json["caption"].string
                link.photo = processPhoto(json["photo"])
                link.isExternal.value = json["is_external"].int?.bool
                link.rating = processRating(json["rating"])
                link.button = processButton(json["button"])
            })
            return link
        }
        return nil
    }
    
    class func processWallPost(_ json: JSON) -> WallPost? {
        let comments = json["comments"]
        let likes = json["likes"]
        let reposts = json["reposts"]
        if let id = json["id"].int {
            var post: WallPost!
            realmWrite { _ in
                post = WallPost.by(id: id)
                post.owner = json["owner_id"].int >>> {User.by(id: $0)}
                post.creator = json["from_id"].int >>> {User.by(id: $0)}
                post.date = json["date"].int >>> {Date.init(timeIntervalSince1970: TimeInterval($0))}
                post.body = json["text"].string
                post.commentCount.value = comments["count"].int
                post.canPostComment.value = comments["can_post"].int?.bool
                post.likeCount.value = likes["count"].int
                if let sLiked = likes["user_likes"].int?.bool {
                    post.liked = sLiked
                }
                post.canLike.value = likes["can_like"].int?.bool
                post.repostCount.value = reposts["count"].int
                post.didRepost.value = reposts["user_resposted"].int?.bool
                post.canDelete.value = json["can_delete"].int?.bool
                if let attachmentsJSON = json["attachments"].array {
                    for att in attachmentsJSON {
                        processMedia(att) >>> {post.attachments.append(RealmMedia(value: $0))}
                    }
                }
                post.geo = processGeolocation(json["geo"])
                post.signed = json["signer_id"].int >>> {User.by(id: $0)}
                post.original = json["reply_post_id"].int >>> {WallPost.by(id: $0)}
                post.ownerOfCopy = json["reply_owner_id"].int >>> {User.by(id: $0)}
                if let sCopyHistory = json["copy_history"].array {
                    for pos in sCopyHistory {
                        if let po = processWallPost(pos) {
                            post.historyOfCopy.append(po)
                        }
                    }
                }
                post.canPin.value = json["can_pin"].int?.bool
                post.canEdit.value = json["can_edit"].int?.bool
                post.isPinned.value = json["is_pinned"].int?.bool
            }
            return post
        }
        return nil
    }
    
    class func prpocessServiceMessageAction(_ json: JSON) -> ServiceMessageAction? {
        if let sAction = json["action"].string {
            switch sAction {
            case "chat_photo_update":
                return ServiceMessageAction.photoUpdate
            case "chat_photo_remove":
                return ServiceMessageAction.photoRemove
            case "chat_create":
                if let title = json["action_text"].string {
                    return ServiceMessageAction.create(title)
                }
            case "chat_title_update":
                if let title = json["action_text"].string {
                    return ServiceMessageAction.titleUpdate(title)
                }
            case "chat_invite_user":
                if let id = json["action_mid"].int {
                    if id < 0 {
                        if let email = json["action_email"].string {
                            return ServiceMessageAction.inviteUser(.email(email))
                        }
                    } else {
                        var act: ServiceMessageAction!
                        realmWrite { _ in
                            act = ServiceMessageAction.inviteUser(.user(User.by(id: id)))
                        }
                        return act
                    }
                }
            case "chat_kick_user":
                if let id = json["action_mid"].int {
                    if id < 0 {
                        if let email = json["action_email"].string {
                            return ServiceMessageAction.kickUser(.email(email))
                        }
                    } else {
                        var act: ServiceMessageAction!
                        realmWrite { _ in
                            act = ServiceMessageAction.kickUser(.user(User.by(id: id)))
                        }
                        return act
                    }
                }
            default:
                break
            }
        }
        return nil
    }
    
    class func processMessage(_ json: JSON) -> Message? {
        if let user = json["user_id"].int >>> {User.by(id: $0)},
            let date = json["date"].int >>> {Date(timeIntervalSince1970: TimeInterval($0))},
            let id = json["id"].int {
            let message = Message.by(id: id)
            realmWrite { _ in
                message.user = user
                message.body = json["body"].string?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
                message.date = date
                message.randomID.value = json["random_id"].int
                message.read = json["read_state"].int?.bool ?? message.read
                message.geolocation = json["geo"] =>> processGeolocation
                message.attachments.removeAll()
                if let atts = json["attachments"].array {
                    for att in atts {
                        processMedia(att) >>> {message.attachments.append(RealmMedia.init(value: $0))}
                    }
                }
                message.forwardedMessages.removeAll()
                if let messes = json["fwd_messages"].array {
                    for mess in messes {
                        processGenericMessage(mess) >>> { message.forwardedMessages.append(RealmForwardedMessage(value: .genericMessage($0))) }
                    }
                }
                message.chatID.value = json["chat_id"].int
                message.action = prpocessServiceMessageAction(json)
                message.photoSURL = json["photo_200"].string
                message.out = json["out"].int?.bool ?? message.read
                
            }
            print(message.body)
            return message
        } else {
            return nil
        }
    }
    
    class func processGenericMessage(_ json: JSON) -> GenericMessage? {
        if let user = json["user_id"].int >>> {User.by(id: $0)},
            let date = json["date"].int >>> {Date(timeIntervalSince1970: TimeInterval($0))} {
            let message = GenericMessage()
            message.user = user
            message.body = json["body"].string?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
            message.date = date
            message.geolocation = json["geo"] =>> processGeolocation
            if let atts = json["attachments"].array {
                for att in atts {
                    processMedia(att) >>> {message.attachments.append(RealmMedia.init(value: $0))}
                }
            }
            if let messes = json["fwd_messages"].array {
                for mess in messes {
                    processGenericMessage(mess) >>> {message.forwardedMessages
                        .append(RealmForwardedMessage(value: .genericMessage($0))) }
                }
            }
            
            realmWrite { realm in
                realm.add(message)
            }
            print(message.body)
            return message
        }
        return nil
    }

    
    
    class func processNotificationSettings(_ json: JSON) -> ChatNotificationSettings? {
        if let sound = json["sound"].int,
            let date = json["disabled_until"].int {
            if date == -1 {
                return ChatNotificationSettings(sound: Bool.from(num: sound), disabledUntil: .never)
            } else {
                return ChatNotificationSettings(sound: Bool.from(num: sound), disabledUntil: .date(Date(timeIntervalSince1970: TimeInterval(date))))
            }
        } else {
            return nil
        }
    }
    
    class func processMultichat(_ json: JSON) -> Multichat? { // from .getChat
        if let id = json["id"].int {
            var chat: Multichat!
            realmWrite { _ in
                chat = Multichat.by(id: id)
                chat.admin = json["admin_id"].int >>> {User.by(id: $0)}
                chat.title = json["title"].string
                // TODO: let type = json["type"].string
                // TODO: type == "chat"
                if let uss = json["users"].array {
                    for user in uss {
                        if let invitedBy = user["invited_by"].int,
                            let us = processUser(json: user) {
                            add(item: MultiChatUser(us, invitedBy: User.by(id: invitedBy)), toList: chat.users)
                        }
                    }
                }
                chat.notificationSettings = RealmNotificatonSettings
                    .init(value: processNotificationSettings(json["push_settings"]))
                chat.image = RealmPhoto.by(chat.imageID, surl: json["photo_200"].string)
                
                var status: MultichatStatus = .active
                if let _ = json["kicked"].int {
                    status = .kicked
                } else if let _ = json["left"].int {
                    status = .left
                }
                chat.participationStatus = status
            }
            return chat
        }
        return nil
    }
    
    class func processDialog(_ json: JSON) -> Dialog? {
        let message = json["message"]
        if let id = message["chat_id"].int { // Multichat
            if let sMessage = processMessage(message) {
                var mChat: Multichat!
                var dialog: Dialog!
                realmWrite { _ in
                    mChat = Multichat.by(id: id)
                    mChat.admin = message["admin_id"].int >>> {User.by(id: $0)}
                    mChat.title = message["title"].string
                    mChat.notificationSettings = RealmNotificatonSettings
                        .init(value: processNotificationSettings(message["push_settings"]))
                    dialog = mChat
//                    dialog.date = sMessage.date
                    RealmDialog.by(dialog: dialog) <~ sMessage
                }
                //                print(dialog)
                return dialog
            }
        } else if let id = message["user_id"].int { // Chat
            if let sMessage = processMessage(json["message"]) {
                var chat: Chat!
                var dialog: Dialog!
                realmWrite { _ in
                    chat = Chat.by(user: User.by(id: id))
                    dialog = chat
//                    dialog.date = sMessage.date
                    RealmDialog.by(dialog: dialog) <~ sMessage
                }
                //                print(dialog)
                return dialog
            }
        }
        return nil
    }
}

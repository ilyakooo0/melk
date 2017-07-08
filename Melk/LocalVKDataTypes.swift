//
//  File.swift
//  golos
//
//  Created by Ilya Kos on 12/12/16.
//  Copyright © 2016 Ilya Kos. All rights reserved.
//

import UIKit
import RealmSwift
import Alamofire
import CoreLocation
import Nuke
import SwiftyVK


typealias Token = String
typealias UserID = Int
typealias MessageID = Int
typealias MultichatID = Int

class RealmPhoto: Object {
    
    convenience init(surl: String, id: String) {
        self.init()
        self.imageSURL = surl
        self.id = id
    }
    
    @objc dynamic var id: String = ""
    var imageURL: URL? {
        get {
            return imageSURL =>> {URL(string: $0)}
        }
        set {
            imageSURL = newValue?.absoluteString
        }
    }
    @objc dynamic var imageSURL: String? {
        didSet {
            if oldValue != imageSURL {
                localImageSURL = nil
            }
        }
    }
    @objc private dynamic var localImageSURL: String? {
        didSet {
            if oldValue != localImageSURL {
                imageCache = nil
            }
        }
    }
    private var imageCache: UIImage?
    
    convenience init(id: String, surl: String?) {
        self.init()
        self.id = id
        self.imageSURL = surl
    }
    
    class func by(_ id: String, surl: String?) -> RealmPhoto {
        do {
            let realm = try Realm()
            if let ob = realm.object(ofType: RealmPhoto.self, forPrimaryKey: id) {
                if realm.isInWriteTransaction {
                    surl =>> {ob.imageSURL = $0}
                } else {
                    try? realm.write {
                        surl =>> {ob.imageSURL = $0}
                    }
                }
                return ob
            } else {
                let ob = RealmPhoto(id: id, surl: surl)
                if realm.isInWriteTransaction {
                    realm.add(ob)
                } else {
                    try? realm.write {
                        realm.add(ob)
                    }
                }
                return ob
            }
        } catch {
            let ob = RealmPhoto(id: id, surl: surl)
            return ob
        }
    }
    
    override static func primaryKey() -> String? {
        return "id"
    }
    
    override static func ignoredProperties() -> [String] {
        return ["imageURL", "imageCache", "completions", "request"]
    }
    
    var completions: [((() -> ()), RealmPhotoToken)] = []
    var views: [(UIImageView?, RealmPhotoToken)] = []
    var request: DataRequest?
    
    @discardableResult func load(into view: UIImageView, completion: (() -> ())? = nil, error errorClosure: (() -> ())? = nil) -> RealmPhotoToken {
        
        let token = RealmPhotoToken()
        
        func getFromServer() {
            if request == nil {
                let surl = "\(id).png"
                if let url = imageURL {
                    print("getting from network")
                    request = Alamofire.request(url, method: .get).validate().responseData(queue: userQueue) { (responce) in
                        self.request = nil
                        switch responce.result {
                        case .success(let data):
                            UIImage(data: data) >>> {image in
                                write(cache: UIImagePNGRepresentation(image), withName: surl) {
                                    realmWrite({ (realm) in
                                        realm.object(ofType: RealmPhoto.self, forPrimaryKey: self.id)?.localImageSURL = surl
                                    })
                                }
                                self.imageCache = image
                                DispatchQueue.main.async {
                                    if token.isValid {
                                        self.views.map { if $0.1.isValid {$0.0?.image = image} }
                                        self.completions.map { if $0.1.isValid { $0.0() } }
                                        self.completions = []
                                    }
                                }
                            }
                        case .failure(let error):
                            errorClosure?()
                            // TODO: Error handling
                            break
                        }
                    }
                }
            }
        }
        
        if let surl = localImageSURL, // TODO: Should probrably get thing from server ???
            let url = url(forName: surl) {
            Nuke.loadImage(with: url, into: view) { [weak view] (response, fromMemory) in
                switch response {
                case .fulfilled(let image):
                    if token.isValid {
                        view?.image = image
                        completion?()
                    }
                case .rejected(let error): // TODO: Handle error?
                    completion >>> {self.completions.append(($0, token))}
                    self.views.append((view, token))
                    getFromServer()
                }
            }
        } else {
            completion >>> {self.completions.append(($0, token))}
            self.views.append((view, token))
            getFromServer()
        }
        
        return token
    }
    
    //    func image(_ completion: @escaping ((UIImage?) -> ())) {
    //        print(id)
    //        let surl = "\(id).png"
    //        if imageCache != nil {
    //            print("we have caching!")
    //        }
    //        imageCache = imageCache ?? (localImageSURL =>> getLocalImage) // TODO: imageCache always seems to be nil... ie always loading from disk for some reason
    //        if let sImage = imageCache {
    //            DispatchQueue.main.async { completion(sImage) }
    //        } else if let url = imageURL {
    //            print("getting from network")
    //            Alamofire.request(url, method: .get).validate().responseData(queue: userQueue) { (responce) in
    //                switch responce.result {
    //                case .success(let data):
    //                    UIImage(data: data) >>> {image in
    //                        write(cache: UIImagePNGRepresentation(image), withName: surl) {
    //                            DispatchQueue.main.async {
    //                                do {
    //                                    let realm  = try Realm()
    //                                    if !realm.isInWriteTransaction {
    //                                        try realm.write {
    //                                            self.localImageSURL = surl
    //                                        }
    //                                    } else {
    //                                        self.localImageSURL = surl
    //                                    }
    //                                } catch { }
    //                            }
    //                        }
    //                        self.imageCache = image
    //                        DispatchQueue.main.async {completion(image)}
    //                    }
    //                case .failure(let error):
    //                    // TODO: Error handling
    //                    break
    //                }
    //                }.resume()
    //        }
    //    }
}

public class RealmPhotoToken {
    public func cancel() {
        isValid = false
    }
    fileprivate var isValid = true
}


class User: Object {
    @objc dynamic var id: UserID = 0
    @objc dynamic var firstName: String?
    @objc dynamic var lastName: String?
    var deactivated: Deactivated? {
        get {
            return deactivatedStr =>> {Deactivated.init(rawValue: $0)}
        }
        set {
            deactivatedStr = newValue >>> {$0.rawValue}
        }
    }
    @objc private dynamic var deactivatedStr: String?
    
    @objc dynamic var about: String?
    @objc dynamic var birthday: Date?
    let blacklisted = RealmOptional<Bool>()
    let canSendFriendRequest = RealmOptional<Bool>()
    let canSendPrivateMessage = RealmOptional<Bool>()
    let mutualFriendCount = RealmOptional<Int>()
    // TODO: var connections:
    @objc dynamic var mobilePhone: String?
    @objc dynamic var homePhone: String?
    // TODO: var exports
    var friendStatus: FriendStatus? {
        get {
            return friendStatusInt.value =>> {FriendStatus(rawValue: $0)}
        }
        set {
            friendStatusInt.value = newValue >>> {$0.rawValue}
        }
    }
    private let friendStatusInt = RealmOptional<Int>()
    let online = RealmOptional<Bool>()
    @objc dynamic var avatar: RealmPhoto?
    var avatarID: String {
        return "user\(id)avatar"
    }
    @objc dynamic var photo: RealmPhoto?
    var photoID: String {
        return "user\(id)photo"
    }
    var site: URL? {
        get {
            return siteSURL =>> {URL.init(string: $0)}
        }
        set {
            siteSURL = newValue >>> {$0.absoluteString}
        }
    }
    @objc dynamic var siteSURL: String?
    @objc dynamic var status: String?
    @objc dynamic var lastSeen: Date?
    //    dynamic var lastUpdated: Date = Date()
    let friendCount = RealmOptional<Int>()
    
    convenience init(id: UserID, firstName: String, lastName: String) {
        self.init()
        self.id = id
        self.firstName = firstName
        self.lastName = lastName
        //        self.lastUpdated = Date()
    }
    class func by(id: UserID) -> User {
        let realm = try! Realm()
        if let us = realm.object(ofType: User.self, forPrimaryKey: id) {
            return us
        } else {
            let us = User()
            us.id = id
            if realm.isInWriteTransaction {
                realm.add(us)
            } else {
                try? realm.write {
                    realm.add(us)
                    
                }
            }
            return us
        }
    }
    
    func get(completion: ((User?) -> ())? = nil) {
        VK.API.Users.get([VK.Arg.userIDs: "\(id)"]).send(onSuccess: { (response) in
            if let json = response.array?.first {
                let us = VKData.processUser(json: json)
                completion?(us)
            } else {
                completion?(nil)
            }
        }, onError: { (error) in
            completion?(nil)
        })
    }
    
    
    override static func primaryKey() -> String? {
        return "id"
    }
    
    override static func ignoredProperties() -> [String] {
        return ["site", "photoID", "avatarID"]
    }
    //    func update() { lastUpdated = Date() }
    
    // MARK: Hashable override
    
    override var hashValue: Int {
        return id
    }
}

class Geolocation: Object {
    var geoCoordinates: CLLocation? {
        get {
            if let long = long.value, let latt = latt.value {
                return CLLocation(latitude: latt, longitude: long)
            }
            return nil
        }
        set {
            if let latt = newValue?.coordinate.latitude,
                let long = newValue?.coordinate.longitude {
                self.latt.value = latt
                self.long.value = long
            } else {
                self.long.value = nil
                self.latt.value = nil
            }
        }
    }
    private let latt = RealmOptional<Double>()
    private let long = RealmOptional<Double>()
    let id = RealmOptional<Int>()
    @objc dynamic var title: String?
    @objc dynamic var image: RealmPhoto?
    var imageID: String {
        return "geo_lat\(latt.value ?? 0)_long\(long.value ?? 0)image"
    }
    var city: String?
    var country: String?
    
    override static func ignoredProperties() -> [String] {
        return ["geoCoordinates", "imageID"]
    }
    convenience init(long: Double, latt: Double) {
        self.init()
        self.long.value = long
        self.latt.value = latt
    }
    
}

class GenericMessage: Object {
    @objc dynamic var date = Date() //
    @objc dynamic var body = "" //
    @objc dynamic var user: User?
    
    var outPhotos: [UIImage] = [] // TODO: ~
    
    @objc dynamic var geolocation: Geolocation?
    
    let attachments = List<RealmMedia>()
    let forwardedMessages = List<RealmForwardedMessage>()
    //let sentMessageId: MessageID?     I DONT KNOW WHY I PUT THIS HERE
    
    //    convenience init(body: String) {
    //        self.init()
    //        self.body = body
    //        self.out.value = true
    //    }
    //    convenience init(image: UIImage) {
    //        self.init()
    //        self.outPhotos.append(image)
    //    }
    override static func ignoredProperties() -> [String] {
        return ["outPhotos"]
    }
}

class Message: GenericMessage, Comparable, SortedArrayItem {
    @objc dynamic var id = 0
    let randomID = RealmOptional<MessageID>()
    @objc dynamic var read = false
    @objc dynamic var replied = false
    @objc dynamic var important = false
    @objc dynamic var deleted = false
    
    func equal(to message: Message) -> Bool {
        //        print("\(lhs.id.value) \(rhs.id.value) \(lhs.id.value == rhs.id.value)")
        if let a = self.randomID.value,
            let b = message.randomID.value {
            if a == b {
                return true
            }
        }
        return self.id == message.id
    }
    internal func greater(than message: Message) -> Bool {
        return self.id < message.id
    }
    
    static func ==(lhs: Message, rhs: Message) -> Bool {
        print("\(lhs.id) \(rhs.id) \(lhs.id == rhs.id)")
        return lhs.id == rhs.id
    }
    
    @objc dynamic var out = false
    
    // Multichat stuff
    
    @objc dynamic var photoSURL: String?
    let chatID = RealmOptional<MultichatID>()
    @objc private dynamic var serviceMessageString: String?
    private var serviceMessageUser: User?
    private let serviceMessage = RealmOptional<Int>()
    
    var action: ServiceMessageAction? {
        get {
            func getUser() -> ServiceMessageUser? {
                if let user = self.serviceMessageUser {
                    return .user(user)
                } else if let email = self.serviceMessageString {
                    return .email(email)
                } else {
                    return nil
                }
            }
            
            return serviceMessage.value =>> { service in
                switch service {
                case 0:
                    return .photoUpdate
                case 1:
                    return .photoRemove
                case 2:
                    return self.serviceMessageString >>> { .create($0) }
                case 3:
                    return self.serviceMessageString >>> { .titleUpdate($0) }
                case 4:
                    return getUser() >>> { .inviteUser($0) }
                case 5:
                    return getUser() >>> { .kickUser($0) }
                default:
                    return nil
                }
            }
        }
        set {
            func set(user: ServiceMessageUser) {
                switch user {
                case .user(let use):
                    self.serviceMessageUser = use
                case .email(let str):
                    self.serviceMessageString = str
                }
            }
            
            serviceMessageString = nil
            serviceMessageUser = nil
            serviceMessage.value = newValue >>> { new in
                switch new {
                case .photoUpdate:
                    return 0
                case .photoRemove:
                    return 1
                case .create(let str):
                    self.serviceMessageString = str
                    return 2
                case .titleUpdate(let str):
                    self.serviceMessageString = str
                    return 3
                case .inviteUser(let user):
                    set(user: user)
                    return 4
                case .kickUser(let user):
                    set(user: user)
                    return 5
                }
            }
        }
    }
    
    func get(completion: ((Message?) -> ())? = nil) {
        VK.API.Messages.getById([VK.Arg.messageIds: String(id)]).send(onSuccess: { (response) in
            if let json = response.array?.first {
                let mes = VKData.processMessage(response)
                completion?(mes)
            } else {
                completion?(nil)
            }
        }, onError: { (error) in
            completion?(nil)
        })
        // TODO: Implement propperly?
    }
    
    class func by(id: MessageID) -> Message {
        let realm = try! Realm()
        if let us = realm.object(ofType: Message.self, forPrimaryKey: id) {
            return us
        } else {
            let us = Message()
            us.id = id
            realmWrite({ (_) in
                realm.add(us)
            })
            return us
        }
    }
    
    override static func primaryKey() -> String? {
        return "id"
    }
}
//func ==(lhs: Message, rhs: Message) -> Bool {
//    print("\(lhs.id.value) \(rhs.id.value) \(lhs.id.value == rhs.id.value)")
//    return lhs.id.value == rhs.id.value
//}
func <(lhs: Message, rhs: Message) -> Bool {
    return lhs.id < rhs.id
}

enum forwardedMessage {
    case genericMessage(GenericMessage)
    case message(Message)
}

class RealmForwardedMessage: Object {
    var value: forwardedMessage? {
        get {
            if let gm = genericMessage {
                return .genericMessage(gm)
            } else if let m = message {
                return .message(m)
            } else {
                return nil
            }
        }
        set {
            realmWrite { _ in
                if let fm = newValue {
                    switch fm {
                    case .genericMessage(let gm):
                        genericMessage = gm
                        message = nil
                    case .message(let m):
                        genericMessage = nil
                        message = m
                    }
                } else {
                    message = nil
                    genericMessage = nil
                }
            }
        }
    }
    @objc private dynamic var genericMessage: GenericMessage?
    @objc private dynamic var message: Message?
    
    var id: MessageID? {
        if let m = message {
            return m.id
        } else {
            return nil
        }
    }
    
    convenience init(value: forwardedMessage) {
        self.init()
        self.value = value
    }
    
    override static func ignoredProperties() -> [String] {
        return ["value"]
    }
}

//struct Geolocation {
//    var coordinates: CLLocation
//    var title: String?
//    var imageURL: URL? {
//        get {
//            return imageSURL =>> {URL.init(string: $0)}
//        }
//        set {
//            imageSURL = newValue?.absoluteString
//        }
//    }
//    var imageSURL: String?
//    //    func image(completion: ((UIImage) -> ())) {
//    //        imageFunc =>> {$0(completion)}
//    //    }
//    var image: (@escaping ((UIImage) -> ()) -> ())?
//    var city: String?
//    var country: String?
//    init(coordinates: CLLocation, title: String?, imageSURL: String?, image: (@escaping ((UIImage) -> ()) -> ()), city: String?, country: String?) {
//        self.coordinates = coordinates
//        self.title = title
//        self.imageSURL = imageSURL
//        self.image = image
//        self.city = city
//        self.country = country
//    }
//}
typealias GeolocationID = Int

enum Deactivated: String {
    case banned = "banned"
    case deleted = "deleted"
    case normal = "normal"
}

enum FriendStatus: Int {
    case notFriends = 0
    case requestSent
    case requestRecieved
    case fiend
}

enum MessageReadState: Int {
    case read = 0
    case notRead
}
enum MessageSendState: Int {
    case received = 0
    case sent
}

enum MultichatNotificationSetting {
    case sound
    case disabled_until
}

enum ServiceMessageAction {
    case photoUpdate // 0
    case photoRemove // 1
    case create(String) // 2
    case titleUpdate(String) // 3
    case inviteUser(ServiceMessageUser) // 4
    case kickUser(ServiceMessageUser) // 5
}

enum ServiceMessageUser {
    case user(User)
    case email(String)
}

typealias MessageChunkID = String
class MessageChunk: Object { // message ids go down
    subscript(index: Int) -> Message {
        return messages[index]
    }
    
    @objc dynamic var id: MessageChunkID = ""
    
    fileprivate let messages = List<Message>()
    
    var firstMessage: Message? {
        return messages.first
    }
    
    var lastMessage: Message? {
        return messages.last
    }
    
    var firstID: MessageID? {
        return firstMessage?.id
    }
    
    var lastID: MessageID? {
        return lastMessage?.id
    }
    
    var count: Int {
        return messages.count
    }
    
    fileprivate func append(message: Message?) {
        message >>> {messages.append($0)}
    }
    
    override static func primaryKey() -> String? {
        return "id"
    }
    
    override static func ignoredProperties() -> [String] {
        return ["firstMessage", "lastMessage", "firstID", "lastID", "count"]
    }
}

func +=(lhs: MessageChunk, rhs: MessageChunk) {
    lhs.messages.append(objectsIn: rhs.messages)
}

/// Returns: true if added. false if was already in list
func <~(lhs: MessageChunk?, rhs: Message?) -> Bool {
    var out: Bool = false
    realmWrite { (_) in
        out = lhs?.messages <~ rhs
    }
    return out
}
/// Returns: Indexes of added items
func <-(lhs: MessageChunk?, rhs: [Message?]?) -> [Int] {
    var out: [Int] = []
    realmWrite { (_) in
        out = lhs?.messages <- rhs
    }
    return out
}
/// Returns: Indexes of added items
func <-(lhs: MessageChunk?, rhs: MessageChunk?) -> [Int] {
    var out: [Int] = []
    realmWrite { (_) in
        out = lhs?.messages <- rhs?.messages
    }
    return out
}

enum MessageEntry {
    case message(Message)
    case spacer
}

typealias MessagesID = Int
class Messages: Object {
    subscript(ind: Int) -> MessageEntry? {
        assert(ind >= 0, "index out of bounds")
        if ind >= count || ind < 0 {
            return nil
        }
        var index = ind
        var i = 0
        while messageChunks[i].count < index {
            index -= messageChunks[i].count + 1
            i += 1
        }
        if index == messageChunks[i].count {
            return .spacer
        } else {
            return .message(messageChunks[i][index])
        }
    }
    
    @objc dynamic var id: MessagesID = 0
    
    @objc fileprivate dynamic var lastChunkID = 0
    
    var endIndex: Int {
        return messageChunks.endIndex
    }
    
    var first: Message? {
        return messageChunks.first?.firstMessage
    }
    
    func count(upToChunk index: Int) -> Int {
        var n = 0
        for i in 0..<index {
            n += messageChunks[i].count + 1
        }
        return n
    }
    
    public var count: Int {
        var n = messageChunks.count - 1
        for chunk in messageChunks {
            n += chunk.count
        }
        return n
    }
    
    fileprivate let messageChunks = List<MessageChunk>()
    
    public var chunks: List<MessageChunk> {
        return messageChunks
    }
    
    fileprivate enum ChunkIndex {
        case inside(Int)
        case after(Int)
        case beforeFirst
    }
    
    fileprivate func createChunk(at index: Int = 0) -> MessageChunk {
        let chunk = MessageChunk()
        realmWrite { (realm) in
            chunk.id = "\(id)_\(lastChunkID)"
            lastChunkID  += 1
            realm.add(chunk)
            messageChunks.insert(chunk, at: index)
        }
        return chunk
    }
    
    /// Return nil if there are no chunks
    fileprivate func chunkIndex(of message: Message) -> ChunkIndex? {
        if messageChunks.count == 0 {
            return nil
        }
        if let first = messageChunks.first?.firstMessage {
            if first.greater(than: message) {
                return .beforeFirst
            }
        }
        for (i, chunk) in messageChunks.enumerated() {
            if let lastMessage = chunk.lastMessage { // It should never be nil since a chunk is never empty
                if !message.greater(than: lastMessage) { // [ ... | ()] [...] ...
                    if i == 0 {
                        return .inside(i)
                    } else {
                        if let firstMessage = chunk.firstMessage { // It should never be nil since a chunk is never empty
                            if message.greater(than: firstMessage) || message.equal(to: firstMessage) {
                                return .inside(i)
                            } else {
                                return .after(i-1)
                            }
                        }
                    }
                }
            }
        }
        return .after(endIndex-1)
    }
    
    
    override static func primaryKey() -> String? {
        return "id"
    }
    
    override static func ignoredProperties() -> [String] {
        return ["endIndex"]
    }
    
    class func by(id: MessagesID) -> Messages {
        let realm = try! Realm()
        if let us = realm.object(ofType: Messages.self, forPrimaryKey: id) {
            return us
        } else {
            let us = Messages()
            us.id = id
            realm.add(us)
            return us
        }
    }
    
    // MARK: Messages obesrver
    
    static let notificationName: Notification.Name = Notification.Name(rawValue: "MessagesWereModifiedNotificationName")
    
    enum Changes {
        case added
        case modified
        case deleted
    }
}



/// Returns: true if added. false if was already in list
func <~(lhs: Messages?, rhs: Message?) -> Bool {
    var out: Bool = false
    if let lhs = lhs,
        let rhs = rhs {
        realmWrite { (_) in
            if let index = lhs.chunkIndex(of: rhs) {
                switch index {
                case .after(let i):
                    lhs.messageChunks[i].append(message: rhs)
                    out = true
                case .inside(let i):
                    out = lhs.messageChunks[i] <~ rhs
                case .beforeFirst:
                    out = lhs.createChunk(at: 0) <~ rhs
                }
            } else {
                out = lhs.createChunk() <~ rhs
            }
        }
    }
    return out
}
/// Only accepts a list of SEQUENTIAL messages. Will silently break if not passed sequentially.
/// Returns: Indexes of added items
func <-(lhs: Messages?, rhs: [Message?]?) /*-> [Int]*/ {
    print(rhs)
    print(lhs)
    if let lhs = lhs,
        let rhs = rhs?.flatMap({$0}),
        let first = rhs.first,
        let last = rhs.last {
        
        var deleted: [Int] = []
        var modified: [Int] = []
        var added: [Int] = []
        if let startI = lhs.chunkIndex(of: first),
            let endI = lhs.chunkIndex(of: last) {
            var start: Int!
            var end: Int!
            print("\t", startI, endI)
            switch startI {
            case .inside(let i):
                start = i
            case .after(let i):
                start = i + 1
            case .beforeFirst:
                start = -1
            }
            switch endI {
            case .after(let i):
                end = i
            case .inside(let i):
                end = i
            case .beforeFirst:
                end = -1
            }
            
            if start < end {
                print(start, end)
                start = max(start, 0)
                var spacerIndexes = (start+1...end).map({lhs.count(upToChunk: $0) - 1})
                //                deleted += spacerIndexes
                let count = lhs.count(upToChunk: start)
                var dIndex = 0
                for i in 0..<spacerIndexes.count {
                    spacerIndexes[i] -= dIndex
                    deleted.append(spacerIndexes[i])
                    spacerIndexes[i] -= count
                    dIndex += 1
                }
                var addedMs: [Int]!
                realmWriteWithCompletion { realm, completion in
                    for x in start+1...end {
                        print(lhs.chunks.count, x)
                        lhs.chunks[start] += lhs.chunks[start+1]
                        realm.delete(lhs.chunks[start+1])
                        //                        lhs.chunks.remove(objectAtIndex: start+1)
                    }
                    let chunk = lhs.chunks[start]
                    addedMs = chunk <- rhs
                    
                    addedMs.map {$0 + count}
                    added += addedMs
                    
                    completion {
                        print("after notification", lhs.chunks)
                        NotificationCenter.default.post(name: Messages.notificationName,
                                                        object: lhs.id,
                                                        userInfo: [Messages.Changes.added: added,
                                                                   Messages.Changes.modified: modified,
                                                                   Messages.Changes.deleted: deleted])
                    }
                }
            } else { // within one
                assert(start == end, "start index is larger than end index!")
                realmWriteWithCompletion { _, completion in
                    if start == -1 {
                        added += lhs.createChunk(at: 0) <- rhs
                        added.append(0) // IDK     o[]o[]o     []o[]o
                    } else {
                        added += (lhs.messageChunks[start] <- rhs).map {$0 + lhs.count(upToChunk: start)}
                    }
                    completion {
                        NotificationCenter.default.post(name: Messages.notificationName,
                                                        object: lhs.id,
                                                        userInfo: [Messages.Changes.added: added,
                                                                   Messages.Changes.modified: modified,
                                                                   Messages.Changes.deleted: deleted])
                    }
                }
            }
        } else { // empty
            realmWriteWithCompletion { _, completion in
                added += lhs.createChunk() <- rhs
                completion {
                    NotificationCenter.default.post(name: Messages.notificationName,
                                                    object: lhs.id,
                                                    userInfo: [Messages.Changes.added: added,
                                                               Messages.Changes.modified: modified,
                                                               Messages.Changes.deleted: deleted])
                }
            }
        }
        print(lhs)
        print(added)
        print(deleted)
    }
}

enum Media {
    case photo(Photo)
    case video(Video)
    case audio(Audio)
    case doc(Document)
    case wall(WallPost)
    case wallReply(WallPostReply)
    case sticker(Sticker)
    case link(Link)
    case gift(Gift)
    case market(Market)
    case marketAlbum(MarketAlbum)
    case graffiti(Document)
    case note(Note)
    case poll(Poll)
    case album(PhotoAlbum)
    var realm: RealmMedia {
        return RealmMedia(value: self)
    }
}

class RealmMedia: Object {
    @objc private dynamic var photo: Photo?
    @objc private dynamic var video: Video?
    @objc private dynamic var audio: Audio?
    @objc private dynamic var doc: Document?
    @objc private dynamic var wall: WallPost?
    @objc private dynamic var wallReply: WallPostReply?
    @objc private dynamic var sticker: Sticker?
    @objc private dynamic var link: Link?
    @objc private dynamic var gift: Gift?
    @objc private dynamic var market: Market?
    @objc private dynamic var marketAlbum: MarketAlbum?
    @objc private dynamic var graffiti: Document?
    @objc private dynamic var note: Note?
    @objc private dynamic var poll: Poll?
    @objc private dynamic var album: PhotoAlbum?
    
    var value: Media? {
        get {
            if let sureThing = self.photo { return .photo(sureThing) }
            if let sureThing = self.video { return .video(sureThing) }
            if let sureThing = self.audio { return .audio(sureThing) }
            if let sureThing = self.doc { return .doc(sureThing) }
            if let sureThing = self.wall { return .wall(sureThing) }
            if let sureThing = self.wallReply { return .wallReply(sureThing) }
            if let sureThing = self.sticker { return .sticker(sureThing) }
            if let sureThing = self.link { return .link(sureThing) }
            if let sureThing = self.gift { return .gift(sureThing) }
            if let sureThing = self.market { return .market(sureThing) }
            if let sureThing = self.marketAlbum { return .marketAlbum(sureThing) }
            if let sureThing = self.graffiti { return .graffiti(sureThing) }
            if let sureThing = self.note { return .note(sureThing) }
            if let sureThing = self.poll { return .poll(sureThing) }
            if let sureThing = self.album { return .album(sureThing) }
            return nil
        }
        set {
            
            photo = nil
            video = nil
            audio = nil
            doc = nil
            wall = nil
            wallReply = nil
            sticker = nil
            link = nil
            gift = nil
            market = nil
            marketAlbum = nil
            graffiti = nil
            note = nil
            poll = nil
            album = nil
            
            if let val = newValue {
                switch val {
                case .photo(let foo): photo = foo
                case .video(let foo): video = foo
                case .audio(let foo): audio = foo
                case .doc(let foo): doc = foo
                case .wall(let foo): wall = foo
                case .wallReply(let foo): wallReply = foo
                case .sticker(let foo): sticker = foo
                case .link(let foo): link = foo
                case .gift(let foo): gift = foo
                case .market(let foo): market = foo
                case .marketAlbum(let foo): marketAlbum = foo
                case .graffiti(let foo): graffiti = foo
                case .note(let foo): note = foo
                case .poll(let foo): poll = foo
                case .album(let foo): album = foo
                }
            }
        }
    }
    convenience init(value: Media) {
        self.init()
        self.value = value
    }
}

class Poll: Object {
    @objc dynamic var id: PollID = 0
    @objc dynamic var owner: User?
    @objc dynamic var date: Date?
    @objc dynamic var question: String?
    let votes = RealmOptional<Int>()
    let answerID = RealmOptional<PollAnswerID>()
    let answers = List<PollAnswer>()
    convenience init(id: PollID, owner: User, date: Date, question: String, votes: Int) {
        self.init()
        self.id = id
        self.owner = owner
        self.date = date
        self.question = question
        self.votes.value = votes
        //        self.answerID.value = answerID
    }
    class func by(id: PollID) -> Poll {
        let realm = try! Realm()
        if let us = realm.object(ofType: Poll.self, forPrimaryKey: id) {
            return us
        } else {
            let us = Poll()
            us.id = id
            realm.add(us)
            return us
        }
    }
    
    override class func primaryKey() -> String? {
        return "id"
    }
}
typealias PollID = Int

class PollAnswer: Object {
    @objc dynamic var id: PollAnswerID = 0
    @objc dynamic var body: String = ""
    @objc dynamic var votes: Int = 0
    @objc dynamic var rating: Int = 0
    
    convenience init(id: PollAnswerID, body: String, votes: Int, rating: Int) {
        self.init()
        self.id = id
        self.body = body
        self.votes = votes
        self.rating = rating
    }
}
typealias PollAnswerID = Int

class Note: Object {
    @objc dynamic var id: NoteID = 0
    @objc dynamic var owner: User?
    @objc dynamic var title: String?
    @objc dynamic var body: String?
    @objc dynamic var date: Date?
    var url: URL? {
        get {
            return surl =>> {URL(string: $0)}
        }
        set {
            surl = newValue >>> {$0.absoluteString}
        }
    }
    @objc dynamic var surl: String?
    let commentCount = RealmOptional<Int>()
    convenience init(id: NoteID, owner: User, title: String, body: String, date: Date, url: URL, commentCount: Int) {
        self.init()
        self.id = id
        self.owner = owner
        self.title = title
        self.body = body
        self.date = date
        self.url = url
        self.commentCount.value = commentCount
    }
    class func by(id: NoteID) -> Note {
        let realm = try! Realm()
        if let us = realm.object(ofType: Note.self, forPrimaryKey: id) {
            return us
        } else {
            let us = Note()
            us.id = id
            realm.add(us)
            return us
        }
    }
    override class func ignoredProperties() -> [String] {
        return ["url"]
    }
    
    override class func primaryKey() -> String? {
        return "id"
    }
}
typealias NoteID = Int

typealias GraffitiID = Int
class Graffiti: Document {
} // Use document.image ?

class Photo: Object {
    @objc dynamic var id: PhotoID = 0
    @objc dynamic var owner: User?
    @objc dynamic var date: Date?
    @objc dynamic var thumbnail: RealmPhoto?
    var thumbnailID: String {
        return "photo\(id)thumbnail"
    }
    @objc dynamic var image: RealmPhoto?
    var imageID: String {
        return "photo\(id)image"
    }
    let width = RealmOptional<Int>()
    let height = RealmOptional<Int>()
    @objc dynamic var accessKey: Key?
    
    convenience init(id: PhotoID, owner: User, date: Date){
        self.init()
        self.id = id
        self.owner = owner
        self.date = date
    }
    
    class func by(id: PhotoID) -> Photo {
        let realm = try! Realm()
        if let us = realm.object(ofType: Photo.self, forPrimaryKey: id) {
            return us
        } else {
            let us = Photo()
            us.id = id
            realm.add(us)
            return us
        }
    }
    
    func get(completion: ((Photo?) -> ())? = nil) {
        if let ownerID = owner?.id {
            var ph = "\(ownerID)_\(id)"
            if let key = accessKey {
                ph.append("_\(key)")
            }
            VK.API.Photos.getById([VK.Arg.photos: ph]).send(onSuccess: { (response) in
                if let json = response.array?.first {
                    let photo = VKData.processPhoto(json)
                    completion?(photo)
                } else {
                    completion?(nil)
                }
            }, onError: { (error) in
                completion?(nil)
            })
        } else {
            completion?(nil)
        }
    }
    
    override class func primaryKey() -> String? {
        return "id"
    }
    
    override static func ignoredProperties() -> [String] {
        return ["thumbnailID", "imageID"]
    }
}

class PhotoAlbum: Object {
    @objc dynamic var id: PhotoAlbumID = 0
    @objc dynamic var thumb: Photo?
    @objc dynamic var owner: User?
    @objc dynamic var title: String?
    @objc dynamic var albumDescription: String?
    @objc dynamic var dateCreated: Date?
    @objc dynamic var dateUpdated: Date?
    let count = RealmOptional<Int>()
    let photos = List<Photo>()
    convenience init(id: PhotoAlbumID) {
        self.init()
        self.id = id
    }
    
    override class func primaryKey() -> String? {
        return "id"
    }
    class func by(id: PhotoAlbumID) -> PhotoAlbum {
        let realm = try! Realm()
        if let us = realm.object(ofType: PhotoAlbum.self, forPrimaryKey: id) {
            return us
        } else {
            let us = PhotoAlbum()
            us.id = id
            realm.add(us)
            return us
        }
    }
    
    
    //    init(id: PhotoAlbumID, thumbID: PhotoID, ownerID: UserID, title: String, dateCreated: Date, dateUpdated: Date, count: Int) {
    //        self.id = id
    //        self.thumbID = thumbID
    //        self.ownerID = ownerID
    //        self.title = title
    //        self.dateCreated = dateCreated
    //        self.dateUpdated = dateUpdated
    //        self.count = count
    //    }
    
}
typealias PhotoID = Int
typealias PhotoAlbumID = Int
typealias Key = String

class WallPost: Object {
    @objc dynamic var id: Int = 0
    @objc dynamic var owner: User?
    @objc dynamic var creator: User?
    @objc dynamic var date: Date?
    @objc dynamic var body: String?
    let commentCount = RealmOptional<Int>()
    let canPostComment = RealmOptional<Bool>()
    let likeCount = RealmOptional<Int>()
    @objc dynamic var liked: Bool = false
    let canLike = RealmOptional<Bool>()
    let repostCount = RealmOptional<Int>()
    let canDelete = RealmOptional<Bool>()
    let didRepost = RealmOptional<Bool>()
    // Optional ⬇
    let attachments = List<RealmMedia>()
    @objc dynamic var geo: Geolocation?
    // TODO: let postSource
    @objc dynamic var signed: User?
    @objc dynamic var ownerOfCopy: User?
    @objc dynamic var original: WallPost?
    let historyOfCopy = List<WallPost>()
    let canPin = RealmOptional<Bool>()
    let canEdit = RealmOptional<Bool>()
    let isPinned = RealmOptional<Bool>()
    
    //    convenience init(id: WallPostID, ownerID: UserID, creatorID: UserID, date: Date, body: String, commentCount: Int, canPostComment: Bool, likeCount: Int, liked: Bool, canLike: Bool, repostCount: Int, didRepost: Bool, attachments: [Media], geo: Geolocation?, signed: UserID?, copyID: WallPostID?, canDelete: Bool, canPin: Bool?, canEdit: Bool?, isPinned: Bool?, copyHistory: [WallPostID], copyOwnerID: UserID?) {
    //        self.id = id
    //        self.ownerID = ownerID
    //        self.creatorID = creatorID
    //        self.date = date
    //        self.body = body
    //        self.commentCount = commentCount
    //        self.canPostComment = canPostComment
    //        self.likeCount = likeCount
    //        self.liked = liked
    //        self.canLike = canLike
    //        self.repostCount = repostCount
    //        self.didRepost = didRepost
    //        self.attachments = attachments
    //        self.geo = geo
    //        self.signed = signed
    //        self.copyID = copyID
    //        self.canDelete = canDelete
    //        self.canPin = canPin
    //        self.canEdit = canEdit
    //        self.isPinned = isPinned
    //        self.copyHistory = copyHistory
    //        self.copyOwnerID = copyOwnerID
    //    }
    
    func get(completion: ((WallPost?) -> ())? = nil) {
        if let ownerID = owner?.id {
            var ph = "\(ownerID)_\(id)"
            //            if let key = accessKey {
            //                ph.append("_\(key)")
            //            }
            VK.API.Wall.getById([VK.Arg.posts: ph]).send(onSuccess: { (response) in
                if let json = response.array?.first {
                    let photo = VKData.processWallPost(json)
                    completion?(photo)
                } else {
                    completion?(nil)
                }
            }, onError: { (error) in
                completion?(nil)
            })
        } else {
            completion?(nil)
        }
    }
    
    
    override class func primaryKey() -> String? {
        return "id"
    }
    
    class func by(id: UserID) -> WallPost {
        let realm = try! Realm()
        if let us = realm.object(ofType: WallPost.self, forPrimaryKey: id) {
            return us
        } else {
            let us = WallPost()
            us.id = id
            realm.add(us)
            return us
        }
    }
    
}
typealias WallPostID = Int

class WallPostReply: Object {
    @objc dynamic var id: WallPostReplyID = 0
    @objc dynamic var author: User?
    @objc dynamic var wallPost: WallPost?
    @objc dynamic var wallOwner: User?
    @objc dynamic var date: Date?
    @objc dynamic var body: String?
    let likeCount = RealmOptional<Int>()
    let didLike = RealmOptional<Bool>()
    let canLike = RealmOptional<Bool>()
    @objc dynamic var inReplyToUser: User?
    let attachments = List<RealmMedia>()
    @objc dynamic var inReplyToComment: WallPostReply?
    class func by(id: WallPostReplyID) -> WallPostReply {
        let realm = try! Realm()
        if let us = realm.object(ofType: WallPostReply.self, forPrimaryKey: id) {
            return us
        } else {
            let us = WallPostReply()
            us.id = id
            realm.add(us)
            return us
        }
    }
    
    override class func primaryKey() -> String? {
        return "id"
    }
}
typealias WallPostReplyID = Int

class Sticker: Object {
    @objc dynamic var id: StickerID = 0
    @objc dynamic var packID: StickerPackID = 0
    @objc dynamic var image: RealmPhoto?
    var imageID: String {
        return "sticker\(id)image"
    }
    let width = RealmOptional<Int>()
    let height = RealmOptional<Int>()
    
    convenience init(id: StickerID, packID: StickerPackID, width: Int, height: Int) {
        self.init()
        self.id = id
        self.packID = packID
        self.width.value = width
        self.height.value = height
    }
    class func by(id: StickerID) -> Sticker {
        let realm = try! Realm()
        if let us = realm.object(ofType: Sticker.self, forPrimaryKey: id) {
            return us
        } else {
            let us = Sticker()
            us.id = id
            realm.add(us)
            return us
        }
    }
    
    override class func primaryKey() -> String? {
        return "id"
    }
    override static func ignoredProperties() -> [String] {
        return ["imageID"]
    }
}
typealias StickerID = Int
typealias StickerPackID = Int

class Gift: Object {
    @objc dynamic var id: GiftID = 0
    @objc dynamic var image: RealmPhoto?
    var imageID: String {
        return "gift\(id)image"
    }
    convenience init(id: GiftID, surl: String) {
        self.init()
        self.id = id
        self.image = RealmPhoto.by(imageID, surl: surl)
    }
    class func by(id: GiftID) -> Gift {
        let realm = try! Realm()
        if let us = realm.object(ofType: Gift.self, forPrimaryKey: id) {
            return us
        } else {
            let us = Gift()
            us.id = id
            realm.add(us)
            return us
        }
    }
    
    override class func primaryKey() -> String? {
        return "id"
    }
    override static func ignoredProperties() -> [String] {
        return ["imageID"]
    }
}
typealias GiftID = Int

class Link: Object {
    var url: URL? {
        get {
            return surl =>> {URL(string: $0)}
        }
    }
    @objc dynamic var surl: String = ""
    @objc dynamic var title: String?
    @objc dynamic var caption: String?
    @objc dynamic var linkDescription: String?
    @objc dynamic var photo: Photo?
    let isExternal = RealmOptional<Bool>()
    //var product: Market?
    var rating: Rating? {
        get {
            if let stars = ratingStars.value,
                let count = ratingReviewCount.value {
                return Rating(stars: stars, reviewCount: count)
            }
            return nil
        }
        set {
            ratingStars.value = newValue?.stars
            ratingReviewCount.value = newValue?.reviewCount
        }
    }
    private let ratingStars = RealmOptional<Int>()
    private let ratingReviewCount = RealmOptional<Int>()
    //let application: Application?
    var button: LinkButton? {
        get {
            if let title = buttonTitle,
                let url = buttonURL {
                return LinkButton(title: title, url: url)
            }
            return nil
        }
        set {
            buttonURL = newValue?.url
            buttonTitle = newValue?.title
        }
    }
    @objc private dynamic var buttonTitle: String?
    private var buttonURL: URL? {
        get {
            return buttonSURL =>> {URL(string: $0)}
        }
        set {
            buttonSURL = newValue?.absoluteString
        }
    }
    private var buttonSURL: String?
    //let previewURL: URL
    
    class func by(surl: String) -> Link {
        let realm = try! Realm()
        if let us = realm.object(ofType: Link.self, forPrimaryKey: surl) {
            return us
        } else {
            let us = Link()
            us.surl = surl
            realm.add(us)
            return us
        }
    }
    override class func primaryKey() -> String? {
        return "surl"
    }
    override static func ignoredProperties() -> [String] {
        return ["url", "rating", "button", "buttonURL"]
    }
}


struct Rating {
    let stars: Int
    let reviewCount: Int
}

struct LinkButton {
    let title: String
    let url: URL
}

class Market: Object {
    @objc dynamic var id: MarketID = 0
    @objc dynamic var owner: User?
    @objc dynamic var title: String?
    @objc dynamic var marketDescription: String?
    let amount = RealmOptional<Int>()
    let price = RealmOptional<Int>()
    let currencyID = RealmOptional<CurrencyID>()
    @objc dynamic var currencyName: String?
    @objc dynamic var priceString: String?
    let categoryID = RealmOptional<MarketCategoryID>()
    @objc dynamic var categoryName: String?
    let sectionID = RealmOptional<MarketSectionID>()
    @objc dynamic var sectionName: String?
    @objc dynamic var image: RealmPhoto?
    var imageID: String {
        return "market\(id)image"
    }
    @objc dynamic var creationDate: Date?
    var availability: MarketAvailability? {
        set {
            availabilityInt.value = newValue?.rawValue
        }
        get {
            return availabilityInt.value =>> {MarketAvailability(rawValue: $0)}
        }
    }
    private let availabilityInt = RealmOptional<Int>()
    let photos = List<Photo>()
    let canComment = RealmOptional<Bool>()
    let canRepost = RealmOptional<Bool>()
    let likesCount = RealmOptional<Int>()
    let liked = RealmOptional<Bool>()
    
    class func by(id: MarketID) -> Market {
        let realm = try! Realm()
        if let us = realm.object(ofType: Market.self, forPrimaryKey: id) {
            return us
        } else {
            let us = Market()
            us.id = id
            realm.add(us)
            return us
        }
    }
    
    override class func primaryKey() -> String? {
        return "id"
    }
    override static func ignoredProperties() -> [String] {
        return ["imageID"]
    }
}
typealias CurrencyID = Int
typealias MarketCategoryID = Int
typealias MarketSectionID = Int
enum MarketAvailability: Int {
    case availability = 0
    case deleted
    case notAvailability
}
typealias MarketID = Int

class MarketAlbum: Object {
    @objc dynamic var id: MarketAlbumID = 0
    @objc dynamic var owner: User?
    @objc dynamic var title: String?
    @objc dynamic var photo: Photo?
    let count = RealmOptional<Int>()
    @objc dynamic var updateTime: Date?
    override class func primaryKey() -> String? {
        return "id"
    }
}
typealias MarketAlbumID = Int

class Video: Object {
    @objc dynamic var id: VideoID = 0
    @objc dynamic var owner: User?
    @objc dynamic var title: String?
    @objc dynamic var videoDescription: String?
    let duration = RealmOptional<TimeInterval>()
    @objc dynamic var thumbnail: RealmPhoto?
    var thumbnailID: String {
        return "video\(id)thumbnail"
    }
    var player: URL? {
        get {
            return playerSURL =>> {URL(string: $0)}
        }
        set {
            playerSURL = newValue?.absoluteString
        }
    }
    @objc dynamic var playerSURL: String?
    @objc dynamic var accessKey: String?
    @objc dynamic var isProcessing: Bool = false
    @objc dynamic var isLive: Bool = false
    convenience init(id: VideoID, owner: User, title: String, description: String, duration: TimeInterval) {
        self.init()
        self.id = id
        self.owner = owner
        self.title = title
        self.videoDescription = description
        self.duration.value = duration
    }
    
    class func by(id: VideoID) -> Video {
        let realm = try! Realm()
        if let us = realm.object(ofType: Video.self, forPrimaryKey: id) {
            return us
        } else {
            let us = Video()
            us.id = id
            realm.add(us)
            return us
        }
    }
    
    func get(completion: ((Video?) -> ())? = nil) {
        if let peerID = owner?.id {
            var vi = "\(peerID)_\(id)"
            if let key = accessKey {
                vi.append("_\(key)")
            }
            VK.API.Video.get([VK.Arg.videos: vi]).send(onSuccess: { (response) in
                if let json = response["items"].array?.first {
                    let video = VKData.processVideo(json)
                    completion?(video)
                } else {
                    completion?(nil)
                }
            }, onError: { (error) in
                completion?(nil)
            })
        } else {
            completion?(nil)
        }
    }
    
    override class func primaryKey() -> String? {
        return "id"
    }
    override static func ignoredProperties() -> [String] {
        return ["player", "thumbnailID"]
    }
}
typealias VideoID = Int

class Audio: Object {
    @objc dynamic var id: AudioID = 0
    @objc dynamic var owner: User?
    @objc dynamic var artist: String?
    @objc dynamic var title: String?
    let duration = RealmOptional<TimeInterval>()
    var url: URL? {
        get {
            return surl =>> {URL(string: $0)}
        }
        set {
            surl = newValue?.absoluteString
        }
    }
    @objc dynamic var surl: String?
    
    convenience init(id: AudioID) {
        self.init()
        self.id = id
    }
    class func by(id: AudioID) -> Audio {
        let realm = try! Realm()
        if let us = realm.object(ofType: Audio.self, forPrimaryKey: id) {
            return us
        } else {
            let us = Audio()
            us.id = id
            realm.add(us)
            return us
        }
    }
    
    override class func primaryKey() -> String? {
        return "id"
    }
    override static func ignoredProperties() -> [String] {
        return ["url"]
    }
}
typealias AudioID = Int
typealias LyricID = Int
typealias AudioAlbumID = Int
typealias GenreID = Int

class Document: Object {
    @objc dynamic var id: DocumentID = 0
    @objc dynamic var owner: User?
    @objc dynamic var title: String?
    let size = RealmOptional<Int>()
    @objc dynamic var fileExtension: String?
    var url: URL? {
        get {
            return surl =>> {URL(string: $0)}
        }
        set {
            surl = newValue?.absoluteString
        }
    }
    @objc dynamic var surl: String?
    @objc dynamic var image: RealmPhoto?
    var imageID: String {
        return "doc\(id)image"
    }
    var type: DocumentType? {
        get {
            return typeInt.value =>> {DocumentType(rawValue: $0)}
        }
        set {
            typeInt.value = newValue?.rawValue
        }
    }
    private let typeInt = RealmOptional<Int>()
    convenience init(id: DocumentID, owner: User, title: String, size: Int, ext: String, url: URL, type: DocumentType) {
        self.init()
        self.id = id
        self.owner = owner
        self.title = title
        self.size.value = size
        self.fileExtension = ext
        self.url = url
        self.type = type
    }
    class func by(id: DocumentID) -> Document {
        let realm = try! Realm()
        if let us = realm.object(ofType: Document.self, forPrimaryKey: id) {
            return us
        } else {
            let us = Document()
            us.id = id
            realm.add(us)
            return us
        }
    }
    
    func get(completion: ((Document?) -> ())? = nil) {
        if let ownerID = owner?.id {
            var doc = "\(ownerID)_\(id)"
            //            if let key = accessKey {
            //                doc.append("_\(key)")
            //            }
            VK.API.Docs.getById([VK.Arg.docs: doc]).send(onSuccess: { response in
                if let json = response.array?.first {
                    let document = VKData.processDocument(json)
                    completion?(document)
                } else {
                    completion?(nil)
                }
            }, onError: { (error) in
                completion?(nil)
            })
        } else {
            completion?(nil)
        }
    }
    
    override class func primaryKey() -> String? {
        return "id"
    }
    override static func ignoredProperties() -> [String] {
        return ["url", "imageID"]
    }
}
typealias DocumentID = Int
enum DocumentType: Int {
    case text = 1
    case archive
    case gif
    case image
    case audio
    case video
    case eBook
    case unknown
}

protocol Dialog {
    var firstMessage: Message? { get }
    var important: Bool { get set }
    var name: String? { get }
    func loadImage(into view: UIImageView, completion: (() -> ())?) -> RealmPhotoToken?
    var messages: Messages? { get }
    var id: Int { get }
    var lastReadMessageID: Int { get set }
    var count: RealmOptional<Int> { get }
    var notificationSettings: RealmNotificatonSettings? { get set }
    var peerID: Int { get }
}

func dialog(for id: DialogID) -> Dialog {
    if id > multichatchatId { // multichat
        let chat = Multichat.by(id: id - multichatchatId)
        return chat
        
        //} else if id < 0 { // Pablic
        
    } else { // Normal user
        let chat = Chat.by(user: User.by(id: id))
        return chat
    }
}

// For name conflicts
func dialogFor(_ id: DialogID) -> Dialog {
    return dialog(for: id)
}

class RealmDialog: Object, Comparable {
    
    // TODO: Remove these two
    @objc dynamic var dateLastSent: Date?
    /// Number of times a message has been sent in the dateLastSent second
    @objc dynamic var dateSentNumber = 0
    
    var value: Dialog? {
        get {
            return dialog(for: id)
        }
    }
    
    var peerID: Int? {
        return value?.peerID
    }
    
    @objc dynamic var id: DialogID = 0
    
    @objc dynamic var date: Date?
    
    class func by(dialog: Dialog) -> RealmDialog {
        return RealmDialog.by(peerID: dialog.peerID)
    }
    
    class func by(peerID: Int) -> RealmDialog {
        if let dialog = (try? Realm())?.object(ofType: RealmDialog.self, forPrimaryKey: peerID) {
            return dialog
        } else {
            let dialog = RealmDialog()
            dialog.id = peerID
            realmWrite({ (realm) in
                realm.add(dialog)
            })
            return dialog
        }
    }
    
    override class func primaryKey() -> String? {
        return "id"
    }
    override static func ignoredProperties() -> [String] {
        return ["value", "peerID"]
    }
}
func ==(lhs: RealmDialog, rhs: RealmDialog) -> Bool {
    return lhs.date == rhs.date
}
func <(lhs: RealmDialog, rhs: RealmDialog) -> Bool {
    if let l = lhs.date,
        let r = rhs.date {
        return l < r
    } else {
        return false
    }
}
typealias DialogID = Int

//func ==(lhs: Dialog, rhs: Dialog) -> Bool {
//    return lhs.date == rhs.date
//}
//func <(lhs: Dialog, rhs: Dialog) -> Bool {
//    return lhs.date < rhs.date
//}

class RealmNotificatonSettings: Object {
    var value: ChatNotificationSettings? {
        get {
            if let sound = notiSound.value,
                let never = notiDateNever.value {
                if never {
                    return ChatNotificationSettings(sound: sound, disabledUntil: .never)
                } else {
                    return notiDate >>> {ChatNotificationSettings(sound: sound, disabledUntil: .date($0))}
                }
            }
            return nil
        }
        set {
            notiSound.value = newValue?.sound
            if let newV = newValue {
                switch newV.disabledUntil {
                case .date(let date):
                    notiDate = date
                    notiDateNever.value = false
                case .never:
                    notiDateNever.value = true
                    notiDate = nil
                }
            }
        }
    }
    private let notiSound = RealmOptional<Bool>()
    private let notiDateNever = RealmOptional<Bool>()
    @objc private dynamic var notiDate: Date?
    convenience init(value: ChatNotificationSettings?) {
        self.init()
        self.value = value
    }
}

class Multichat: Object {
    @objc dynamic var id: MultichatID = 0
    @objc dynamic var admin: User?
    var timers: [UserID: Timer] = [:]
    var typingUsers: Set<User> = []
    @objc dynamic var title: String?
    let users = List<MultiChatUser>()
    @objc dynamic var messages: Messages?
    //    let messages = List<Message>()
    @objc dynamic var lastReadMessageID = 0
    @objc dynamic var important = false
    @objc dynamic var answered = false
    @objc dynamic var date = Date()
    let count = RealmOptional<Int>()
    @objc dynamic var image: RealmPhoto?
    var imageID: String {
        return "mchat\(id)image"
    }
    let attachments = List<RealmMedia>()
    
    @objc dynamic var notificationSettings: RealmNotificatonSettings?
    
    var participationStatus: MultichatStatus? {
        get {
            return participationStatusInt.value =>> {MultichatStatus(rawValue: $0)}
        }
        set {
            participationStatusInt.value = newValue?.rawValue
        }
    }
    private let participationStatusInt = RealmOptional<Int>()
    
    //    convenience init(id: MultichatID, adminID: UserID, title: String, userIDs: [(user: UserID, invitedBy: UserID)]?, notificationSettings: MultichatNotificationSettings?, participationStatus: MultichatStatus?) {
    //        self.id = id
    //        self.adminID = adminID
    //        self.title = title
    //        self.userIDs = userIDs
    //        self.notificationSetting = notificationSettings
    //        self.participationStatus = participationStatus
    //    }
    class func by(id: MultichatID) -> Multichat {
        let realm = try! Realm()
        if let us = realm.object(ofType: Multichat.self, forPrimaryKey: id) {
            return us
        } else {
            VkServices.getMultichat(for: id)
            let us = Multichat()
            realmWrite { realm in
                us.id = id
                us.messages = Messages.by(id: us.peerID)
                realm.add(us)
            }
            return us
        }
    }
    
    override class func primaryKey() -> String? {
        return "id"
    }
    override static func ignoredProperties() -> [String] {
        return ["imageID", "typingUsers", "timers"]
    }
}

extension Multichat: Dialog {
    var firstMessage: Message? {
        return messages?.first
    }
    
    var name: String? {
        return title
    }
    
    func loadImage(into view: UIImageView, completion: (() -> ())? = nil) -> RealmPhotoToken? {
        return image?.load(into: view, completion: completion)
    }
    //    func image(completion: @escaping ((UIImage?) -> ())) {
    //        if let im = image?.image {
    //            im(completion)
    //        } else {
    //            completion(nil)
    //        }
    //    }
    
    var peerID: Int {
        return id + multichatchatId
    }
}

class MultiChatUser: Object {
    @objc dynamic var user: User?
    @objc dynamic var invitedBy: User?
    convenience init(_ user: User, invitedBy: User) {
        self.init()
        self.user = user
        self.invitedBy = invitedBy
    }
}

enum MultichatStatus: Int {
    case active
    case left
    case kicked
}

class Chat: Object {
    @objc dynamic var user: User? {
        didSet {
            user >>> {userID = $0.id}
        }
    }
    var timer: Timer?
    @objc dynamic var date = Date()
    @objc dynamic var userID = 0
    @objc dynamic var isTyping = false
    @objc dynamic var lastReadMessageID = 0
    let count = RealmOptional<Int>()
    @objc dynamic var messages: Messages?
    //    let messages = List<Message>()
    @objc dynamic var important = false
    @objc dynamic var answered = false
    let attachments = List<RealmMedia>()
    @objc dynamic var notificationSettings: RealmNotificatonSettings?
    class func by(user: User) -> Chat {
        let realm = try! Realm()
        if let us = realm.object(ofType: Chat.self, forPrimaryKey: user.id) {
            return us
        } else {
            let us = Chat()
            realmWrite { realm in
                us.user = user
                us.messages = Messages.by(id: us.peerID)
                realm.add(us)
            }
            return us
        }
    }
    
    convenience init(user: User) {
        self.init()
        self.user = user
    }
    override static func ignoredProperties() -> [String] {
        return ["timer"]
    }
    override class func primaryKey() -> String? {
        return "userID"
    }
}

extension Chat: Dialog {
    var firstMessage: Message? {
        return messages?.first
    }
    
    var name: String? {
        if let firstName = user?.firstName,
            let lastName = user?.lastName {
            return "\(firstName) \(lastName)"
        } else {
            return nil
        }
    }
    
    func loadImage(into view: UIImageView, completion: (() -> ())? = nil) -> RealmPhotoToken? {
        return user?.avatar?.load(into: view, completion: completion)
    }
    
    //    func image(completion: @escaping ((UIImage?) -> ())) {
    //        if let im = user?.avatar?.image {
    //            im(completion)
    //        } else {
    //            completion(nil)
    //        }
    //    }
    
    var id: Int {
        return userID
    }
    
    var peerID: Int {
        return userID
    }
}

struct ChatNotificationSettings {
    var sound: Bool
    var disabledUntil: disableDate
}

enum disableDate {
    case never
    case date(Date)
    init?(value: Int) {
        switch value {
        case -1:
            self = .never
        case 0:
            return nil
        default:
            self = .date(Date(timeIntervalSince1970: TimeInterval(value)))
        }
    }
}

func isPhoneNumber(_ phone: String) -> Bool {
    let nums = "1234567890".characters
    let f002 = phone.characters.map{nums.contains($0) ? 1 : 0}
    let foo1 = Double(sum(acc: 0, arr: f002))
    let foo = foo1/Double(phone.characters.count)
    return foo >= 0.4 ? true : false
}



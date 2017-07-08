//
//  File.swift
//  golos
//
//  Created by Ilya Kos on 12/10/16.
//  Copyright © 2016 Ilya Kos. All rights reserved.
//

import SwiftyVK

let permissions: Set<VK.Scope> = [
    .notify,
    .friends,
    .photos,
    .audio,
    .video,
    .docs,
    .notes,
    .pages,
    .status,
    .offers,
    .questions,
    .wall,
    .groups,
    .messages,
    .email,
    .notifications,
    .stats,
    .ads,
    .offline,
    .market
]
let vkAPIVersion = "5.60"
let appID = "5529752"

let multichatchatId = 2000000000

enum Methods {
    static let getDialogs = "getDialogs"
}

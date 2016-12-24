//
//  Tweet.swift
//  TimerTweetViewer
//
//  Created by Keisei Saito on 2016/12/25.
//  Copyright © 2016 keisei_1092. All rights reserved.
//

import Foundation

struct Tweet {
    let text: String
    let createdAt: String
    let user: User
}

struct User {
    let name: String
    let screenName: String
    let profileImageURLHTTPS: String
}

//
//  Post.swift
//  Original
//
//  Created by 藤井　孝輔 on 2020/05/09.
//  Copyright © 2020 fujii_kosuke. All rights reserved.
//

import UIKit

class Post: NSObject {
    var objectId: String
    var user: User
    var title: String
    var author: String
    var genre: String
    var text: String
    var date: String?
    var publisher: String?
    var createDate: Date
    var isLiked: Bool?
    
    init(objectId: String, user: User, title: String, author: String, genre: String, createDate: Date, text: String) {
        self.objectId = objectId
        self.user = user
        self.title = title
        self.author = author
        self.genre = genre
        self.text = text
        self.createDate = createDate
    }
}

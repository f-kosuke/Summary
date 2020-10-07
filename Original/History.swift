//
//  History.swift
//  Original
//
//  Created by 藤井　孝輔 on 2020/05/27.
//  Copyright © 2020 fujii_kosuke. All rights reserved.
//

import UIKit

class History: NSObject {
    var post: Post
    var postId: String
    var user: User
    
    init(post: Post, postId: String, user: User) {
        self.post = post
        self.postId = postId
        self.user = user
    }

}

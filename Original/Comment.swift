//
//  Comment.swift
//  Original
//
//  Created by 藤井　孝輔 on 2020/05/12.
//  Copyright © 2020 fujii_kosuke. All rights reserved.
//

import UIKit

class Comment: NSObject {
    var postId: String
    var user: User
    var text: String
    
    init(postId: String, user: User, text: String) {
        self.postId = postId
        self.user = user
        self.text = text
    }

}

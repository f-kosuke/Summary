//
//  User.swift
//  Original
//
//  Created by 藤井　孝輔 on 2020/05/09.
//  Copyright © 2020 fujii_kosuke. All rights reserved.
//

import UIKit

class User: NSObject {
    var objectId: String
    var userName: String
    
    init(objectId: String, userName: String) {
        self.objectId = objectId
        self.userName = userName
    }
}

//
//  Item.swift
//  Kali Note
//
//  Created by Kenan Ali on 20.03.26.
//

import Foundation
import SwiftData

@Model
final class Item {
    var timestamp: Date
    var user: User?
    
    init(timestamp: Date, user: User? = nil) {
        self.timestamp = timestamp
        self.user = user
    }
}

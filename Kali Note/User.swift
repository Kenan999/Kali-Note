//
//  User.swift
//  Kali Note
//
//  Created by Antigravity on 20.03.26.
//

import Foundation
import SwiftData

@Model
final class User {
    @Attribute(.unique) var email: String
    var username: String
    var createdAt: Date
    
    @Relationship(deleteRule: .cascade, inverse: \AuthMethod.user)
    var authMethods: [AuthMethod] = []
    
    // Document-oriented metadata stored as JSON Data
    var metadata: Data?
    
    init(email: String, username: String, metadata: Data? = nil) {
        self.email = email
        self.username = username
        self.createdAt = Date()
        self.metadata = metadata
    }
}

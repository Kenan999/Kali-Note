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
    var email: String
    var username: String
    var passwordHash: String?
    var profilePhotoURL: String?
    var isOffline: Bool?
    var createdAt: Date
    
    @Relationship(deleteRule: .cascade, inverse: \AuthMethod.user)
    var authMethods: [AuthMethod] = []
    
    @Relationship(deleteRule: .cascade, inverse: \Item.user)
    var items: [Item] = []
    
    // Document-oriented metadata stored as JSON Data
    var metadata: Data?
    
    init(email: String, username: String, passwordHash: String? = nil, isOffline: Bool = false, metadata: Data? = nil) {
        self.email = email
        self.username = username
        self.passwordHash = passwordHash
        self.isOffline = isOffline
        self.createdAt = Date()
        self.metadata = metadata
    }
    
    var initials: String {
        let name = username.isEmpty ? email : username
        let components = name.components(separatedBy: " ")
        if components.count > 1 {
            return (String(components[0].prefix(1)) + String(components[1].prefix(1))).uppercased()
        } else {
            return String(name.prefix(2)).uppercased()
        }
    }
}

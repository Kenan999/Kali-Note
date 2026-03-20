//
//  AuthMethod.swift
//  Kali Note
//
//  Created by Antigravity on 20.03.26.
//

import Foundation
import SwiftData

@Model
final class AuthMethod {
    var provider: String // "google", "apple", "normal", "android"
    var externalID: String
    var createdAt: Date
    
    var user: User?
    
    init(provider: String, externalID: String, user: User? = nil) {
        self.provider = provider
        self.externalID = externalID
        self.createdAt = Date()
        self.user = user
    }
}

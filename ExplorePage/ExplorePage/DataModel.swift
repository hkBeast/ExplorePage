//
//  DataModel.swift
//  ExplorePage
//
//  Created by HKBeast on 09/12/24.
//

import SwiftUI

// Main response model
struct Response: Codable {
    let status: Bool
    let data: [ExploreData]
    let totalPages: Int
    let premiumStatus: Int
    let problemFilter: [FilterModel] // You can change the type if the problem_filter contains more complex data
    
    // Coding Keys to map JSON keys to Swift property names
    enum CodingKeys: String, CodingKey {
        case status
        case data
        case totalPages = "total_pages"
        case premiumStatus = "premium_status"
        case problemFilter = "problem_filter"
    }
}


// Main model to represent each item in the JSON
struct ExploreData: Codable,Hashable {
    let id: Int
    let title: String
    let juLabel: String
    let promoText: String
    let description: String
    let juType: String
    let juPremium: String
    let numDays: Int
    let thumbImage: String
    let coverImage: String
    let juLink: String? // Can be null, so optional
    let problems: [String] // If problems contain more complex data, you can create a model for it
    let techniques: [String] // If techniques contain more complex data, you can create a model for it
    let days: [DateDataModel] // If days contain more complex data, you can create a model for it
    let details: String
    let sessions: String
    let mins: String

    // Coding keys to map JSON keys with Swift properties
    enum CodingKeys: String, CodingKey {
        case id
        case title
        case juLabel = "ju_label"
        case promoText = "promo_text"
        case description
        case juType = "ju_type"
        case juPremium = "ju_premium"
        case numDays = "num_days"
        case thumbImage = "thumb_image"
        case coverImage = "cover_image"
        case juLink = "ju_link"
        case problems
        case techniques
        case days
        case details
        case sessions
        case mins
    }
}



    // Main model to represent the journey progress
struct DateDataModel: Codable,Hashable {
    let id: Int
    let title: String
    let description: String
    let numSteps: Int
    let dayCompleted: String
    let completedSteps: Int
    
    // Coding keys to map JSON keys with Swift properties
    enum CodingKeys: String, CodingKey {
        case id
        case title
        case description
        case numSteps = "num_steps"
        case dayCompleted = "day_completed"
        case completedSteps = "completed_steps"
    }
}


struct FilterModel : Codable,Hashable{
    let title: String
    let id : Int
}

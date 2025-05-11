//
//  QuoteModel.swift
//  ProductivityApp
//
//  Created by Zhanserik Amangeldi on 11.05.2025.
//

import Foundation

struct Quote: Codable, Identifiable {
    var id: String { content.hashValue.description }
    let content: String
    let author: String
    
    enum CodingKeys: String, CodingKey {
        case content = "q"
        case author = "a"
    }
}

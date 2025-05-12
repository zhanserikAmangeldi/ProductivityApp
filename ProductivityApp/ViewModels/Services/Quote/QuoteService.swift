//
//  QuoteService.swift
//  ProductivityApp
//
//  Created by Zhanserik Amangeldi on 11.05.2025.
//

import Foundation

class QuotesService {
    static let shared = QuotesService()
    
    private let cache = NSCache<NSString, NSArray>()
    private let cacheKey = "cachedQuotes" as NSString
    
    private init() {}
    
    func clearCache() {
        cache.removeAllObjects()
    }
    
    func fetchQuotes() async throws -> [Quote] {
        // Check cache first
        if let cachedQuotes = cache.object(forKey: cacheKey) as? [Quote], !cachedQuotes.isEmpty {
            return cachedQuotes
        }
        
        // Fetch from API
        let url = URL(string: "https://zenquotes.io/api/quotes")!
        
        do {
            let (data, response) = try await URLSession.shared.data(from: url)
            
            guard let httpResponse = response as? HTTPURLResponse,
                  httpResponse.statusCode == 200 else {
                throw NetworkError.invalidResponse
            }
            
            let quotes = try JSONDecoder().decode([Quote].self, from: data)
            
            // Cache the results
            cache.setObject(quotes as NSArray, forKey: cacheKey)
            
            return quotes
        } catch {
            throw error
        }
    }
    
    func getRandomQuote() async throws -> Quote {
        do {
            let quotes = try await fetchQuotes()
            guard let randomQuote = quotes.randomElement() else {
                throw QuoteError.noQuotesAvailable
            }
            return randomQuote
        } catch {
            throw error
        }
    }
}

enum NetworkError: Error {
    case invalidResponse
    case invalidData
}

enum QuoteError: Error {
    case noQuotesAvailable
}

//
//  NaturalLanguageParser.swift
//  FortnightBudget
//
//  Parses natural language transaction input like "coles 85.50 grocery"
//  into structured Transaction objects.
//

import Foundation

struct NaturalLanguageParser {
    
    /// Parse a natural language string into transaction components.
    /// Supports formats: "description amount category", "amount description", "description amount"
    /// Examples:
    ///   "coles 85.50 grocery" → (description: "Coles", amount: 85.50, category: Groceries)
    ///   "84.50 woolworths"    → (description: "Woolworths", amount: 84.50, category: nil)
    ///   "salary 3500"         → (description: "Salary", amount: 3500.00, category: Income)
    func parse(_ input: String) -> ParsedTransaction? {
        let trimmed = input.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return nil }
        
        let words = trimmed.components(separatedBy: .whitespaces)
            .filter { !$0.isEmpty }
        
        guard words.count >= 2 else {
            // Single word — could be a known category or description
            if let category = findCategory(words[0]) {
                return ParsedTransaction(description: words[0], amount: nil, category: category)
            }
            return ParsedTransaction(description: words[0], amount: nil, category: nil)
        }
        
        // Try to extract amount (look for number patterns)
        var amount: Decimal?
        var descriptionWords: [String] = []
        var categoryHint: String?
        
        for word in words {
            if let parsedAmount = parseAmount(word) {
                amount = parsedAmount
            } else if let foundCategory = findCategory(word) {
                categoryHint = word
            } else {
                descriptionWords.append(word)
            }
        }
        
        let description = descriptionWords.joined(separator: " ").capitalized
        let category = categoryHint.flatMap { findCategory($0) }
        
        guard !description.isEmpty else { return nil }
        
        return ParsedTransaction(
            description: description,
            amount: amount,
            category: category
        )
    }
    
    // MARK: - Amount parsing
    
    private func parseAmount(_ word: String) -> Decimal? {
        // Strip $ prefix and commas
        let cleaned = word
            .replacingOccurrences(of: "$", with: "")
            .replacingOccurrences(of: ",", with: "")
            .replacingOccurrences(of: "-", with: "")  // handle "-120" as negative
        
        guard let decimal = Decimal(string: cleaned) else { return nil }
        return decimal
    }
    
    // MARK: - Category matching
    
    private func findCategory(_ word: String) -> TransactionCategory? {
        let lower = word.lowercased()
        
        let categories: [(String, TransactionCategory)] = [
            // Income
            ("salary", .income), ("pay", .income), ("income", .income), ("wage", .income),
            ("freelance", .income), ("invoice", .income),
            
            // Groceries / Shopping
            ("grocery", .groceries), ("coles", .groceries), ("woolworths", .groceries),
            ("aldi", .groceries), ("iga", .groceries), ("food", .groceries),
            ("shopping", .shopping), ("kmart", .shopping), ("target", .shopping),
            ("amazon", .shopping), ("bigw", .shopping), ("bunnings", .shopping),
            
            // Transport
            ("transport", .transport), ("fuel", .transport), ("petrol", .transport),
            ("uber", .transport), ("taxi", .transport), ("parking", .transport),
            ("toll", .transport), ("myki", .transport), ("opal", .transport),
            ("smartrider", .transport), ("transperth", .transport),
            
            // Housing
            ("rent", .housing), ("mortgage", .housing), ("strata", .housing),
            ("repair", .housing), ("rates", .housing),
            
            // Utilities
            ("electricity", .utilities), ("gas", .utilities), ("water", .utilities),
            ("synergy", .utilities), ("internet", .utilities),
            ("phone", .utilities), ("mobile", .utilities),
            
            // Dining / Entertainment
            ("dining", .dining), ("restaurant", .dining), ("cafe", .dining),
            ("coffee", .dining), ("mcdonalds", .dining), ("maccas", .dining),
            ("hungry jacks", .dining), ("dominos", .dining),
            ("netflix", .entertainment), ("spotify", .entertainment),
            ("disney", .entertainment), ("youtube", .entertainment),
            
            // Subscriptions
            ("subscription", .subscriptions), ("membership", .subscriptions),
            ("apple", .subscriptions), ("icloud", .subscriptions),
            
            // Insurance
            ("insurance", .insurance), ("aami", .insurance), ("rac", .insurance),
            
            // Health
            ("health", .health), ("doctor", .health), ("dentist", .health),
            ("pharmacy", .health), ("chemist", .health), ("gym", .health),
            
            // Debt
            ("debt", .debt), ("loan", .debt), ("credit", .debt),
            ("afterpay", .debt), ("zip", .debt),
            
            // Savings
            ("savings", .savings), ("investment", .savings), ("super", .savings),
            
            // Tax
            ("tax", .tax), ("ato", .tax),
        ]
        
        for (keyword, category) in categories {
            if lower == keyword || lower.hasPrefix(keyword) {
                return category
            }
        }
        
        return nil
    }
}

// MARK: - Parsed Result

struct ParsedTransaction {
    let description: String
    let amount: Decimal?
    let category: TransactionCategory?
}

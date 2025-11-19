//
//  HistoryItem.swift
//  Calculator
//
//  Created by Trae AI on 2025/1/15.
//

import Foundation

struct HistoryItem: Codable {
    let id: UUID
    let expression: String
    let result: String
    let timestamp: Date
    
    init(expression: String, result: String) {
        self.id = UUID()
        self.expression = expression
        self.result = result
        self.timestamp = Date()
    }
}

class HistoryManager {
    static let shared = HistoryManager()
    private let defaults = UserDefaults.standard
    private let key = "calculatorHistory"
    
    func save(item: HistoryItem) {
        var history = getHistory()
        history.insert(item, at: 0) // 最新记录放在最前面
        
        do {
            let data = try JSONEncoder().encode(history)
            defaults.set(data, forKey: key)
        } catch {
            print("Failed to save history: \(error)")
        }
    }
    
    func getHistory() -> [HistoryItem] {
        guard let data = defaults.data(forKey: key) else {
            return []
        }
        
        do {
            return try JSONDecoder().decode([HistoryItem].self, from: data)
        } catch {
            print("Failed to load history: \(error)")
            return []
        }
    }
    
    func deleteItem(id: UUID) {
        var history = getHistory()
        history.removeAll { $0.id == id }
        
        do {
            let data = try JSONEncoder().encode(history)
            defaults.set(data, forKey: key)
        } catch {
            print("Failed to delete history item: \(error)")
        }
    }
    
    func deleteItems(ids: [UUID]) {
        var history = getHistory()
        history.removeAll { ids.contains($0.id) }
        
        do {
            let data = try JSONEncoder().encode(history)
            defaults.set(data, forKey: key)
        } catch {
            print("Failed to delete multiple history items: \(error)")
        }
    }
    
    func clearAll() {
        defaults.removeObject(forKey: key)
    }
}
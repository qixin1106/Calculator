import Foundation

// Protocol for history item selection\pprotocol HistoryDelegate {
    func historyItemSelected(_ item: HistoryItem)
}

// History item model
struct HistoryItem {
    let expression: String
    let result: String
    let timestamp: Date
}

// History manager singleton
class HistoryManager {
    static let shared = HistoryManager()
    
    private var items: [HistoryItem] = []
    private let userDefaults = UserDefaults.standard
    private let historyKey = "calculatorHistory"
    
    private init() {
        loadHistory()
    }
    
    // Add a new history item
    func addItem(expression: String, result: String) {
        let item = HistoryItem(expression: expression, result: result, timestamp: Date())
        items.insert(item, at: 0) // Add to the beginning
        saveHistory()
    }
    
    // Get all history items
    func getAllItems() -> [HistoryItem] {
        return items
    }
    
    // Clear all history items
    func clearHistory() {
        items.removeAll()
        saveHistory()
    }
    
    // Load history from UserDefaults
    private func loadHistory() {
        if let data = userDefaults.data(forKey: historyKey) {
            do {
                items = try JSONDecoder().decode([HistoryItem].self, from: data)
            } catch {
                print("Failed to load history: \(error)")
            }
        }
    }
    
    // Save history to UserDefaults
    private func saveHistory() {
        do {
            let data = try JSONEncoder().encode(items)
            userDefaults.set(data, forKey: historyKey)
        } catch {
            print("Failed to save history: \(error)")
        }
    }
}
//
//  HistoryItem.swift
//  Calculator
//
//  Created by Andrea Vultaggio on 24/10/2017.
//  Copyright © 2017 Andrea Vultaggio. All rights reserved.
//

import Foundation

struct HistoryItem: Codable {
    let id: UUID
    let expression: String
    let result: String
    let timestamp: Date
}
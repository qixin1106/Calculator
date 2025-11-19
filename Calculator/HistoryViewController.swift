//
//  HistoryViewController.swift
//  Calculator
//
//  Created by Andrea Vultaggio on 24/10/2017.
//  Copyright © 2017 Andrea Vultaggio. All rights reserved.
//

import UIKit

class HistoryViewController: UIViewController {
    @IBOutlet weak var historyTableView: UITableView!
    @IBOutlet weak var deleteButton: UIBarButtonItem!
    @IBOutlet weak var editButton: UIBarButtonItem!
    @IBOutlet weak var clearAllButton: UIBarButtonItem!
    @IBOutlet weak var doneButton: UIBarButtonItem!
    
    var historyItems: [HistoryItem] = []
    var selectedItem: HistoryItem?
    var isEditingMode: Bool = false
    var selectedIndices: Set<IndexPath> = []
    
    weak var delegate: HistoryDelegate?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        historyTableView.delegate = self
        historyTableView.dataSource = self
        
        // 加载历史记录
        loadHistory()
        
        // 设置编辑模式
        setEditingMode(false)
    }
    
    // 加载历史记录
    func loadHistory() {
        if let savedHistory = UserDefaults.standard.data(forKey: "calculatorHistory"),
           let decodedHistory = try? JSONDecoder().decode([HistoryItem].self, from: savedHistory) {
            historyItems = decodedHistory.reversed() // 倒序展示
            historyTableView.reloadData()
        }
    }
    
    // 保存历史记录
    func saveHistory() {
        // 先获取完整历史，再添加新记录，然后保存
        var fullHistory: [HistoryItem] = []
        if let savedHistory = UserDefaults.standard.data(forKey: "calculatorHistory"),
           let decodedHistory = try? JSONDecoder().decode([HistoryItem].self, from: savedHistory) {
            fullHistory = decodedHistory
        }
        
        // 倒序添加新记录
        for item in historyItems.reversed() {
            if !fullHistory.contains(where: { $0.id == item.id }) {
                fullHistory.append(item)
            }
        }
        
        if let encodedHistory = try? JSONEncoder().encode(fullHistory) {
            UserDefaults.standard.set(encodedHistory, forKey: "calculatorHistory")
        }
    }
    
    // 设置编辑模式
    func setEditingMode(_ isEditing: Bool) {
        isEditingMode = isEditing
        navigationItem.rightBarButtonItems = isEditing ? [doneButton, clearAllButton, deleteButton] : [editButton]
        historyTableView.setEditing(isEditing, animated: true)
        
        // 清除选中索引
        selectedIndices.removeAll()
        updateDeleteButtonState()
    }
    
    // 更新删除按钮状态
    func updateDeleteButtonState() {
        deleteButton.isEnabled = !selectedIndices.isEmpty
    }
    
    // MARK: - IBActions
    
    @IBAction func editButtonTapped(_ sender: UIBarButtonItem) {
        setEditingMode(true)
    }
    
    @IBAction func doneButtonTapped(_ sender: UIBarButtonItem) {
        setEditingMode(false)
    }
    
    @IBAction func deleteButtonTapped(_ sender: UIBarButtonItem) {
        // 删除选中的记录
        let sortedIndices = selectedIndices.sorted(by: { $0.row > $1.row })
        for indexPath in sortedIndices {
            historyItems.remove(at: indexPath.row)
            selectedIndices.remove(indexPath)
        }
        
        historyTableView.deleteRows(at: sortedIndices, with: .automatic)
        saveHistory()
        updateDeleteButtonState()
        
        if historyItems.isEmpty {
            setEditingMode(false)
        }
    }
    
    @IBAction func clearAllButtonTapped(_ sender: UIBarButtonItem) {
        let alert = UIAlertController(title: "确认清空", message: "是否要清空所有历史记录？", preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "取消", style: .cancel, handler: nil))
        alert.addAction(UIAlertAction(title: "清空", style: .destructive, handler: { [weak self] _ in
            self?.historyItems.removeAll()
            self?.historyTableView.reloadData()
            self?.saveHistory()
            self?.setEditingMode(false)
        }))
        present(alert, animated: true, completion: nil)
    }
}

// MARK: - UITableViewDelegate & UITableViewDataSource

extension HistoryViewController: UITableViewDelegate, UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return historyItems.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "HistoryCell", for: indexPath)
        let item = historyItems[indexPath.row]
        
        // 设置表达式和结果
        cell.textLabel?.text = item.expression
        cell.detailTextLabel?.text = item.result
        
        // 设置时间戳
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd HH:mm"
        let timestampString = dateFormatter.string(from: item.timestamp)
        cell.accessoryView = UILabel(frame: CGRect(x: 0, y: 0, width: 150, height: 20))
        (cell.accessoryView as? UILabel)?.text = timestampString
        (cell.accessoryView as? UILabel)?.font = UIFont.systemFont(ofSize: 12)
        (cell.accessoryView as? UILabel)?.textColor = .gray
        
        // 设置选中状态
        cell.accessoryType = selectedIndices.contains(indexPath) ? .checkmark : .none
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let item = historyItems[indexPath.row]
        
        if isEditingMode {
            // 编辑模式下，切换选中状态
            if selectedIndices.contains(indexPath) {
                selectedIndices.remove(indexPath)
            } else {
                selectedIndices.insert(indexPath)
            }
            tableView.reloadRows(at: [indexPath], with: .automatic)
            updateDeleteButtonState()
        } else {
            // 非编辑模式下，导回主界面
            delegate?.historyItemSelected(item)
            navigationController?.popViewController(animated: true)
        }
    }
    
    func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            historyItems.remove(at: indexPath.row)
            historyTableView.deleteRows(at: [indexPath], with: .automatic)
            saveHistory()
            
            if historyItems.isEmpty {
                setEditingMode(false)
            }
        }
    }
}

// MARK: - History Delegate

protocol HistoryDelegate: AnyObject {
    func historyItemSelected(_ item: HistoryItem)
}
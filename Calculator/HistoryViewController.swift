//
//  HistoryViewController.swift
//  Calculator
//
//  Created by Trae AI on 2025/1/15.
//

import UIKit

protocol HistoryViewControllerDelegate: AnyObject {
    func didSelectHistoryItem(_ item: HistoryItem)
}

class HistoryViewController: UIViewController {
    
    @IBOutlet weak var historyTableView: UITableView!
    @IBOutlet weak var deleteButton: UIBarButtonItem!
    @IBOutlet weak var selectAllButton: UIBarButtonItem!
    
    weak var delegate: HistoryViewControllerDelegate?
    
    private var historyItems: [HistoryItem] = []
    private var selectedItems: Set<UUID> = []
    private var isEditingMode = false
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        title = "历史记录"
        
        historyTableView.dataSource = self
        historyTableView.delegate = self
        historyTableView.register(UITableViewCell.self, forCellReuseIdentifier: "HistoryCell")
        
        navigationItem.rightBarButtonItems = [deleteButton, selectAllButton]
        deleteButton.isEnabled = false
        
        loadHistory()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        loadHistory()
    }
    
    private func loadHistory() {
        historyItems = HistoryManager.shared.getHistory()
        historyTableView.reloadData()
    }
    
    @IBAction func deleteButtonTapped(_ sender: UIBarButtonItem) {
        if selectedItems.isEmpty {
            return
        }
        
        let alert = UIAlertController(title: "删除记录", message: "确定要删除选中的\(selectedItems.count)条记录吗？", preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "取消", style: .cancel))
        alert.addAction(UIAlertAction(title: "删除", style: .destructive) { [weak self] _ in
            guard let self = self else { return }
            HistoryManager.shared.deleteItems(ids: Array(self.selectedItems))
            self.selectedItems.removeAll()
            self.loadHistory()
            self.updateEditMode()
        })
        present(alert, animated: true)
    }
    
    @IBAction func selectAllButtonTapped(_ sender: UIBarButtonItem) {
        if selectedItems.count == historyItems.count {
            // 取消全选
            selectedItems.removeAll()
            selectAllButton.title = "全选"
        } else {
            // 全选
            selectedItems = Set(historyItems.map { $0.id })
            selectAllButton.title = "取消全选"
        }
        deleteButton.isEnabled = !selectedItems.isEmpty
        historyTableView.reloadData()
    }
    
    private func updateEditMode() {
        if selectedItems.isEmpty {
            isEditingMode = false
            selectAllButton.title = "全选"
        } else {
            isEditingMode = true
        }
        deleteButton.isEnabled = !selectedItems.isEmpty
    }
}

extension HistoryViewController: UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return historyItems.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "HistoryCell", for: indexPath)
        let item = historyItems[indexPath.row]
        
        var content = cell.defaultContentConfiguration()
        content.text = item.expression + " " + item.result
        content.secondaryText = formatDate(item.timestamp)
        cell.contentConfiguration = content
        
        // 设置选中状态
        cell.accessoryType = selectedItems.contains(item.id) ? .checkmark : .none
        
        return cell
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
}

extension HistoryViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let item = historyItems[indexPath.row]
        
        if isEditingMode {
            // 编辑模式下切换选中状态
            if selectedItems.contains(item.id) {
                selectedItems.remove(item.id)
            } else {
                selectedItems.insert(item.id)
            }
            updateEditMode()
            tableView.reloadRows(at: [indexPath], with: .automatic)
        } else {
            // 非编辑模式下返回主界面
            delegate?.didSelectHistoryItem(item)
            navigationController?.popViewController(animated: true)
        }
    }
    
    func tableView(_ tableView: UITableView, trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
        let deleteAction = UIContextualAction(style: .destructive, title: "删除") { [weak self] _, _, completion in
            guard let self = self else { return }
            let item = self.historyItems[indexPath.row]
            HistoryManager.shared.deleteItem(id: item.id)
            self.historyItems.remove(at: indexPath.row)
            self.tableView.deleteRows(at: [indexPath], with: .automatic)
            completion(true)
        }
        
        return UISwipeActionsConfiguration(actions: [deleteAction])
    }
}
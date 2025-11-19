//
//  ViewController.swift
//  Calculator
//
//  Created by Andrea Vultaggio on 17/10/2017.
//  Copyright © 2017 Andrea Vultaggio. All rights reserved.
//

import UIKit
import DeviceKit

class ViewController: UIViewController, HistoryDelegate {
    
    //MARK: Outlets
    
    @IBOutlet weak var sequence: UILabel!
    @IBOutlet weak var cornerView: UIView!
    @IBOutlet weak var display: UILabel!
    @IBOutlet weak var historyButton: UIButton!
    
    //MARK: Variables
    
    private var brain = CalculatorBrain()
    private var userIsInTheMiddleOfTyping = false
    
    private var iPhoneModel: Device {
        return Device.realDevice(from: .current)
    }
    
    private var displayValue: Double {
        get {
            return Double(display.text ?? Constants.emptyString) ?? Double.nan
        }
        set {
            let tmp = String(newValue).removeAfterPointIfZero()
            display.text = tmp.setMaxLength(of: 8)
        }
    }
 
    override var preferredStatusBarStyle: UIStatusBarStyle {
        return .lightContent
    }
    
    override var prefersStatusBarHidden: Bool {
        return false
    }
    
    //MARK: UIVIew Delegate
    
    override func viewDidLoad() {
        // round the corners of the calculator on iPhones with the notch.
        if Device.allDevicesWithSensorHousing.contains(iPhoneModel) {
            cornerView.layer.cornerRadius = Constants.cornerRadius
            cornerView.layer.masksToBounds = true
        } 
        
        // 设置label自动缩放
        setupAutoResizeLabels()
    }
    
    // 设置label自动缩放
    private func setupAutoResizeLabels() {
        // 设置自动调整大小
        sequence.adjustsFontSizeToFitWidth = true
        sequence.minimumScaleFactor = 0.2 // 最小缩放因子
        sequence.numberOfLines = 1
        sequence.lineBreakMode = .byClipping
        
        display.adjustsFontSizeToFitWidth = true
        display.minimumScaleFactor = 0.2 // 最小缩放因子
        display.numberOfLines = 1
        display.lineBreakMode = .byClipping
    }
    
    //MARK: IBAction(s)
    
    @IBAction func touchDigit(_ sender: UIButton) {
        guard let digit = sender.currentTitle else { return }
        
        if userIsInTheMiddleOfTyping {
            guard let textCurrentlyInDisplay = display.text else { return }
            
            if digit == "." && (textCurrentlyInDisplay.range(of: Constants.decimalPoint) != nil) {
                return
            } else {
                let tmp = textCurrentlyInDisplay + digit
                display.text = tmp.setMaxLength(of: Constants.maxStringLength)
            }
            
        } else {
            if digit == Constants.decimalPoint {
                display.text = Constants.pointAfterZero
            } else {
                display.text = digit
            }
            userIsInTheMiddleOfTyping = true
        }
        
        sequence.text = brain.description
    }
    
    @IBAction func performOperation(_ sender: UIButton) {
        if userIsInTheMiddleOfTyping {
            brain.setOperand(displayValue)
            userIsInTheMiddleOfTyping = false
        }
        
        if let mathematicalSymbol = sender.currentTitle {
            brain.performOperation(mathematicalSymbol)
        }
        
        if let result = brain.result {
            displayValue = result
            
            // 如果是按了等号，保存历史记录
            if sender.currentTitle == "=" {
                saveHistory()
            }
        }
        
        sequence.text = brain.description
    }
    
    // 保存历史记录
    private func saveHistory() {
        if let expression = sequence.text, let result = display.text, !expression.isEmpty {
            let historyItem = HistoryItem(
                id: UUID(),
                expression: expression,
                result: result,
                timestamp: Date()
            )
            
            // 保存到UserDefaults
            var history: [HistoryItem] = []
            if let savedData = UserDefaults.standard.data(forKey: "calculatorHistory"),
               let decodedHistory = try? JSONDecoder().decode([HistoryItem].self, from: savedData) {
                history = decodedHistory
            }
            
            history.append(historyItem)
            
            if let encodedData = try? JSONEncoder().encode(history) {
                UserDefaults.standard.set(encodedData, forKey: "calculatorHistory")
            }
        }
    }
    
    // MARK: - History Delegate
    
    func historyItemSelected(_ item: HistoryItem) {
        // 将历史记录导回主界面
        let parts = item.expression.components(separatedBy: "=")
        if let expressionPart = parts.first {
            sequence.text = expressionPart
        }
        display.text = item.result
        userIsInTheMiddleOfTyping = false
    }
    
    // MARK: - Navigation
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "showHistory", let destinationVC = segue.destination as? HistoryViewController {
            destinationVC.delegate = self
        }
    }
}

extension ViewController {
    struct Constants {
        static let cornerRadius: CGFloat = 35.0
        static let decimalPoint: String = "."
        static let emptyString: String = ""
        static let maxStringLength: Int = 8
        static let pointAfterZero: String = "0."
    }
}

//
//  ViewController.swift
//  Calculator
//
//  Created by Andrea Vultaggio on 17/10/2017.
//  Copyright © 2017 Andrea Vultaggio. All rights reserved.
//

import UIKit
import DeviceKit

class ViewController: UIViewController {
    
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
            display.text = tmp
            autoScaleLabel(display)
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
        setupLabels()
        
        // 添加历史按钮
        setupHistoryButton()
    }
    
    private func setupLabels() {
        // 开启label自动收缩
        sequence.adjustsFontSizeToFitWidth = true
        sequence.minimumScaleFactor = 0.5
        sequence.lineBreakMode = .byClipping
        
        display.adjustsFontSizeToFitWidth = true
        display.minimumScaleFactor = 0.5
        display.lineBreakMode = .byClipping
        
        // 设置滚动
        let sequenceScrollView = UIScrollView(frame: sequence.frame)
        sequenceScrollView.contentSize = CGSize(width: sequence.frame.width * 2, height: sequence.frame.height)
        sequenceScrollView.addSubview(sequence)
        view.addSubview(sequenceScrollView)
        
        let displayScrollView = UIScrollView(frame: display.frame)
        displayScrollView.contentSize = CGSize(width: display.frame.width * 2, height: display.frame.height)
        displayScrollView.addSubview(display)
        view.addSubview(displayScrollView)
    }
    
    private func setupHistoryButton() {
        historyButton = UIButton(type: .system)
        historyButton.setTitle("历史", for: .normal)
        historyButton.setTitleColor(.white, for: .normal)
        historyButton.addTarget(self, action: #selector(historyButtonTapped), for: .touchUpInside)
        historyButton.frame = CGRect(x: 20, y: 50, width: 60, height: 30)
        view.addSubview(historyButton)
    }
    
    private func autoScaleLabel(_ label: UILabel) {
        guard let text = label.text, !text.isEmpty else {
            return
        }
        
        var fontSize: CGFloat = label.font.pointSize
        let minFontSize: CGFloat = 20
        
        let maxWidth = label.frame.width
        let labelSize = (text as NSString).boundingRect(with: CGSize(width: CGFloat.greatestFiniteMagnitude, height: label.frame.height), options: .usesLineFragmentOrigin, attributes: [.font: label.font.withSize(fontSize)], context: nil)
        
        // 缩小字体直到能容纳
        while labelSize.width > maxWidth && fontSize > minFontSize {
            fontSize -= 1
            let newSize = (text as NSString).boundingRect(with: CGSize(width: CGFloat.greatestFiniteMagnitude, height: label.frame.height), options: .usesLineFragmentOrigin, attributes: [.font: label.font.withSize(fontSize)], context: nil)
            if newSize.width <= maxWidth {
                break
            }
        }
        
        label.font = label.font.withSize(fontSize)
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
                display.text = tmp
                autoScaleLabel(display)
            }
            
        } else {
            if digit == Constants.decimalPoint {
                display.text = Constants.pointAfterZero
            } else {
                display.text = digit
            }
            userIsInTheMiddleOfTyping = true
            autoScaleLabel(display)
        }
        
        sequence.text = brain.description
        autoScaleLabel(sequence)
    }
    
    @IBAction func performOperation(_ sender: UIButton) {
        if userIsInTheMiddleOfTyping {
            brain.setOperand(displayValue)
            userIsInTheMiddleOfTyping = false
        }
        
        if let mathematicalSymbol = sender.currentTitle {
            brain.performOperation(mathematicalSymbol)
            
            // 当按下等号时保存历史记录
            if mathematicalSymbol == "=" {
                if let result = brain.result {
                    let expression = brain.description
                    let resultStr = String(result).removeAfterPointIfZero()
                    let historyItem = HistoryItem(expression: expression, result: resultStr)
                    HistoryManager.shared.save(item: historyItem)
                }
            }
        }
        
        if let result = brain.result {
            displayValue = result
        }
        
        sequence.text = brain.description
        autoScaleLabel(sequence)
    }
    
    @objc private func historyButtonTapped() {
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        if let historyVC = storyboard.instantiateViewController(withIdentifier: "HistoryViewController") as? HistoryViewController {
            historyVC.delegate = self
            navigationController?.pushViewController(historyVC, animated: true)
        }
    }
}

extension ViewController: HistoryViewControllerDelegate {
    func didSelectHistoryItem(_ item: HistoryItem) {
        // 将选中的历史记录导回主界面
        // 这里需要解析表达式并重新计算
        // 简单实现：直接显示结果
        display.text = item.result
        sequence.text = item.expression
        autoScaleLabel(display)
        autoScaleLabel(sequence)
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

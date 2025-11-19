//
//  CalculatorBrain.swift
//  Calculator
//
//  Created by Andrea Vultaggio on 17/10/2017.
//  Copyright © 2017 Andrea Vultaggio. All rights reserved.
//

import Foundation

struct CalculatorBrain {
    
    //MARK: Variables
    
    private var accumulator: Double?
    private var pendingBinaryOperation: PendingBinaryOperation?
    private var resultIsPending = false
    
    var description = ""
    var result: Double? { get { return accumulator } }
    
    //MARK: Enumerations
    
    private enum Operation {
        case constant(Double)
        case unaryOperation((Double) -> Double, String)
        case binaryOperation((Double, Double) -> Double, Int)
        case result
    }
    
    // 运算符优先级: 0=最低, 1=加减, 2=乘除, 3=幂运算
    private var operations: Dictionary<String, Operation> = [
        "＋" : .binaryOperation({ $0 + $1 }, 1),
        "﹣" : .binaryOperation({ $0 - $1 }, 1),
         "×" : .binaryOperation({ $0 * $1 }, 2),
         "÷" : .binaryOperation({ $0 / $1 }, 2),
         "^" : .binaryOperation({ pow($0, $1) }, 3),
         "√" : .unaryOperation({ sqrt($0) }, "√"),
         "sin" : .unaryOperation({ sin($0) }, "sin"),
         "cos" : .unaryOperation({ cos($0) }, "cos"),
         "tan" : .unaryOperation({ tan($0) }, "tan"),
         "log" : .unaryOperation({ log10($0) }, "log"),
         "ln" : .unaryOperation({ log($0) }, "ln"),
         "±" : .unaryOperation({ -$0 }, "±"),
         "﹪" : .unaryOperation({ $0 / 100 }, "﹪"),
         "AC": .constant(0),
         "=" : .result
    ]
    
    //MARK: Embedded struct

    private struct PendingBinaryOperation {
        let function: (Double, Double) -> Double
        let firstOperand: Double
        let precedence: Int
        let operationString: String
        
        func perform(with secondOperand: Double) -> Double {
            return function(firstOperand, secondOperand)
        }
    }
    
    //MARK: Functions
    
    private mutating func performPendingBinaryOperation() {
        if pendingBinaryOperation != nil && accumulator != nil {
            accumulator = pendingBinaryOperation?.perform(with: accumulator!)
            pendingBinaryOperation = nil
            resultIsPending = false
        }
    }
    
    mutating func performOperation(_ symbol: String) {
        if let operation = operations[symbol] {
            switch operation {
                case .constant(let value):
                    accumulator = value
                    description = ""
                case .unaryOperation(let function, let opString):
                    if accumulator != nil {
                        let value = String(describing: accumulator!).removeAfterPointIfZero()
                        description = opString + "(" + value + ")"
                        accumulator = function(accumulator!)
                    }
                case .binaryOperation(let function, let precedence):
                    if pendingBinaryOperation != nil {
                        // 如果当前运算符优先级低于或等于待处理运算符，先执行待处理运算
                        if precedence <= pendingBinaryOperation!.precedence {
                            performPendingBinaryOperation()
                        }
                    }
                    
                    if accumulator != nil {
                        let operandStr = String(describing: accumulator!).removeAfterPointIfZero()
                        
                        if pendingBinaryOperation != nil {
                            // 更新表达式，添加当前运算符
                            description += symbol
                        } else {
                            // 新的运算开始
                            description = operandStr + symbol
                        }
                        
                        pendingBinaryOperation = PendingBinaryOperation(function: function, firstOperand: accumulator!, precedence: precedence, operationString: symbol)
                        resultIsPending = true
                        accumulator = nil
                    }
                case .result:
                    if accumulator != nil && pendingBinaryOperation != nil {
                        let secondOperandStr = String(describing: accumulator!).removeAfterPointIfZero()
                        description += secondOperandStr
                    }
                    
                    performPendingBinaryOperation()
                    
                    if result != nil {
                        description += "="
                    }
            }
        }
    }
    
    mutating func setOperand(_ operand: Double?) {
        accumulator = operand ?? 0.0
        if !resultIsPending {
            description = String(describing: operand!).removeAfterPointIfZero()
        } else {
            // 在结果等待状态下添加第二个操作数
            let operandStr = String(describing: operand!).removeAfterPointIfZero()
            description += operandStr
        }
    }
}

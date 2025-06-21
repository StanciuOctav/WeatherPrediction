//
//  ParametersSettingsView.swift
//  WeatherPrediction
//
//  Created by Octav Stanciu on 21.06.2025.
//

import SwiftUI

struct ParametersSettingsView: View {
    
    @Binding var params: RegressorParameters
    @Binding var typeOfRegressor: RegressorType
    
    var body: some View {
        VStack {
            switch typeOfRegressor {
            case .linear:
                linearView()
            case .randomForest:
                randomForestView()
            case .boostedTree:
                boostedView()
            case .decisionTree:
                decisionView()
            }
        }
        .padding()
    }
    
    private func linearView() -> some View {
        VStack {
            NumericInputField(title: "Max iterations - [1, -]", numberType: .int, lowerBound: 1.0, upperBound: nil, intValue: $params.maxIterations, doubleValue: .constant(0))
            NumericInputField(title: "L1 Penalty - [0, 1]", numberType: .double, lowerBound: 0.0, upperBound: 1.0, intValue: .constant(0), doubleValue: $params.l1Penalty)
            NumericInputField(title: "L2 Penaltymp - [0, 1]", numberType: .double, lowerBound: 0.01, upperBound: 1.0, intValue: .constant(0), doubleValue: $params.l2Penalty)
            NumericInputField(title: "Step size - [1, -]", numberType: .int, lowerBound: 1, upperBound: nil, intValue: .constant(0), doubleValue: $params.stepSize)
            NumericInputField(title: "Convergence Threshold - (0, 1)", numberType: .double, lowerBound: 0.001, upperBound: 0.999, intValue: .constant(0), doubleValue: $params.convergenceThreshold)
        }
    }
    private func randomForestView() -> some View {
        VStack {
            NumericInputField(title: "Max depth - [1, -]", numberType: .int, lowerBound: 1.0, upperBound: nil, intValue: $params.maxDepth, doubleValue: .constant(0))
            NumericInputField(title: "Max iterations - [1, -]", numberType: .int, lowerBound: 1.0, upperBound: nil, intValue: $params.maxIterations, doubleValue: .constant(0))
            NumericInputField(title: "Min Loss Reduction - [0.0, 1.0]", numberType: .double, lowerBound: 0.1, upperBound: 1.0, intValue: .constant(0), doubleValue: $params.minLossReduction)
            NumericInputField(title: "Min Child Weight - [0.1, 1.0]", numberType: .double, lowerBound: 0.1, upperBound: 1.0, intValue: .constant(0), doubleValue: $params.minChildWeight)
            NumericInputField(title: "Row subsample ratio - (0, 1)", numberType: .double, lowerBound: 0.001, upperBound: 0.999, intValue: .constant(0), doubleValue: $params.rowSubsampleRatio)
            NumericInputField(title: "Column subsample ratio - (0, 1)", numberType: .double, lowerBound: 0.001, upperBound: 0.999, intValue: .constant(0), doubleValue: $params.columnSubsampleRatio)
        }
    }
    private func boostedView() -> some View {
        VStack {
            NumericInputField(title: "Max depth - [1, -]", numberType: .int, lowerBound: 1.0, upperBound: nil, intValue: $params.maxDepth, doubleValue: .constant(0))
            NumericInputField(title: "Max iterations - [1, -]", numberType: .int, lowerBound: 1.0, upperBound: nil, intValue: $params.maxIterations, doubleValue: .constant(0))
            NumericInputField(title: "Min Loss Reduction - [0.0, 1.0]", numberType: .double, lowerBound: 0.1, upperBound: 1.0, intValue: .constant(0), doubleValue: $params.minLossReduction)
            NumericInputField(title: "Min Child Weight - [0.1, 1.0]", numberType: .double, lowerBound: 0.1, upperBound: 1.0, intValue: .constant(0), doubleValue: $params.minChildWeight)
            NumericInputField(title: "Step size - (0, 1)", numberType: .double, lowerBound: 0.001, upperBound: 0.999, intValue: .constant(0), doubleValue: $params.stepSize)
            NumericInputField(title: "Row subsample ratio - (0, 1)", numberType: .double, lowerBound: 0.001, upperBound: 0.999, intValue: .constant(0), doubleValue: $params.rowSubsampleRatio)
            NumericInputField(title: "Column subsample ratio - (0, 1)", numberType: .double, lowerBound: 0.001, upperBound: 0.999, intValue: .constant(0), doubleValue: $params.columnSubsampleRatio)
        }
    }
    private func decisionView() -> some View {
        VStack {
            NumericInputField(title: "Max depth - [1, -]", numberType: .int, lowerBound: 1.0, upperBound: nil, intValue: $params.maxDepth, doubleValue: .constant(0))
            NumericInputField(title: "Min Loss Reduction - [0.0, 1.0]", numberType: .double, lowerBound: 0.1, upperBound: 1.0, intValue: .constant(0), doubleValue: $params.minLossReduction)
            NumericInputField(title: "Min Child Weight - [0.1, 1.0]", numberType: .double, lowerBound: 0.1, upperBound: 1.0, intValue: .constant(0), doubleValue: $params.minChildWeight)
        }
    }
}

enum NumberType {
    case int
    case double
}

struct NumericInputField: View {
    let title: String
    let numberType: NumberType
    let lowerBound: Double?
    let upperBound: Double?
    
    @Binding var intValue: Int
    @Binding var doubleValue: Double
    @State private var inputText: String = ""

    var body: some View {
        VStack(alignment: .leading) {
            Text(title)
            
            TextField("Enter number", text: $inputText)
                .keyboardType(.decimalPad)
                .onChange(of: inputText) { _, newValue in
                    validateInput(newValue)
                }
                .textFieldStyle(RoundedBorderTextFieldStyle())
        }
        .onAppear {
            // Sync the initial value
            if numberType == .int {
                inputText = "\(intValue)"
            } else if numberType == .double {
                inputText = String(format: "%.2f", doubleValue)
            }
        }
    }

    private func validateInput(_ newValue: String) {
        // Allow valid numeric characters including "." (but only one!)
        let filtered = newValue.filter { "0123456789.".contains($0) }
        let dotCount = filtered.filter { $0 == "." }.count

        // Reject multiple dots
        if dotCount > 1 {
            return
        }

        switch numberType {
        case .int:
            // Don't allow dots in integer mode
            let cleaned = filtered.replacingOccurrences(of: ".", with: "")
            inputText = cleaned
            if let intVal = Int(cleaned) {
                if isValid(Double(intVal)) {
                    intValue = intVal
                }
            }

        case .double:
            inputText = filtered
            if let doubleVal = Double(filtered) {
                if isValid(doubleVal) {
                    doubleValue = doubleVal
                }
            }
        }
    }

    private func isValid(_ value: Double) -> Bool {
        if let lower = lowerBound, value < lower {
            return false
        }
        if let upper = upperBound, value > upper {
            return false
        }
        return true
    }
}

//
//  EvaluationMetric.swift
//  WeatherPrediction
//
//  Created by Octav Stanciu on 07.05.2025.
//

import Foundation

struct EvaluationMetric: Identifiable, CustomStringConvertible {
    var id = UUID()
    
    let target: String
    let mae: Double
    let mse: Double
    let rmse: Double
    let r2: Double
    
    var description: String {
        return "\(target),\(String(format: "%.2f", mae)),\(String(format: "%.2f", mse)),\(String(format: "%.2f", rmse)),\(String(format: "%.2f", r2))"
    }
}

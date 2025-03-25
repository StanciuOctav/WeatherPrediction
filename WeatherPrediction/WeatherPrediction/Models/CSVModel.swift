//
//  CSVModel.swift
//  WeatherPrediction
//
//  Created by Octav Stanciu on 16.03.2025.
//

import Foundation

struct CSVModel: Identifiable, Hashable {
    
    var id: String {
        UUID().uuidString
    }
    
    var latitude: Double
    var longitude: Double
    var time: Time?
    
    // OpenWeather data
    var omTemp: Double = 0
    var omFeelLike: Double = 0
    var omPrecipProb: Int = 0
    
    // WeatherAPI data
    var wTemp: Double = 0
    var wFeelLike: Double = 0
    var wPrecipProb: Int = 0
    
    // Predicted data
    var pTemp: Double = 0
    var pFeelLike: Double = 0
    var pPrecipProb: Double = 0
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}

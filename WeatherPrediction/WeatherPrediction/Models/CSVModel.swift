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
    var omTemp: Double = -100
    var omFeelLike: Double = -100
    var omPrecipProb: Int = -100
    
    // WeatherAPI data
    var wTemp: Double = -100
    var wFeelLike: Double = -100
    var wPrecipProb: Int = -100
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}

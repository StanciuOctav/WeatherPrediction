//
//  MLModel.swift
//  WeatherPrediction
//
//  Created by Octav Stanciu on 16.03.2025.
//

import Foundation

struct MLModel {
    var latitude: Double
    var longitude: Double
    
    // OpenWeather data
    var omTemp: [Time: Double] = [:]
    var omFeelLike: [Time: Double] = [:]
    var omPrecipProb: [Time: Int] = [:]
    
    // WeatherAPI data
    var wTemp: [Time: Double] = [:]
    var wFeelLike: [Time: Double] = [:]
    var wPrecipProb: [Time: Int] = [:]
}

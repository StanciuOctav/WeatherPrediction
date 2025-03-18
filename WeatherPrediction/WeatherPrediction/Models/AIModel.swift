//
//  AIModel.swift
//  WeatherPrediction
//
//  Created by Octav Stanciu on 16.03.2025.
//

import Foundation

struct MLModel {
    let latitude: Double
    let longitude: Double
    let time: Time
    
    // OpenWeather data
    let omTemp: Double
    let omFeelLike: Double
    let omPrecipProb: Double
    
    // WeatherAPI data
    let wTemp: Double
    let wFeelLike: Double
    let wPrecipProb: Double
}

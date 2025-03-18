//
//  NetworkProtocol.swift
//  WeatherPrediction
//
//  Created by Octav Stanciu on 09.03.2025.
//

import Foundation

protocol NetworkProtocol<T> {
    associatedtype T
    
    func fetchWeatherData(latitude: Double, longitude: Double) async -> T
}

//
//  WeatherAPINetworkManager.swift
//  WeatherPrediction
//
//  Created by Octav Stanciu on 18.03.2025.
//

import Alamofire
import Constants
import SwiftUI

@Observable
class WeatherAPINetworkManager: NetworkProtocol {
    
    func buildURL(latitude: Double, longitude: Double) -> String? {
        var components = URLComponents()
        components.scheme = Constants.urlScheme
        components.host = Constants.WeatherAPI.host
        components.path = Constants.WeatherAPI.path
        
        components.queryItems = [
            URLQueryItem(name: "key", value: "\(Constants.WeatherAPI.apiKey)"),
            URLQueryItem(name: "q", value: "\(latitude) \(longitude)"),
            URLQueryItem(name: "days", value: "14"),
            URLQueryItem(name: "aqi", value: "no"),
            URLQueryItem(name: "alerts", value: "no")
        ]
        
        return components.url?.absoluteString
    }
    
    func fetchWeatherData(latitude: Double, longitude: Double) async -> WeatherAPIModel? {
        guard let url = buildURL(latitude: 46.75, longitude: 23.57) else { return nil }
            
        do {
            return try await AF.request(url)
                .validate()
                .serializingDecodable(WeatherAPIModel.self)
                .value
        } catch {
            print("Failed to fetch weather data: \(error)")
            return nil
        }
    }
}
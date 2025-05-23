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
    typealias T = WeatherAPIModel?
    
    private enum WeatherAPIType {
        case history, forecast
    }
    
    private func buildURL(latitude: Double, longitude: Double, date: String, forecastType: WeatherAPIType) -> String? {
        var components = URLComponents()
        components.scheme = Constants.urlScheme
        components.host = Constants.WeatherAPI.host
        switch forecastType {
        case .history:
            components.path = Constants.WeatherAPI.historyPath
            components.queryItems = [
                URLQueryItem(name: "key", value: "\(Constants.WeatherAPI.apiKey)"),
                URLQueryItem(name: "q", value: "\(latitude) \(longitude)"),
                URLQueryItem(name: "dt", value: date)
            ]
        case .forecast:
            components.path = Constants.WeatherAPI.forecastPath
            components.queryItems = [
                URLQueryItem(name: "key", value: "\(Constants.WeatherAPI.apiKey)"),
                URLQueryItem(name: "q", value: "\(latitude) \(longitude)"),
                URLQueryItem(name: "days", value: "2"), // today and tomorrow
                URLQueryItem(name: "aqi", value: "no"),
                URLQueryItem(name: "alerts", value: "no")
            ]
        }
        
        return components.url?.absoluteString
    }
    
    func fetchWeatherData(latitude: Double, longitude: Double, selectedDay: DayPrediction) async -> T {
        
        var weatherData = WeatherAPIModel()
        
        var last7Days = selectedDay == .today ? Calendar.last7Days : Calendar.last7DaysAndToday + [Calendar.tomorrow]
        
        for date in last7Days {
            guard let url = buildURL(latitude: latitude, longitude: longitude, date: date, forecastType: .history) else { return nil }
            
            do {
                let value = try await AF.request(url)
                    .validate()
                    .serializingDecodable(WeatherAPIModel.self)
                    .value
                weatherData.location = value.location
                weatherData.forecast.forecastday.append(contentsOf: value.forecast.forecastday)
            } catch {
                print("Failed to fetch weather data - WeatherAPI - 1: \(error)")
                return nil
            }
        }
        
        guard let url = buildURL(latitude: latitude, longitude: longitude, date: Calendar.tomorrow, forecastType: .forecast) else { return weatherData }
        
        do {
            let value = try await AF.request(url)
                .validate()
                .serializingDecodable(WeatherAPIModel.self)
                .value
            weatherData.location = value.location
            weatherData.forecast.forecastday.append(contentsOf: value.forecast.forecastday)
        } catch {
            print("Failed to fetch weather data - WeatherAPI - 2: \(error)")
            return nil
        }
            
        return weatherData
    }
}

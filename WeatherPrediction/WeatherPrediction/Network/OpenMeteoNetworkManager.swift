//
//  OpenMeteoNetworkManager.swift
//  WeatherPrediction
//
//  Created by Octav Stanciu on 18.03.2025.
//

import Alamofire
import Constants
import Foundation

@Observable
class OpenMeteoNetworkManager: NetworkProtocol {
    typealias T = OpenMeteoModel?
    
    func buildURL(latitude: Double, longitude: Double, selectedDay: DayPrediction) -> String? {
        var components = URLComponents()
        components.scheme = Constants.urlScheme
        components.host = Constants.OpenMeteo.host
        components.path = Constants.OpenMeteo.path
        
        components.queryItems = [
            URLQueryItem(name: "latitude", value: "\(latitude)"),
            URLQueryItem(name: "longitude", value: "\(longitude)"),
            URLQueryItem(name: "hourly", value: Constants.OpenMeteo.hourly),
            URLQueryItem(name: "past_days", value: "7"),
            URLQueryItem(name: "forecast_days", value: selectedDay == .today ? "1" : "2") // today and tomorrow
        ]
        
        return components.url?.absoluteString
    }
    
    func fetchWeatherData(latitude: Double, longitude: Double, selectedDay: DayPrediction) async -> T {
    guard let url = buildURL(latitude: latitude, longitude: longitude, selectedDay: selectedDay) else { return nil }
        do {
            return try await AF.request(url)
                .validate()
                .serializingDecodable(OpenMeteoModel.self)
                .value
            }
        catch {
            print("Failed to fetch weather data in OpenMeteo: \(error)")
            return nil
        }
    }
}

//
//  ContentView.swift
//  WeatherPrediction
//
//  Created by Octav Stanciu on 03.02.2025.
//

import Alamofire
import Constants
import SwiftUI

@Observable
class OpenMeteoViewModel: NetworkProtocol {
    
    func buildURL(latitude: Double, longitude: Double) -> String? {
        var components = URLComponents()
        components.scheme = Constants.urlScheme
        components.host = Constants.OpenMeteo.host
        components.path = Constants.OpenMeteo.path
        
        components.queryItems = [
            URLQueryItem(name: "latitude", value: "\(latitude)"),
            URLQueryItem(name: "longitude", value: "\(longitude)"),
            URLQueryItem(name: "hourly", value: Constants.OpenMeteo.hourly),
            URLQueryItem(name: "forecast_days", value: "14")
        ]
        
        return components.url?.absoluteString
    }
    
    func fetchWeatherData(latitude: Double, longitude: Double) {
        if let url = buildURL(latitude: 46.75, longitude: 23.57) {
            AF.request(url).responseDecodable(of: OpenMeteoModel.self) { response in
                guard let result = response.value else { return }
                print("OpenMeteo: \(result.hourly.time.count)")
            }
        }
    }
}

@Observable
class WeatherAPIViewModel: NetworkProtocol {
    
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
    
    func fetchWeatherData(latitude: Double, longitude: Double) {
        if let url = buildURL(latitude: 46.75, longitude: 23.57) {
            AF.request(url).responseDecodable(of: WeatherAPIModel.self) { response in
                guard let result = response.value else { return }
                let totalData = result.forecast.forecastday.reduce(into: 0) { result, element in
                    result += element.hour.count
                }
                print("WeatherAPI: \(totalData)")
            }
        }
    }
}

struct ContentView: View {
    @State private var openVm = OpenMeteoViewModel()
    @State private var weatherVM = WeatherAPIViewModel()
    var body: some View {
        VStack {
            Text("Fetchiiiiing")
        }
        .onAppear {
            openVm.fetchWeatherData(latitude: 46.75, longitude: 23.57)
            weatherVM.fetchWeatherData(latitude: 46.75, longitude: 23.57)
        }
    }
}

#Preview {
    ContentView()
}

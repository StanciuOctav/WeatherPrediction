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
class OpenMeteoViewModel {
    
    func buildWeatherURL(latitude: Double, longitude: Double) -> String? {
        var components = URLComponents()
        components.scheme = "https"
        components.host = "api.open-meteo.com"
        components.path = "/v1/forecast"
        
        components.queryItems = [
            URLQueryItem(name: "latitude", value: "\(latitude)"),
            URLQueryItem(name: "longitude", value: "\(longitude)"),
            URLQueryItem(name: "hourly", value: "temperature_2m,apparent_temperature,precipitation,rain,showers")
        ]
        
        return components.url?.absoluteString
    }
    
    func fetch() {
        if let url = buildWeatherURL(latitude: 46.75, longitude: 23.57) {
            AF.request(url).responseDecodable(of: OpenMeteoModel.self) { response in
                guard let result = response.value else { return }
                print(result.hourly)
            }
        }
    }
}

struct ContentView: View {
    @State private var openVm = OpenMeteoViewModel()
    var body: some View {
        VStack {
            Text("Fetchiiiiing")
        }
        .onAppear {
            openVm.fetch()
        }
    }
}

#Preview {
    ContentView()
}

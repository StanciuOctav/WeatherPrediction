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
class ContentViewModel {
    
    let openNM: any NetworkProtocol
    let weatherNM: any NetworkProtocol
    
    init(openNM: any NetworkProtocol, weatherNM: any NetworkProtocol) {
        self.openNM = openNM
        self.weatherNM = weatherNM
    }

    func fetchWeatherData(latitude: Double, longitude: Double) async {
        async let openModelCall = openNM.fetchWeatherData(latitude: latitude, longitude: longitude)
        async let weatherModelCall = weatherNM.fetchWeatherData(latitude: latitude, longitude: longitude)
        
        let (openModel, weatherModel) = await (openModelCall, weatherModelCall)
        
        guard let openModel = openModel as? OpenMeteoModel,
              let weatherModel = weatherModel as? WeatherAPIModel else { return }
    }
    
}

struct ContentView: View {
    @State private var vm: ContentViewModel
    
    init() {
        self.vm = ContentViewModel(openNM: OpenMeteoNetworkManager(), weatherNM: WeatherAPINetworkManager())
    }
    
    var body: some View {
        VStack {
            Text("Fetchiiiiing")
        }
        .task {
            await vm.fetchWeatherData(latitude: 46.75, longitude: 23.57)
        }
    }
}

#Preview {
    ContentView()
}

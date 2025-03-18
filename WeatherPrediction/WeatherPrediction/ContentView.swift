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
    
    @ObservationIgnored private let openNM: any NetworkProtocol
    @ObservationIgnored private let weatherNM: any NetworkProtocol
    @ObservationIgnored private var mlModel: MLModel
    
    init(openNM: any NetworkProtocol, weatherNM: any NetworkProtocol) {
        self.openNM = openNM
        self.weatherNM = weatherNM
        self.mlModel = MLModel(latitude: 46.75, longitude: 23.57)
    }

    func fetchWeatherData() async {
        async let openModelCall = openNM.fetchWeatherData(latitude: mlModel.latitude, longitude: mlModel.longitude)
        async let weatherModelCall = weatherNM.fetchWeatherData(latitude: mlModel.latitude, longitude: mlModel.longitude)
        
        let (openModel, weatherModel) = await (openModelCall, weatherModelCall)
        
        guard let openModel = openModel as? OpenMeteoModel,
              let weatherModel = weatherModel as? WeatherAPIModel else { return }
        
        buildMLModel(openModel: openModel, weatherModel: weatherModel)
    }
    
    func buildMLModel(openModel: OpenMeteoModel, weatherModel: WeatherAPIModel) {
        for i in 0..<openModel.hourly.time.count {
            let currentTime = openModel.hourly.time[i]
            mlModel.omTemp[currentTime] = openModel.hourly.temp[i]
            mlModel.omFeelLike[currentTime] = openModel.hourly.feelLikeTemp[i]
            mlModel.omPrecipProb[currentTime] = openModel.hourly.precipProb[i]
        }
        
        for forecastDay in weatherModel.forecast.forecastday {
            for hour in forecastDay.hour {
                mlModel.wTemp[hour.time] = hour.temp
                mlModel.wFeelLike[hour.time] = hour.feelLikeTemp
                mlModel.wPrecipProb[hour.time] = hour.precipProb
            }
        }
        
        print(mlModel.omTemp.count)
        print(mlModel.wTemp.count)
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
            await vm.fetchWeatherData()
        }
    }
}

#Preview {
    ContentView()
}

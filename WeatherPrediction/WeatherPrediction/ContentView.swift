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
        async let openModelCall = openNM.fetchWeatherData(latitude: mlModel.latitude, longitude: mlModel.longitude, forDates: [])
        async let weatherModelCall = weatherNM.fetchWeatherData(latitude: mlModel.latitude, longitude: mlModel.longitude, forDates: Calendar.last14Days + [Calendar.tomorrow])
        
        let (openModel, weatherModel) = await (openModelCall, weatherModelCall)
        
        guard let openModel = openModel as? OpenMeteoModel,
              let weatherModel = weatherModel as? WeatherAPIModel else { return }
        
        print("OpenModel: \(openModel.hourly.time.last!)")
        print("Weather: \(weatherModel.forecast.forecastday.count)")
        
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
                mlModel.time.append(hour.time)
            }
        }
        
        mlModel.time.sort { $0 < $1 }
        
        exportToCSV()
    }
    
    func exportToCSV() {
        var csvString = "Time,Latitude,Longitude,omTemp,omFeelLike,omPrecipProb,wTemp,wFeelLike,wPrecipProb\n"

        // Iterate through all unique Time values
        for time in mlModel.time {
            let timeString = "\(time.year)-\(time.month)-\(time.day) \(time.hour):00"

            let omTemp = mlModel.omTemp[time] ?? Double.nan
            let omFeelLike = mlModel.omFeelLike[time] ?? Double.nan
            let omPrecipProb = mlModel.omPrecipProb[time] ?? -1

            let wTemp = mlModel.wTemp[time] ?? Double.nan
            let wFeelLike = mlModel.wFeelLike[time] ?? Double.nan
            let wPrecipProb = mlModel.wPrecipProb[time] ?? -1

            let row = "\(timeString),\(mlModel.latitude),\(mlModel.longitude),\(omTemp),\(omFeelLike),\(omPrecipProb),\(wTemp),\(wFeelLike),\(wPrecipProb)\n"
            csvString.append(row)
        }

        // Get the file path for the CSV file
        let fileURL = FileManager.default.temporaryDirectory.appendingPathComponent("ModelData.csv")

        do {
            try csvString.write(to: fileURL, atomically: true, encoding: .utf8)
            print("CSV file saved at: \(fileURL.path)")
        } catch {
            print("Failed to save CSV: \(error)")
        }
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
            Task.detached(priority: .background, operation: {
                await vm.fetchWeatherData()
            })
        }
    }
}

#Preview {
    ContentView()
}

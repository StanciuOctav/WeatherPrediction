//
//  ContentView.swift
//  WeatherPrediction
//
//  Created by Octav Stanciu on 03.02.2025.
//

import Alamofire
import Constants
import CoreML
import CreateML
import SwiftUI
import TabularData

@Observable
class ContentViewModel {
    
    @ObservationIgnored private let openNM: any NetworkProtocol
    @ObservationIgnored private let weatherNM: any NetworkProtocol
    @ObservationIgnored private var mlModel: CSVModel
    
    init(openNM: any NetworkProtocol, weatherNM: any NetworkProtocol) {
        self.openNM = openNM
        self.weatherNM = weatherNM
        self.mlModel = CSVModel(latitude: 46.75, longitude: 23.57)
    }
    
    func fetchWeatherData() async {
        async let openModelCall = openNM.fetchWeatherData(latitude: mlModel.latitude, longitude: mlModel.longitude, forDates: [])
        async let weatherModelCall = weatherNM.fetchWeatherData(latitude: mlModel.latitude, longitude: mlModel.longitude, forDates: Calendar.last14Days + [Calendar.tomorrow])
        
        let (openModel, weatherModel) = await (openModelCall, weatherModelCall)
        
        guard let openModel = openModel as? OpenMeteoModel,
              let weatherModel = weatherModel as? WeatherAPIModel else { return }
        
        //        print("OpenModel: \(openModel.hourly.time.count)")
        //        print("WeatherAPI: \(weatherModel.forecast.forecastday.count * weatherModel.forecast.forecastday.first!.hour.count)")
        // Uncomment this when we want the latest data in order to use it to train new models
        buildCSVModel(openModel: openModel, weatherModel: weatherModel)
    }
    
    func buildCSVModel(openModel: OpenMeteoModel, weatherModel: WeatherAPIModel) {
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
        var csvString = "Time,Latitude,Longitude,omTemp,omFeelLike,omPrecipProb,wTemp,wFeelLike,wPrecipProb,TEMPERATURE,FEELING,PRECIPITATION\n"
        
        for time in mlModel.time {
            let timeString = "\(time.year)-\(time.month)-\(time.day) \(time.hour):00"
            
            let omTemp = mlModel.omTemp[time] ?? Double.nan
            let omFeelLike = mlModel.omFeelLike[time] ?? Double.nan
            let omPrecipProb = mlModel.omPrecipProb[time] ?? -1
            
            let wTemp = mlModel.wTemp[time] ?? Double.nan
            let wFeelLike = mlModel.wFeelLike[time] ?? Double.nan
            let wPrecipProb = mlModel.wPrecipProb[time] ?? -1
            
            let row = "\(timeString),\(mlModel.latitude),\(mlModel.longitude),\(omTemp),\(omFeelLike),\(omPrecipProb),\(wTemp),\(wFeelLike),\(wPrecipProb),\((omTemp+wTemp)/2),\((omFeelLike+wFeelLike)/2),\((omPrecipProb+wPrecipProb)/2)\n"
            csvString.append(row)
        }
        
        let fileURL = FileManager.default.temporaryDirectory.appendingPathComponent("ModelData.csv")
        
        do {
            try csvString.write(to: fileURL, atomically: true, encoding: .utf8)
            print("CSV file saved at: \(fileURL.path)")
            trainAndPredictWeatherMetrics() // (todayTemp: 10, columnName: "wTemp")
        } catch {
            print("Failed to save CSV: \(error)")
        }
    }
    
    func trainAndPredictWeatherMetrics() {
        let fileURL = FileManager.default.temporaryDirectory.appendingPathComponent("ModelData.csv")

            Task {
                do {
                    let dataframe = try DataFrame(contentsOfCSVFile: fileURL)

                    // Parse and filter rows for tomorrow
                    let dateFormatter = DateFormatter()
                    dateFormatter.dateFormat = "yyyy-MM-dd HH:mm"

                    let calendar = Calendar.current
                    let today = calendar.startOfDay(for: Date())
                    guard let tomorrow = calendar.date(byAdding: .day, value: 1, to: today) else { return }

                    var hourlyRowsForTomorrow: [(date: Date, row: DataFrame.Row)] = []

                    for row in dataframe.rows {
                        if let timeString = row["Time"] as? String,
                           let date = dateFormatter.date(from: timeString),
                           calendar.isDate(date, inSameDayAs: tomorrow) {
                            hourlyRowsForTomorrow.append((date, row))
                        }
                    }

                    if hourlyRowsForTomorrow.isEmpty {
                        print("⚠️ No data found for tomorrow.")
                        return
                    }

                    // Define targets and their feature columns
                    let predictionTasks: [(target: String, features: [String])] = [
                        ("TEMPERATURE", ["omTemp", "wTemp"]),
                        ("FEELING", ["omFeelLike", "wFeelLike"]),
                        ("PRECIPITATION", ["omPrecipProb", "wPrecipProb"])
                    ]

                    for (target, features) in predictionTasks {
                        // Filter relevant columns
                        let allColumns = features + [target]
                        let filteredData = dataframe[allColumns]

                        // Train model
                        let regressor = try MLBoostedTreeRegressor(trainingData: filteredData, targetColumn: target)

                        // Save and compile model
                        let modelURL = FileManager.default.temporaryDirectory.appendingPathComponent("\(target).mlmodel")
                        try regressor.write(to: modelURL)
                        let compiledURL = try MLModel.compileModel(at: modelURL)
                        let model = try MLModel(contentsOf: compiledURL)

                        print("\n🔮 Predicting \(target.uppercased()) for each hour of tomorrow:")

                        for (date, row) in hourlyRowsForTomorrow {
                            var inputDict: [String: MLFeatureValue] = [:]

                            for feature in features {
                                if let value = row[feature] {
                                    if let doubleValue = value as? Double {
                                        inputDict[feature] = MLFeatureValue(double: doubleValue)
                                    } else if let intValue = value as? Int {
                                        inputDict[feature] = MLFeatureValue(int64: Int64(intValue))
                                    } else if let stringValue = value as? String {
                                        inputDict[feature] = MLFeatureValue(string: stringValue)
                                    }
                                }
                            }

                            let inputProvider = try MLDictionaryFeatureProvider(dictionary: inputDict)
                            let prediction = try model.prediction(from: inputProvider)

                            if let result = prediction.featureValue(for: target)?.doubleValue {
                                let hourString = DateFormatter.localizedString(from: date, dateStyle: .none, timeStyle: .short)
                                print("⏰ \(hourString): \(result)")
                            }
                        }
                    }

                } catch {
                    print("❌ Error: \(error)")
                }
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

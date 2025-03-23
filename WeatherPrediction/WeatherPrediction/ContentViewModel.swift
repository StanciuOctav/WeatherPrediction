//
//  ContentViewModel.swift
//  WeatherPrediction
//
//  Created by Octav Stanciu on 23.03.2025.
//

import Alamofire
import Constants
import CoreML
#if canImport(CreateML)
import CreateML
#endif
import SwiftUI
import TabularData

@Observable
class ContentViewModel {
    
    @ObservationIgnored private let openNM: any NetworkProtocol
    @ObservationIgnored private let weatherNM: any NetworkProtocol
    var mlModel: [CSVModel]
    
    init(openNM: any NetworkProtocol, weatherNM: any NetworkProtocol) {
        self.openNM = openNM
        self.weatherNM = weatherNM
        self.mlModel = [] // CSVModel(latitude: 46.75, longitude: 23.57)
    }
    
    func fetchWeatherData() async {
        async let openModelCall = openNM.fetchWeatherData(latitude: 46.75, longitude: 23.57, forDates: [])
        async let weatherModelCall = weatherNM.fetchWeatherData(latitude: 46.75, longitude: 23.57, forDates: Calendar.last14Days + [Calendar.tomorrow])
        
        let (openModel, weatherModel) = await (openModelCall, weatherModelCall)
        
        guard let openModel = openModel as? OpenMeteoModel,
              let weatherModel = weatherModel as? WeatherAPIModel else { return }
        
        //        print("OpenModel: \(openModel.hourly.time.count)")
        //        print("WeatherAPI: \(weatherModel.forecast.forecastday.count * weatherModel.forecast.forecastday.first!.hour.count)")
        // Uncomment this when we want the latest data in order to use it to train new models
        Task { @MainActor [weak self] in
            guard let self else { return }
            buildCSVModel(openModel: openModel, weatherModel: weatherModel)
        }
    }
    
    func buildCSVModel(openModel: OpenMeteoModel, weatherModel: WeatherAPIModel) {
        for i in 0..<openModel.hourly.time.count {
            let currentTime = openModel.hourly.time[i]
            mlModel.append(CSVModel(latitude: 46.75, longitude: 23.57, time: currentTime, omTemp: openModel.hourly.temp[i], omFeelLike: openModel.hourly.feelLikeTemp[i], omPrecipProb: openModel.hourly.precipProb[i]))
        }
        
        for forecastDay in weatherModel.forecast.forecastday {
            for hour in forecastDay.hour {
                if let index = mlModel.firstIndex(where: { $0.time == hour.time }) {
                    mlModel[index].wTemp = hour.temp
                    mlModel[index].wFeelLike = hour.feelLikeTemp
                    mlModel[index].wPrecipProb = hour.precipProb
                }
            }
        }
        
        mlModel.sort(by: {
            guard let t1 = $0.time, let t2 = $1.time else {
                print("DEBUG -- PROBLEMO")
                return false }
            return t1 < t2
        })
        
        exportToCSV()
    }
    
    func exportToCSV() {
        var csvString = "Time,Latitude,Longitude,omTemp,omFeelLike,omPrecipProb,wTemp,wFeelLike,wPrecipProb,TEMPERATURE,FEELING,PRECIPITATION\n"
        
        for model in mlModel {
            guard let time = model.time else { continue }
            let timeString = "\(time.year)-\(time.month)-\(time.day) \(time.hour):00"
            
            let omTemp = model.omTemp
            let omFeelLike = model.omFeelLike
            let omPrecipProb = model.omPrecipProb
            
            let wTemp = model.wTemp
            let wFeelLike = model.wFeelLike
            let wPrecipProb = model.wPrecipProb
            
            let row = "\(timeString),\(model.latitude),\(model.longitude),\(omTemp),\(omFeelLike),\(omPrecipProb),\(wTemp),\(wFeelLike),\(wPrecipProb),\((omTemp+wTemp)/2),\((omFeelLike+wFeelLike)/2),\((omPrecipProb+wPrecipProb)/2)\n"
            csvString.append(row)
        }
        
        let fileURL = FileManager.default.temporaryDirectory.appendingPathComponent("ModelData.csv")
        
        do {
            try csvString.write(to: fileURL, atomically: true, encoding: .utf8)
            print("CSV file saved at: \(fileURL.path)")
#if canImport(CreateML)
            trainAndPredictWeatherMetrics() // (todayTemp: 10, columnName: "wTemp")
#endif
        } catch {
            print("Failed to save CSV: \(error)")
        }
    }
    
#if canImport(CreateML)
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
#endif
}

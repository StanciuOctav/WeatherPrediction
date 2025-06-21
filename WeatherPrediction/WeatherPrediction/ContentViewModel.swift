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

enum RegressorType: Identifiable, CaseIterable {
    var id: String { UUID().uuidString }
    
    case linear, randomForest, boostedTree, decisionTree
    
    var description: String {
        switch self {
        case .linear:
            return "Linear Regression"
        case .randomForest:
            return "Random Forest Regression"
        case .boostedTree:
            return "Boosting Tree Regression"
        case .decisionTree:
            return "Decision Tree Regression"
        }
    }
}

enum DayPrediction: Identifiable, CaseIterable {
    var id: String { UUID().uuidString }
    
    case today, tomorrow
    
    var description: String {
        switch self {
        case .today:
            return "Today"
        case .tomorrow:
            return "Tomorrow"
        }
    }
}

struct RegressorParameters {
    /// [1, -]
    var maxIterations: Int = 10
    /// [1, -]
    var maxDepth: Int = 6
    /// [0.0, 1.0]
    var minLossReduction: Double = 0.0
    /// [0.1, 1.0]
    var minChildWeight: Double = 0.1
    /// (0, 1)
    var rowSubsampleRatio: Double = 0.8
    /// (0, 1)
    var columnSubsampleRatio: Double = 0.8
    /// (0, 1)
    var stepSize: Double = 0.3
    /// [0, 1]
    var l1Penalty: Double = 0.0
    /// [0, 1]
    var l2Penalty: Double = 0.01
    /// (0, 1)
    var convergenceThreshold: Double = 0.01
}

@Observable
class ContentViewModel {
    
    @ObservationIgnored private let openNM: any NetworkProtocol
    @ObservationIgnored private let weatherNM: any NetworkProtocol
    
    var regressorType: RegressorType = .linear
    var regressorParameters = RegressorParameters()
    var selectedDay: DayPrediction = .today
    var mlModel: [SkyCastModel] = []
    var predictedSkyCastModels: [SkyCastModel] = []
    var evaluationMetrics: [EvaluationMetric] = []
    var predictedCSVString: String = "Target,MAE,MSE,RMSE,R2\n"
    
    init(openNM: any NetworkProtocol, weatherNM: any NetworkProtocol) {
        self.openNM = openNM
        self.weatherNM = weatherNM
    }
    
    func clearPredictedData() {
        predictedSkyCastModels = []
        evaluationMetrics = []
        predictedCSVString = "Target,MAE,MSE,RMSE,R2\n"
    }
    
    func clearAllData() {
        clearPredictedData()
        mlModel = []
    }
    
    func fetchWeatherData() async {
        async let openModelCall = openNM.fetchWeatherData(latitude: Constants.latitude,
                                                          longitude: Constants.longitude,
                                                          selectedDay: selectedDay)
        async let weatherModelCall = weatherNM.fetchWeatherData(latitude: Constants.latitude,
                                                                longitude: Constants.longitude,
                                                                selectedDay: selectedDay)
        
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
    
    private func buildCSVModel(openModel: OpenMeteoModel, weatherModel: WeatherAPIModel) {
        for i in 0..<openModel.hourly.time.count {
            let currentTime = openModel.hourly.time[i]
            mlModel.append(SkyCastModel(latitude: Constants.latitude,
                                        longitude: Constants.longitude,
                                        time: currentTime,
                                        omTemp: openModel.hourly.temp[i],
                                        omFeelLike: openModel.hourly.feelLikeTemp[i],
                                        omPrecipProb: openModel.hourly.precipProb[i]))
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
            guard let t1 = $0.time, let t2 = $1.time else { return false }
            return t1 < t2
        })
        
        exportToCSV()
    }
    
    private func exportToCSV() {
        var csvString = "Time,Latitude,Longitude,omTemp,omFeelLike,omPrecipProb,wTemp,wFeelLike,wPrecipProb,TEMPERATURE,FEELING,PRECIPITATION\n"
        
        for model in mlModel {
            guard let time = model.time else { continue }
            let timeString = "\(time.year)-\(time.month)-\(time.day) \(time.hour):00"
            
            let omTemp = model.omTemp
            let omFeelLike = model.omFeelLike
            let omPrecipProb = Double(model.omPrecipProb)
            
            let wTemp = model.wTemp
            let wFeelLike = model.wFeelLike
            let wPrecipProb = Double(model.wPrecipProb)
            
            let row = "\(timeString),\(model.latitude),\(model.longitude),\(omTemp),\(omFeelLike),\(omPrecipProb),\(wTemp),\(wFeelLike),\(wPrecipProb),\((omTemp+wTemp)/2),\((omFeelLike+wFeelLike)/2),\((omPrecipProb+wPrecipProb)/2)\n"
            csvString.append(row)
        }
        
        let fileURL = FileManager.default.temporaryDirectory.appendingPathComponent("ModelData.csv")
        
        do {
            try csvString.write(to: fileURL, atomically: true, encoding: .utf8)
            print("CSV file saved at: \(fileURL.path)")
#if canImport(CreateML)
            trainAndPredict()
#endif
        } catch {
            print("Failed to save CSV: \(error)")
        }
    }
    
#if canImport(CreateML)
    func trainAndPredict() {
        let fileURL = FileManager.default.temporaryDirectory.appendingPathComponent("ModelData.csv")
        
        Task { [weak self] in
            guard let self else { return }
            do {
                let dataframe = try DataFrame(contentsOfCSVFile: fileURL)
                
                let dateFormatter = DateFormatter()
                dateFormatter.dateFormat = "yyyy-MM-dd HH:mm"
                
                var hourlyRowsForTomorrow: [(date: Date, row: DataFrame.Row)] = []
                
                for row in dataframe.rows {
                    if let timeString = row["Time"] as? String,
                       let date = dateFormatter.date(from: timeString),
                       Calendar.current.isDate(date, inSameDayAs: selectedDay == .today ? Calendar.todayDate : Calendar.tomorrowDate) {
                        hourlyRowsForTomorrow.append((date, row))
                    }
                }
                
                if hourlyRowsForTomorrow.isEmpty {
                    print("⚠️ No data found for tomorrow.")
                    return
                }
                
                let predictionTasks: [(target: String, features: [String], keyPath: WritableKeyPath<SkyCastModel, Double>)] = [
                    ("TEMPERATURE", ["omTemp", "wTemp"], \.pTemp),
                    ("FEELING", ["omFeelLike", "wFeelLike"], \.pFeelLike),
                    ("PRECIPITATION", ["omPrecipProb", "wPrecipProb"], \.pPrecipProb)
                ]
                
                for (target, features, keyPath) in predictionTasks {
                    let allColumns = features + [target]
                    let filteredData = dataframe[allColumns]
                    
                    let model: MLModel = try {
                        switch self.regressorType {
                        case .linear:
                            let regressor = try MLLinearRegressor(trainingData: filteredData,
                                                                  targetColumn: target,
                                                                  parameters: MLLinearRegressor.ModelParameters(maxIterations: self.regressorParameters.maxIterations,
                                                                                                                l1Penalty: self.regressorParameters.l1Penalty,
                                                                                                                l2Penalty: self.regressorParameters.l2Penalty,
                                                                                                                stepSize: self.regressorParameters.stepSize,
                                                                                                                convergenceThreshold: self.regressorParameters.convergenceThreshold))
                            let modelURL = FileManager.default.temporaryDirectory.appendingPathComponent("\(target).mlmodel")
                            try regressor.write(to: modelURL)
                            let compiledURL = try MLModel.compileModel(at: modelURL)
                            return try MLModel(contentsOf: compiledURL)
                        case .randomForest:
                            let regressor = try MLRandomForestRegressor(trainingData: filteredData,
                                                                        targetColumn: target,
                                                                        parameters: MLRandomForestRegressor.ModelParameters(maxDepth: self.regressorParameters.maxDepth,
                                                                                                                            maxIterations: self.regressorParameters.maxIterations,
                                                                                                                            minLossReduction: self.regressorParameters.minLossReduction,
                                                                                                                            minChildWeight: self.regressorParameters.minChildWeight,
                                                                                                                            rowSubsample: self.regressorParameters.rowSubsampleRatio,
                                                                                                                            columnSubsample: self.regressorParameters.columnSubsampleRatio))
                            let modelURL = FileManager.default.temporaryDirectory.appendingPathComponent("\(target).mlmodel")
                            try regressor.write(to: modelURL)
                            let compiledURL = try MLModel.compileModel(at: modelURL)
                            return try MLModel(contentsOf: compiledURL)
                        case .boostedTree:
                            let regressor = try MLBoostedTreeRegressor(trainingData: filteredData,
                                                                       targetColumn: target,
                                                                       parameters: MLBoostedTreeRegressor.ModelParameters(maxDepth: self.regressorParameters.maxDepth,
                                                                                                                          maxIterations: self.regressorParameters.maxIterations,
                                                                                                                          minLossReduction: self.regressorParameters.minLossReduction,
                                                                                                                          minChildWeight: self.regressorParameters.minChildWeight,
                                                                                                                          stepSize: self.regressorParameters.stepSize,
                                                                                                                          rowSubsample: self.regressorParameters.rowSubsampleRatio,
                                                                                                                          columnSubsample: self.regressorParameters.columnSubsampleRatio))
                            let modelURL = FileManager.default.temporaryDirectory.appendingPathComponent("\(target).mlmodel")
                            try regressor.write(to: modelURL)
                            let compiledURL = try MLModel.compileModel(at: modelURL)
                            return try MLModel(contentsOf: compiledURL)
                        case .decisionTree:
                            let regressor = try MLDecisionTreeRegressor(trainingData: filteredData,
                                                                        targetColumn: target,
                                                                        parameters: MLDecisionTreeRegressor.ModelParameters(maxDepth: self.regressorParameters.maxDepth,
                                                                                                                            minLossReduction: self.regressorParameters.minLossReduction,
                                                                                                                            minChildWeight: self.regressorParameters.minChildWeight))
                            let modelURL = FileManager.default.temporaryDirectory.appendingPathComponent("\(target).mlmodel")
                            try regressor.write(to: modelURL)
                            let compiledURL = try MLModel.compileModel(at: modelURL)
                            return try MLModel(contentsOf: compiledURL)
                        }
                    }()
                    
                    print("\n🔮 Predicting \(target.uppercased()) for each hour of tomorrow:")
                    
                    var actualValues: [Double] = []
                    var predictedValues: [Double] = []
                    
                    for (date, row) in hourlyRowsForTomorrow {
                        var inputDict: [String: MLFeatureValue] = [:]
                        
                        for feature in features {
                            if let value = row[feature] as? Double {
                                inputDict[feature] = MLFeatureValue(double: value)
                            }
                            if let value = row[feature] as? Int {
                                inputDict[feature] = MLFeatureValue(int64: Int64(value))
                            }
                        }
                        
                        let inputProvider = try MLDictionaryFeatureProvider(dictionary: inputDict)
                        let prediction = try model.prediction(from: inputProvider)
                        
                        if let predictedValue = prediction.featureValue(for: target)?.doubleValue,
                           let actualValue = row[target] as? Double {
                            
                            actualValues.append(actualValue)
                            predictedValues.append(predictedValue)
                            
                            let components = Calendar.current.dateComponents([.year, .month, .day, .hour], from: date)
                            let hour = components.hour ?? 0
                            
                            if let index = predictedSkyCastModels.firstIndex(where: { $0.time?.hour == hour }) {
                                predictedSkyCastModels[index][keyPath: keyPath] = predictedValue
                            } else {
                                predictedSkyCastModels.append(SkyCastModel(
                                    latitude: 0.0,
                                    longitude: 0.0,
                                    time: Time(year: components.year ?? 0,
                                               month: components.month ?? 0,
                                               day: components.day ?? 0,
                                               hour: hour),
                                    pTemp: 0,
                                    pFeelLike: 0,
                                    pPrecipProb: 0
                                ))
                                predictedSkyCastModels[predictedSkyCastModels.count - 1][keyPath: keyPath] = predictedValue
                            }
                            
                            let hourString = DateFormatter.localizedString(from: date, dateStyle: .none, timeStyle: .short)
                            print("⏰ \(hourString): \(Int(predictedValue)) (Actual: \(actualValue))")
                        }
                    }
                    
//                    // Precipitation is the only type out of the three that has the most 0 values all the time
//                    if target == "PRECIPITATION" {
//                        // Filter out zero actuals
//                        let filteredPairs = zip(actualValues, predictedValues).filter { Int($0.0) != 0 }
//                        let actualNonZero = filteredPairs.map { $0.0 }
//                        let predictedNonZero = filteredPairs.map { $0.1 }
//                        
//                        if actualNonZero.isEmpty {
//                            print("⚠️ No valid data to compute accuracy metrics for \(target).")
//                            return
//                        }
//                        print("📊 Skipping 0 values (only non-zero precipitation cases)...")
//                        computeAccuracyMetrics(actualValues: actualNonZero, predictedValues: predictedNonZero, target: target + " (non-zero only)")
//                    } else {
                        computeAccuracyMetrics(actualValues: actualValues, predictedValues: predictedValues, target: target)
//                    }
                }
                exportPredictedCSV()
            } catch {
                print("❌ Error: \(error)")
            }
        }
    }
    
    func computeAccuracyMetrics(actualValues: [Double], predictedValues: [Double], target: String) {
        let n = Double(actualValues.count)
        
        let mae = zip(actualValues, predictedValues).map { abs($0 - $1) }.reduce(0, +) / n
        let mse = zip(actualValues, predictedValues).map { pow($0 - $1, 2) }.reduce(0, +) / n
        let rmse = sqrt(mse)
        
        let meanActual = actualValues.reduce(0, +) / n
        let ssTotal = actualValues.map { pow($0 - meanActual, 2) }.reduce(0, +)
        let ssResidual = zip(actualValues, predictedValues).map { pow($0 - $1, 2) }.reduce(0, +)
        let r2 = 1 - (ssResidual / ssTotal)

        print("""
        📊 Model Accuracy for \(target):
        🔹 MAE: \(String(format: "%.2f", mae))
        🔹 MSE: \(String(format: "%.2f", mse))
        🔹 RMSE: \(String(format: "%.2f", rmse))
        🔹 R² Score: \(String(format: "%.2f", r2))
        """)
        
        let evMetric = EvaluationMetric(target: target, mae: mae, mse: mse, rmse: rmse, r2: r2)
        evaluationMetrics.append(evMetric)
        predictedCSVString.append("\(evMetric.description)\n")
    }
    
    private func exportPredictedCSV() {
        predictedCSVString.append("Time,Temperature,Feels Like,Precipitation\n")
        
        for pred in predictedSkyCastModels {
            let row = "\(pred.time?.description ?? "N/A"),\(String(format: "%.1f", pred.pTemp)),\(String(format: "%.1f", pred.pFeelLike)),\(Int(pred.pPrecipProb))%\n"
            predictedCSVString.append(row)
        }
        
        let fileURL = FileManager.default.temporaryDirectory.appendingPathComponent("Predictions.csv")
        
        do {
            try predictedCSVString.write(to: fileURL, atomically: true, encoding: .utf8)
            print("CSV file saved at: \(fileURL.path)")
        } catch {
            print("Failed to save CSV: \(error)")
        }
    }
#endif
}

//
//  ContentView.swift
//  WeatherPrediction
//
//  Created by Octav Stanciu on 03.02.2025.
//

import SwiftUI

fileprivate enum PickerSection {
    case openMeteo, weatherAPI, prediction
}

struct ContentView: View {
    @State private var vm = ContentViewModel(openNM: OpenMeteoNetworkManager(), weatherNM: WeatherAPINetworkManager())
    @State private var selectedSection: PickerSection = .prediction
    
    var body: some View {
        NavigationStack {
            Form {
                Section {
                    Text("Evaluation metrics").font(.title)
                    ForEach(vm.evaluationMetrics) { metric in
                        HStack(alignment: .center) {
                            Text("\(metric.target)").font(.subheadline)
                            Text(String(format: "MAE %.2f", metric.mae))
                            Text(String(format: "MSE %.2f", metric.mse))
                            Text(String(format: "RMSE %.2f", metric.rmse))
                            Text(String(format: "R^2 %.2f", metric.r2))
                        }
                    }
                }
                Section {
                    VStack {
                        Picker(selection: $selectedSection, content: {
                            Text("Predicted").tag(PickerSection.prediction)
                            Text("OpenMeteo").tag(PickerSection.openMeteo)
                            Text("WeatherAPI").tag(PickerSection.weatherAPI)
                        }, label: {
                            Text("Choose data source")
                        })
                        .pickerStyle(.segmented)
                        
                        if selectedSection == .openMeteo || selectedSection == .weatherAPI {
                            List(vm.mlModel, id:\.id) { model in
                                VStack(alignment: .leading) {
                                    HStack {
                                        Text(model.time?.description ?? "N/A")
                                            .bold()
                                        Spacer()
                                        
                                        VStack {
                                            Text("Temp: \(temp(from: model))")
                                            Text("FeelsLike: \(feelLike(from: model))")
                                            Text("Precip Prob: \(precipProb(from: model))")
                                        }
                                        
                                    }
                                }
                                .padding()
                            }
                            .scrollContentBackground(.hidden)
                            .background(.regularMaterial)
                        } else {
                            List(vm.predictedCSVModels, id:\.id) { model in
                                VStack(alignment: .leading) {
                                    HStack {
                                        Text(model.time?.description ?? "N/A")
                                            .bold()
                                        Spacer()
                                        
                                        VStack {
                                            Text("Temp: \(temp(from: model))")
                                            Text("FeelsLike: \(feelLike(from: model))")
                                            Text("Precip Prob: \(precipProb(from: model))")
                                        }
                                    }
                                }
                                .padding()
                            }
                            .scrollContentBackground(.hidden)
                            .background(.regularMaterial)
                            
                        }
                    }
                    .padding(.vertical)
                }
            }
            .task {
                Task.detached(priority: .background, operation: {
                    await vm.fetchWeatherData()
                })
            }
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Picker(selection: $vm.regressorType) {
                        ForEach(RegressorType.allCases, id:\.self) { Text($0.description) }
                    } label: {
                        Text("\(vm.regressorType.description)")
                    }
                    .pickerStyle(.menu)
                }
                
                ToolbarItem(placement: .primaryAction) {
                    Picker(selection: $vm.selectedDay) {
                        ForEach(DayPrediction.allCases, id:\.self) { Text($0.description) }
                    } label: {
                        Text("\(vm.selectedDay.description)")
                    }
                    .pickerStyle(.menu)
                }
                
                
                ToolbarItem(placement: .principal) {
                    Button {
                        Task {
                            vm.clearAllData()
                            await vm.fetchWeatherData()
                        }
                    } label: {
                        Text("Re-fetch data and make prediction")
                    }
                    .buttonStyle(.borderedProminent)
                }
                
                ToolbarItem(placement: .navigation) {
                    Button {
                        vm.clearPredictedData()
                        vm.trainAndPredictWeatherMetrics()
                    } label: {
                        Text("Predict with selected regressor")
                    }
                    .buttonStyle(.borderedProminent)
                }
            }
        }
    }
    
    private func temp(from model: CSVModel) -> String {
        let value: Double
        switch selectedSection {
        case .openMeteo:
            value = model.omTemp
        case .weatherAPI:
            value = model.wTemp
        case .prediction:
            value = model.pTemp
        }
        return String(format: "%.1f", value)
    }

    private func feelLike(from model: CSVModel) -> String {
        let value: Double
        switch selectedSection {
        case .openMeteo:
            value = model.wTemp
        case .weatherAPI:
            value = model.wFeelLike
        case .prediction:
            value = model.pFeelLike
        }
        return String(format: "%.1f", value)
    }

    private func precipProb(from model: CSVModel) -> String {
        let value: Double
        switch selectedSection {
        case .openMeteo:
            value = Double(model.omPrecipProb)
        case .weatherAPI:
            value = Double(model.wPrecipProb)
        case .prediction:
            value = model.pPrecipProb
        }
        return String(format: "%.0f", value) + "%"
    }
}

#Preview {
    ContentView()
}

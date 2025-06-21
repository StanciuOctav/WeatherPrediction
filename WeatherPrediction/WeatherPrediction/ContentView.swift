//
//  ContentView.swift
//  WeatherPrediction
//
//  Created by Octav Stanciu on 03.02.2025.
//

import Charts
import SwiftUI

fileprivate enum PickerSection {
    case openMeteo, weatherAPI, prediction
}

fileprivate enum ChartData: String {
    case temp = "Temperature"
    case feelLike = "Feels Like"
    case precip = "Precipitation"
}

fileprivate enum DataType: String {
    case list = "List"
    case chart = "Chart"
}

struct ContentView: View {
    @State private var vm = ContentViewModel(openNM: OpenMeteoNetworkManager(), weatherNM: WeatherAPINetworkManager())
    @State private var selectedSection: PickerSection = .prediction
    @State private var selectedDataType: DataType = .list
    @State private var chartDataTypeSelected: ChartData = .temp
    
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
                        Picker(selection: $selectedDataType, content: {
                            Text("List").tag(DataType.list)
                            Text("Chart").tag(DataType.chart)
                        }, label: {
                            Text("Choose data display type")
                        })
                        .pickerStyle(.segmented)
                        
                        if selectedDataType == .list {
                            Picker(selection: $selectedSection, content: {
                                Text("Predicted").tag(PickerSection.prediction)
                                Text("OpenMeteo").tag(PickerSection.openMeteo)
                                Text("WeatherAPI").tag(PickerSection.weatherAPI)
                            }, label: {
                                Text("Choose data source")
                            })
                            .pickerStyle(.segmented)
                        } else {
                            Picker(selection: $chartDataTypeSelected, content: {
                                Text("Temperature").tag(ChartData.temp)
                                Text("Feels like temperature").tag(ChartData.feelLike)
                                Text("Precipitation probability").tag(ChartData.precip)
                            }, label: {
                                Text("Choose data display type")
                            })
                            .pickerStyle(.segmented)
                        }
                        
                        switch selectedDataType {
                        case .list:
                            listView()
                        case .chart:
                            chartView()
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
            .onChange(of: vm.regressorType, { _, _ in
                vm.regressorParameters = RegressorParameters()
            })
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    NavigationLink(destination: ParametersSettingsView(params: $vm.regressorParameters,
                                                                       typeOfRegressor: $vm.regressorType)) {
                        Label("Set model parameters", systemImage: "gear")
                    }
                }
                
                ToolbarItem(placement: .topBarLeading) {
                    Menu("Actions") {
                        Button {
                            Task {
                                vm.clearAllData()
                                await vm.fetchWeatherData()
                            }
                        } label: {
                            Text("Re-fetch data and make prediction")
                        }
                        .buttonStyle(.borderedProminent)
                        
                        Button {
                            vm.clearPredictedData()
#if canImport(CreateML)
                            vm.trainAndPredict()
#endif
                        } label: {
                            Text("Predict with selected regressor")
                        }
                        .buttonStyle(.borderedProminent)
                    }
                }
                
                ToolbarItem(placement: .topBarLeading) {
                    Menu("Configuration menu") {
                        regressorTypePicker()
                        selectDayPicker()
                    }
                }
            }
        }
    }
    
    private func regressorTypePicker() -> some View {
        Picker(selection: $vm.regressorType) {
            ForEach(RegressorType.allCases, id:\.self) { Text($0.description) }
        } label: {
            Text("Regressor: \(vm.regressorType.description)")
        }
        .pickerStyle(.menu)
    }
    
    private func selectDayPicker() -> some View {
        Picker(selection: $vm.selectedDay) {
            ForEach(DayPrediction.allCases, id:\.self) { Text($0.description) }
        } label: {
            Text("Predict for: \(vm.selectedDay.description)")
        }
        .pickerStyle(.menu)
    }
    
    private func chartView() -> some View {
        VStack {
            Text(chartDataTypeSelected.rawValue)
                .font(.headline)
            
            Chart {
                ForEach(vm.predictedSkyCastModels, id:\.id) { model in
                    if let hour = model.time?.hour {
                        LineMark(
                            x: .value("Hour", hour),
                            y: .value("Value", yValueFor(model))
                        )
                    }
                }
            }
            .chartXScale(domain: 0...23)
            .frame(height: 300)
        }
        .padding()
    }
    
    private func listView() -> some View {
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
            List(vm.predictedSkyCastModels, id:\.id) { model in
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
    
    private func yValueFor(_ model: SkyCastModel) -> Double {
        switch chartDataTypeSelected {
        case .temp:
            return model.pTemp
        case .feelLike:
            return model.pFeelLike
        case .precip:
            return model.pPrecipProb
        }
    }
    
    private func temp(from model: SkyCastModel) -> String {
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
    
    private func feelLike(from model: SkyCastModel) -> String {
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
    
    private func precipProb(from model: SkyCastModel) -> String {
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

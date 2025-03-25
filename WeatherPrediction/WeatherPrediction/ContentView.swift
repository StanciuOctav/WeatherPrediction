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
    @State private var vm: ContentViewModel
    @State private var selectedSection: PickerSection = .prediction
    
    init() {
        self.vm = ContentViewModel(openNM: OpenMeteoNetworkManager(), weatherNM: WeatherAPINetworkManager())
    }
    
    var body: some View {
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
        .task {
            Task.detached(priority: .background, operation: {
                await vm.fetchWeatherData()
            })
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
        return String(format: "%.2f", value)
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
        return String(format: "%.2f", value)
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
        return String(format: "%.2f", value) + "%"
    }
}

#Preview {
    ContentView()
}

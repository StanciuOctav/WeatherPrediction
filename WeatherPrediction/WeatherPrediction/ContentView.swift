//
//  ContentView.swift
//  WeatherPrediction
//
//  Created by Octav Stanciu on 03.02.2025.
//

import SwiftUI

fileprivate enum PickerSection {
    case openMeteo, weatherAPI, prediction, all
}

struct ContentView: View {
    @State private var vm: ContentViewModel
    @State private var selectedSection: PickerSection = .openMeteo
    
    init() {
        self.vm = ContentViewModel(openNM: OpenMeteoNetworkManager(), weatherNM: WeatherAPINetworkManager())
    }
    
    var body: some View {
        VStack {
            Picker(selection: $selectedSection, content: {
                Text("OpenMeteo").tag(PickerSection.openMeteo)
                Text("WeatherAPI").tag(PickerSection.weatherAPI)
                Text("Predicted").tag(PickerSection.prediction)
                Text("All").tag(PickerSection.all)
            }, label: {
                Text("Choose data source")
            })
            .pickerStyle(.segmented)
            
            List(vm.mlModel, id:\.id) { model in
                VStack(alignment: .leading) {
                    HStack {
                    Text(model.time?.description ?? "N/A")
                        .bold()
                        Spacer()
                        VStack {
                            Text("Temp: \(temp(from: model)))")
                            Text("FeelsLike: \(feelLike(from: model))")
                            Text("Precip Prob: \(precipProb(from: model))%")
                        }
                    }
                }
                .padding()
            }
            .scrollContentBackground(.hidden)
            .background(.regularMaterial)
        }
        .padding(.vertical)
        .task {
            Task.detached(priority: .background, operation: {
                await vm.fetchWeatherData()
            })
        }
    }
    
    private func temp(from model: CSVModel) -> Double {
        switch selectedSection {
        case .openMeteo:
            model.omTemp
        case .weatherAPI:
            model.wTemp
        case .prediction:
            0
        case .all:
            0
        }
    }
    
    private func feelLike(from model: CSVModel) -> Double {
        switch selectedSection {
        case .openMeteo:
            model.wTemp
        case .weatherAPI:
            model.wFeelLike
        case .prediction:
            0
        case .all:
            0
        }
    }
    
    private func precipProb(from model: CSVModel) -> Int {
        switch selectedSection {
        case .openMeteo:
            model.omPrecipProb
        case .weatherAPI:
            model.wPrecipProb
        case .prediction:
            0
        case .all:
            0
        }
    }
}

#Preview {
    ContentView()
}

//
//  ContentView.swift
//  WeatherPrediction
//
//  Created by Octav Stanciu on 03.02.2025.
//

import Alamofire
import Constants
import SwiftUI

struct Time: Decodable, DataDecoder {
    let year: Int
    let month: Int
    let day: Int
    let hour: Int
    
    init?(from dateString: String) {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm"

        guard let date = dateFormatter.date(from: dateString) else { return nil }

        let calendar = Calendar(identifier: .gregorian)
        self.year = calendar.component(.year, from: date)
        self.month = calendar.component(.month, from: date)
        self.day = calendar.component(.day, from: date)
        self.hour = calendar.component(.hour, from: date)
    }
    
    func decode<D>(_ type: D.Type, from data: Data) throws -> D where D : Decodable {
        let decoder = JSONDecoder()
        return try decoder.decode(D.self, from: data)
    }
}

struct Hourly: Decodable, DataDecoder {
    var time: [Time]
    var temperature: [Double]
    
    enum CodingKeys: String, CodingKey {
        case time
        case temperature = "temperature_2m"
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        let dateStringArray = try container.decodeIfPresent([String].self, forKey: .time) ?? []
        
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm"
        
        self.time = dateStringArray.compactMap { Time(from: $0) }
        self.temperature = try container.decodeIfPresent([Double].self, forKey: .temperature) ?? []
    }
    
    func decode<D>(_ type: D.Type, from data: Data) throws -> D where D : Decodable {
        let decoder = JSONDecoder()
        return try decoder.decode(D.self, from: data)
    }
}

struct MeteoModel: Decodable, DataDecoder {
    func decode<D>(_ type: D.Type, from data: Data) throws -> D where D : Decodable {
        let decoder = JSONDecoder()
        return try decoder.decode(D.self, from: data)
    }
    
    var latitude: Double
    var longitude: Double
    var hourly: Hourly
    
    enum CodingKeys: String, CodingKey {
        case latitude
        case longitude
        case hourly
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.latitude = try container.decodeIfPresent(Double.self, forKey: .latitude) ?? 0.0
        self.longitude = try container.decodeIfPresent(Double.self, forKey: .longitude) ?? 0.0
        self.hourly = try container.decodeIfPresent(Hourly.self, forKey: .hourly) ?? Hourly(from: decoder)
    }
}

@Observable
class ContentViewModel {
    
    func fetch() {
        AF.request(Constants.Meteo.base).responseDecodable(of: MeteoModel.self) { response in
            guard let result = response.value else { return }
            print(result.hourly.time)
        }
    }
}

struct ContentView: View {
    @State private var vm = ContentViewModel()
    var body: some View {
        VStack {
            Button {
                vm.fetch()
            } label: {
                Text("Fetch weather")
            }
        }
        .padding()
    }
}

#Preview {
    ContentView()
}

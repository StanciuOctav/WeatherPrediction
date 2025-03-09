//
//  OpenMeteoModels.swift
//  WeatherPrediction
//
//  Created by Octav Stanciu on 09.03.2025.
//

import Alamofire
import Foundation

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
    var apparentTemperature: [Double]
    var precipitation: [Double]
    var rain: [Double]
    var showers: [Double]
    
    enum CodingKeys: String, CodingKey {
        case time
        case temperature = "temperature_2m"
        case apparentTemperature = "apparent_temperature"
        case precipitation
        case rain
        case showers
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        let dateStringArray = try container.decodeIfPresent([String].self, forKey: .time) ?? []
        
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm"
        
        self.time = dateStringArray.compactMap { Time(from: $0) }
        self.temperature = try container.decodeIfPresent([Double].self, forKey: .temperature) ?? []
        self.apparentTemperature = try container.decodeIfPresent([Double].self, forKey: .apparentTemperature) ?? []
        self.precipitation = try container.decodeIfPresent([Double].self, forKey: .precipitation) ?? []
        self.rain = try container.decodeIfPresent([Double].self, forKey: .rain) ?? []
        self.showers = try container.decodeIfPresent([Double].self, forKey: .showers) ?? []
    }
    
    func decode<D>(_ type: D.Type, from data: Data) throws -> D where D : Decodable {
        let decoder = JSONDecoder()
        return try decoder.decode(D.self, from: data)
    }
}

struct OpenMeteoModel: Decodable, DataDecoder {
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

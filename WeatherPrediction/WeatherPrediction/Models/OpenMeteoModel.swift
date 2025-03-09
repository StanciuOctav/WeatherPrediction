//
//  OpenMeteoModels.swift
//  WeatherPrediction
//
//  Created by Octav Stanciu on 09.03.2025.
//

import Alamofire
import Constants
import Foundation

struct Time: Decodable, DataDecoder, AlamofireDecodable {
    let year: Int
    let month: Int
    let day: Int
    let hour: Int
    
    init?(from dateString: String, withDateFormat dateFormat: String) {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = dateFormat

        guard let date = dateFormatter.date(from: dateString) else { return nil }

        let calendar = Calendar(identifier: .gregorian)
        self.year = calendar.component(.year, from: date)
        self.month = calendar.component(.month, from: date)
        self.day = calendar.component(.day, from: date)
        self.hour = calendar.component(.hour, from: date)
    }
}

struct Hourly: Decodable, DataDecoder, AlamofireDecodable {
    let time: [Time]
    let temp: [Double]
    let feelLikeTemp: [Double]
    let precipProb: [Int]
    
    enum CodingKeys: String, CodingKey {
        case time
        case temp = "temperature_2m"
        case feelLikeTemp = "apparent_temperature"
        case precipProb = "precipitation_probability"
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        let dateStringArray = try container.decodeIfPresent([String].self, forKey: .time) ?? []
        
        self.time = dateStringArray.compactMap { Time(from: $0, withDateFormat: Constants.OpenMeteo.dateFormat) }
        self.temp = try container.decodeIfPresent([Double].self, forKey: .temp) ?? []
        self.feelLikeTemp = try container.decodeIfPresent([Double].self, forKey: .feelLikeTemp) ?? []
        self.precipProb = try container.decodeIfPresent([Int].self, forKey: .precipProb) ?? []
    }
}

struct OpenMeteoModel: Decodable, DataDecoder, AlamofireDecodable {
    let latitude: Double
    let longitude: Double
    let hourly: Hourly
    
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

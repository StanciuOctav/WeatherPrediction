//
//  WeatherAPIModel.swift
//  WeatherPrediction
//
//  Created by Octav Stanciu on 09.03.2025.
//

import Alamofire
import Constants
import Foundation

struct Hour: Decodable, DataDecoder, AlamofireDecodable {
    let time: Time
    let temp: Double
    let feelLikeTemp: Double
    let precipProb: Int
    
    enum CodingKeys: String, CodingKey {
        case time
        case temp = "temp_c"
        case feelLikeTemp = "feelslike_c"
        case precipProb = "chance_of_rain"
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        let dateStringArray = try container.decodeIfPresent(String.self, forKey: .time) ?? ""

        self.time = Time(from: dateStringArray, withDateFormat: Constants.WeatherAPI.dateFormat) ?? Time(from: "999-01-01 00:00", withDateFormat: Constants.WeatherAPI.dateFormat)!
        self.temp = try container.decodeIfPresent(Double.self, forKey: .temp) ?? 0
        self.feelLikeTemp = try container.decodeIfPresent(Double.self, forKey: .feelLikeTemp) ?? 0
        self.precipProb = try container.decodeIfPresent(Int.self, forKey: .precipProb) ?? 0
    }
}

struct ForecastDay: Decodable, DataDecoder, AlamofireDecodable {
    let hour: [Hour]
}

struct Forecast: Decodable, DataDecoder, AlamofireDecodable {
    let forecastday: [ForecastDay]
}

struct Location: Decodable, DataDecoder, AlamofireDecodable {
    let lat: Double
    let lon: Double
}

struct WeatherAPIModel: Decodable, DataDecoder, AlamofireDecodable {
    let location: Location
    let forecast: Forecast
}

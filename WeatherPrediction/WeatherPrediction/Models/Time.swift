//
//  Time.swift
//  WeatherPrediction
//
//  Created by Octav Stanciu on 18.03.2025.
//

import Alamofire
import Constants
import Foundation

struct Time: Decodable, DataDecoder, AlamofireDecodable, CustomStringConvertible, Hashable {
    let year: Int
    let month: Int
    let day: Int
    let hour: Int
    
    var description: String {
        "\(year) \(month) \(day) \(hour)\n"
    }
    
    init?(from dateString: String, withDateFormat dateFormat: String) {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = dateFormat
        dateFormatter.timeZone = TimeZone(secondsFromGMT: 0)

        guard let date = dateFormatter.date(from: dateString) else { return nil }

        let calendar = Calendar(identifier: .gregorian)
        self.year = calendar.component(.year, from: date)
        self.month = calendar.component(.month, from: date)
        self.day = calendar.component(.day, from: date)
        self.hour = calendar.component(.hour, from: date)
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(year)
        hasher.combine(month)
        hasher.combine(day)
        hasher.combine(hour)
    }
}

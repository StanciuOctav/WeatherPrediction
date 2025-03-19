//
//  Time.swift
//  WeatherPrediction
//
//  Created by Octav Stanciu on 18.03.2025.
//

import Alamofire
import Constants
import Foundation

struct Time: Decodable, DataDecoder, AlamofireDecodable, CustomStringConvertible {
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
}

extension Time: Comparable {
    static func < (lhs: Time, rhs: Time) -> Bool {
        if lhs.year != rhs.year {
            return lhs.year < rhs.year
        } else if lhs.month != rhs.month {
            return lhs.month < rhs.month
        } else if lhs.day != rhs.day {
            return lhs.day < rhs.day
        } else {
            return lhs.hour < rhs.hour
        }
    }
}

extension Time: Hashable {
    func hash(into hasher: inout Hasher) {
        hasher.combine(year)
        hasher.combine(month)
        hasher.combine(day)
        hasher.combine(hour)
    }
}

//
//  Calendar+Extension.swift
//  WeatherPrediction
//
//  Created by Octav Stanciu on 22.03.2025.
//

import Foundation

extension Calendar {
    /// Returns [String] containing the last 7 days including the one today.
    public static var last7Days: [String] {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        
        let last7Days: [Date] = (0..<8).map { offset in
            calendar.date(byAdding: .day, value: -offset, to: today)!
        }
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        formatter.locale = Locale(identifier: "en_US_POSIX")
        
        let formattedDates = last7Days.map { formatter.string(from: $0) }
        
        return formattedDates
    }
    
    public static var tomorrow: String {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        let tomorrow = calendar.date(byAdding: .day, value: 1, to: today)!
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        formatter.locale = Locale(identifier: "en_US_POSIX")
        return formatter.string(from: tomorrow)
    }
    
    public static var tomorrowDate: Date {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        return calendar.date(byAdding: .day, value: 1, to: today)!
    }
}

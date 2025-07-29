//
//  Calendar+Extension.swift
//  WeatherPrediction
//
//  Created by Octav Stanciu on 22.03.2025.
//

import Foundation

extension Calendar {
    
    private static var formatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        formatter.locale = Locale(identifier: "en_US_POSIX")
        return formatter
    }
    
    /// Returns an array of strings of the last 7 days' dates.
    public static var last7Days: [String] {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        
        // Start from yesterday and go back 6 more days
        let last7Days: [Date] = (1...7).map { offset in
            calendar.date(byAdding: .day, value: -offset, to: today)!
        }
        
        let formattedDates = last7Days.map { formatter.string(from: $0) }
        
        return formattedDates
    }
    
    /// Returns [String] containing the last 7 days including the one today.
    public static var last7DaysAndToday: [String] {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        let todayFormatted = formatter.string(from: today)
        
        return [todayFormatted] + last7Days
    }
    
    /// Returns the String containing today's date.
    public static var tomorrow: String {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        let tomorrow = calendar.date(byAdding: .day, value: 1, to: today)!
        
        return formatter.string(from: tomorrow)
    }
    
    /// Returns the date of tomorrow.
    public static var tomorrowDate: Date {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        return calendar.date(byAdding: .day, value: 1, to: today)!
    }
    
    /// Returns the date of today.
    public static var todayDate: Date {
        let calendar = Calendar.current
        return calendar.startOfDay(for: Date())
//        let today = calendar.startOfDay(for: Date())
//        return calendar.date(byAdding: .day, value: -3, to: today)!
    }
}

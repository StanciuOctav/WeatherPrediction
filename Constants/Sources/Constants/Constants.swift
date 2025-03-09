// The Swift Programming Language
// https://docs.swift.org/swift-book
public struct Constants {
    public static let urlScheme = "https"
    
    public struct OpenMeteo {
        public static let host = "api.open-meteo.com"
        public static let path = "/v1/forecast"
        public static let hourly = "temperature_2m,apparent_temperature,precipitation,rain,showers"
    }
    
    public struct WeatherAPI {
        public static let apiKey = "f4248efc801c49a484a114129250903"
        public static let base = ""
    }
}

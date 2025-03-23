// The Swift Programming Language
// https://docs.swift.org/swift-book
public struct Constants {
    public static let urlScheme = "https"
    
    // https://open-meteo.com/en/docs#hourly=temperature_2m,apparent_temperature,precipitation&past_days=14&forecast_days=1
    public struct OpenMeteo {
        public static let host = "api.open-meteo.com"
        public static let path = "/v1/forecast"
        public static let hourly = "temperature_2m,apparent_temperature,precipitation_probability"
        public static let dateFormat = "yyyy-MM-dd'T'HH:mm"
    }
    
    // https://app.swaggerhub.com/apis-docs/WeatherAPI.com/WeatherAPI/1.0.2#/APIs/realtime-weather
    public struct WeatherAPI {
        public static let host = "api.weatherapi.com"
        public static let historyPath = "/v1/history.json"
        public static let forecastPath = "/v1/forecast.json"
        public static let apiKey = "6de4607f8180463f9b774209252303"
//        public static let base = "https://api.weatherapi.com/v1/forecast.json?key=6de4607f8180463f9b774209252303&q=46.75%2023.57&days=14&aqi=no&alerts=no"
        public static let dateFormat = "yyyy-MM-dd HH:mm"
    }
}

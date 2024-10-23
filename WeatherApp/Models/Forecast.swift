//
//  Forecast.swift
//  WeatherApp
//
//  Created by M W on 19/10/2024.
//

import Foundation

struct Forecast: Codable {
    let daily: [DailyWeather]
    
    struct DailyWeather: Codable {
        let dt: TimeInterval
        let temp: Temperature
        let weather: [WeatherCondition]

        struct Temperature: Codable {
            let day: Double
        }
        
        struct WeatherCondition: Codable {
            let description: String
            let icon: String
        }
    }
}

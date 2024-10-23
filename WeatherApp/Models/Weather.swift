//
//  Weather.swift
//  WeatherApp
//
//  Created by M W on 19/10/2024.
//

import Foundation

struct Weather: Codable {
    let name: String
    let main: Main
    let weather: [WeatherCondition]

    struct Main: Codable {
        let temp: Double
        let humidity: Double
    }

    struct WeatherCondition: Codable {
        let description: String
        let icon: String
    }
}

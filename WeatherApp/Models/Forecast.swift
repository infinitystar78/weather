//
//  Forecast.swift
//  WeatherApp
//
//  Created by M W on 19/10/2024.
//
import Foundation

struct Forecast: Codable {
    let list: [WeatherDetail]
    let city: CityInfo
}

struct WeatherDetail: Codable {
    let dt: TimeInterval
    let main: MainInfo
    let weather: [WeatherCondition]
    let wind: WindInfo
}

struct MainInfo: Codable {
    let temp: Double
    let tempMin: Double
    let tempMax: Double
    let humidity: Int
    
    enum CodingKeys: String, CodingKey {
        case temp
        case tempMin = "temp_min"
        case tempMax = "temp_max"
        case humidity
    }
}

struct WeatherCondition: Codable {
    let id: Int
    let main: String
    let description: String
    let icon: String
}

struct WindInfo: Codable {
    let speed: Double
    let deg: Int
}

struct CityInfo: Codable {
    let id: Int
    let name: String
    let coord: Coordinates
}

struct Coordinates: Codable {
    let lat: Double
    let lon: Double
}


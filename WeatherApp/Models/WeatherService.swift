//
//  WeatherService.swift
//  WeatherApp
//
//  Created by M W on 23/10/2024.
//
import Foundation
import Combine

protocol WeatherServiceProtocol {
    func fetchWeather(for city: String) async throws -> Weather
    func fetchForecast(for city: String) async throws -> Forecast
    func fetchWeather(lat: Double, lon: Double) async throws -> Weather
    func fetchForecast(lat: Double, lon: Double) async throws -> Forecast
}

class WeatherService: WeatherServiceProtocol {
    private let urlSession: URLSession
    private let baseURL = "https://api.openweathermap.org/data/2.5/"
    
    init(urlSession: URLSession = .shared) {
        self.urlSession = urlSession
    }
    
    private func createURL(for endpoint: String, with parameters: String) -> URL? {
        let urlString = "\(baseURL)\(endpoint)?\(parameters)&appid=\(Config.apiKey)&units=metric"
        return URL(string: urlString)
    }
    
    func fetchWeather(for city: String) async throws -> Weather {
        let cityQuery = "q=\(city.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? city)"
        guard let url = createURL(for: "weather", with: cityQuery) else {
            throw URLError(.badURL)
        }
        
        let (data, _) = try await urlSession.data(from: url)
        let weather = try JSONDecoder().decode(Weather.self, from: data)
        return weather
    }
    
    func fetchForecast(for city: String) async throws -> Forecast {
        let cityQuery = "q=\(city.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? city)"
        guard let url = createURL(for: "forecast", with: cityQuery) else {
            throw URLError(.badURL)
        }
        
        let (data, _) = try await urlSession.data(from: url)
        let forecast = try JSONDecoder().decode(Forecast.self, from: data)
        return forecast
    }
    
    func fetchWeather(lat: Double, lon: Double) async throws -> Weather {
        let coordinateQuery = "lat=\(lat)&lon=\(lon)"
        guard let url = createURL(for: "weather", with: coordinateQuery) else {
            throw URLError(.badURL)
        }
        
        let (data, _) = try await urlSession.data(from: url)
        let weather = try JSONDecoder().decode(Weather.self, from: data)
        return weather
    }
    
    func fetchForecast(lat: Double, lon: Double) async throws -> Forecast {
        let coordinateQuery = "lat=\(lat)&lon=\(lon)"
        guard let url = createURL(for: "forecast", with: coordinateQuery) else {
            throw URLError(.badURL)
        }
        
        let (data, _) = try await urlSession.data(from: url)
        let forecast = try JSONDecoder().decode(Forecast.self, from: data)
        return forecast
    }
}


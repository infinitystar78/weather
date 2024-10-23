//
//  WeatherViewModel.swift
//  WeatherApp
//
//  Created by M W on 19/10/2024.
//

import Foundation
import CoreLocation
import Combine

class WeatherViewModel: NSObject, ObservableObject, CLLocationManagerDelegate {
    @Published var weather: Weather?
    @Published var forecast: Forecast?
    @Published var errorMessage: String?

    private let locationManager: CLLocationManager
    private let urlSession: URLSession

    init(
        urlSession: URLSession = .shared,
        locationManager: CLLocationManager = CLLocationManager()
    ) {
        self.urlSession = urlSession
        self.locationManager = locationManager
        super.init()
        setupLocationManager()
    }

    private func setupLocationManager() {
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyKilometer
        requestLocationPermission()
    }

    private func requestLocationPermission() {
        switch locationManager.authorizationStatus {
        case .notDetermined:
            locationManager.requestWhenInUseAuthorization()
        case .denied, .restricted:
            self.errorMessage = "Location access is denied. Please enable it in settings."
        default:
            startLocationUpdatesIfAuthorized()
        }
    }

    private func startLocationUpdatesIfAuthorized() {
        if locationManager.authorizationStatus == .authorizedWhenInUse ||
            locationManager.authorizationStatus == .authorizedAlways {
            locationManager.startUpdatingLocation()
        }
    }

    func fetchWeather(for city: String) async {
        guard !city.trimmingCharacters(in: .whitespaces).isEmpty else { return }

        let cityQuery = city.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? city
        let urlString = "https://api.openweathermap.org/data/2.5/weather?q=\(cityQuery)&appid=\(Config.apiKey)&units=metric"
        
        guard let url = URL(string: urlString) else {
            DispatchQueue.main.async {
                self.errorMessage = "Invalid URL."
            }
            return
        }

        do {
            let (data, response) = try await urlSession.data(from: url)
            
            // Check for valid HTTP status code
            guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
                DispatchQueue.main.async {
                    self.errorMessage = "Invalid response from the server. Please try again."
                }
                return
            }

            let decodedWeather = try JSONDecoder().decode(Weather.self, from: data)

            // Update weather immediately after successful fetch
            DispatchQueue.main.async {
                self.weather = decodedWeather
                self.errorMessage = nil
            }

            // Now fetch forecast
            let forecastUrlString = "https://api.openweathermap.org/data/2.5/forecast?q=\(cityQuery)&appid=\(Config.apiKey)&units=metric"
            if let forecastUrl = URL(string: forecastUrlString) {
                let (forecastData, _) = try await urlSession.data(from: forecastUrl)
                let decodedForecast = try JSONDecoder().decode(Forecast.self, from: forecastData)

                DispatchQueue.main.async {
                    self.forecast = decodedForecast
                }
            }
        } catch let decodingError as DecodingError {
            print("Decoding error: \(decodingError)")
            DispatchQueue.main.async {
                self.errorMessage = "Data format is incorrect. Unable to parse response."
            }
        } catch {
            print("Error fetching weather: \(error)")
            DispatchQueue.main.async {
                self.errorMessage = "Could not find weather for \(city). Error: \(error.localizedDescription)"
            }
        }
    }

    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.first else { return }
        locationManager.stopUpdatingLocation()
        Task {
            await fetchWeather(lat: location.coordinate.latitude, lon: location.coordinate.longitude)
        }
    }

    func fetchWeather(lat: Double, lon: Double) async {
        let urlString = "https://api.openweathermap.org/data/2.5/weather?lat=\(lat)&lon=\(lon)&appid=\(Config.apiKey)&units=metric"

        guard let url = URL(string: urlString) else {
            DispatchQueue.main.async {
                self.errorMessage = "Invalid URL for location-based weather."
            }
            return
        }

        do {
            let (data, response) = try await urlSession.data(from: url)

            // Check for valid HTTP status code
            guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
                DispatchQueue.main.async {
                    self.errorMessage = "Invalid response from the server for current location."
                }
                return
            }

            let decodedWeather = try JSONDecoder().decode(Weather.self, from: data)

            DispatchQueue.main.async {
                self.weather = decodedWeather
                self.errorMessage = nil
            }

            // Fetch the forecast for the given location
            let forecastUrlString = "https://api.openweathermap.org/data/2.5/forecast?lat=\(lat)&lon=\(lon)&appid=\(Config.apiKey)&units=metric"
            if let forecastUrl = URL(string: forecastUrlString) {
                let (forecastData, _) = try await urlSession.data(from: forecastUrl)
                let decodedForecast = try JSONDecoder().decode(Forecast.self, from: forecastData)

                DispatchQueue.main.async {
                    self.forecast = decodedForecast
                }
            }
        } catch let decodingError as DecodingError {
            print("Decoding error: \(decodingError)")
            DispatchQueue.main.async {
                self.errorMessage = "Data format is incorrect. Unable to parse response."
            }
        } catch {
            print("Error fetching weather: \(error)")
            DispatchQueue.main.async {
                self.errorMessage = "Could not find weather for current location. Error: \(error.localizedDescription)"
            }
        }
    }
}


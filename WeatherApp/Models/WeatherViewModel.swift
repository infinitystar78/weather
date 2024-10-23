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
    
    private let weatherService: WeatherServiceProtocol
    private let locationManager: CLLocationManager
    
    init(weatherService: WeatherServiceProtocol = WeatherService()) {
        self.weatherService = weatherService
        self.locationManager = CLLocationManager()
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
        do {
            let weather = try await weatherService.fetchWeather(for: city)
            DispatchQueue.main.async {
                self.weather = weather
                self.errorMessage = nil
            }
        } catch {
            DispatchQueue.main.async {
                self.errorMessage = "Could not find weather for \(city). Error: \(error.localizedDescription)"
            }
        }
    }
    
    func fetchForecast(for city: String) async {
        do {
            let forecast = try await weatherService.fetchForecast(for: city)
            DispatchQueue.main.async {
                self.forecast = forecast
                self.errorMessage = nil
            }
        } catch {
            DispatchQueue.main.async {
                self.errorMessage = "Could not find forecast for \(city). Error: \(error.localizedDescription)"
            }
        }
    }
    
    func fetchWeather(lat: Double, lon: Double) async {
        do {
            let weather = try await weatherService.fetchWeather(lat: lat, lon: lon)
            DispatchQueue.main.async {
                self.weather = weather
                self.errorMessage = nil
            }
        } catch {
            DispatchQueue.main.async {
                self.errorMessage = "Could not find weather for the current location. Error: \(error.localizedDescription)"
            }
        }
    }
    
    func fetchForecast(lat: Double, lon: Double) async {
        do {
            let forecast = try await weatherService.fetchForecast(lat: lat, lon: lon)
            DispatchQueue.main.async {
                self.forecast = forecast
                self.errorMessage = nil
            }
        } catch {
            DispatchQueue.main.async {
                self.errorMessage = "Could not find forecast for the current location. Error: \(error.localizedDescription)"
            }
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.first else { return }
        locationManager.stopUpdatingLocation()
        Task {
            await fetchWeather(lat: location.coordinate.latitude, lon: location.coordinate.longitude)
            await fetchForecast(lat: location.coordinate.latitude, lon: location.coordinate.longitude)
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        DispatchQueue.main.async {
            self.errorMessage = "Location error: \(error.localizedDescription)"
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        switch status {
        case .authorizedWhenInUse, .authorizedAlways:
            startLocationUpdatesIfAuthorized()
        case .denied, .restricted:
            DispatchQueue.main.async {
                self.errorMessage = "Location access is denied. Please enable it in settings."
            }
        default:
            break
        }
    }
}


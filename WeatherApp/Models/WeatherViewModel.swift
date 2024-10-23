//
//  WeatherViewModel.swift
//  WeatherApp
//
//  Created by M W on 19/10/2024.
//
import Foundation
import CoreLocation

class WeatherViewModel: NSObject, ObservableObject {
    @Published var weather: Weather?
    @Published var forecast: Forecast?
    @Published var errorMessage: String?
    private let locationManager = CLLocationManager()
    
    override init() {
        super.init()
        setupLocationManager()
        requestLocationPermission()
        startLocationUpdatesIfAuthorized()
    }

    private func setupLocationManager() {
        locationManager.delegate = self
    }
    
    func fetchWeather(for city: String) async {
        let cityQuery = city.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? city
        let urlString = "https://api.openweathermap.org/data/2.5/weather?q=\(cityQuery)&appid=\(Config.apiKey)&units=metric"
        guard let url = URL(string: urlString) else {
            self.errorMessage = "Invalid URL"
            return
        }

        do {
            let (data, _) = try await URLSession.shared.data(from: url)
            let decodedWeather = try JSONDecoder().decode(Weather.self, from: data)
            DispatchQueue.main.async {
                self.weather = decodedWeather
            }
        } catch {
            DispatchQueue.main.async {
                self.errorMessage = "Failed to fetch weather: \(error.localizedDescription)"
            }
        }
    }
    
    func fetchWeather(lat: Double, lon: Double) async {
        let urlString = "https://api.openweathermap.org/data/2.5/weather?lat=\(lat)&lon=\(lon)&appid=\(Config.apiKey)&units=metric"
        guard let url = URL(string: urlString) else {
            self.errorMessage = "Invalid URL"
            return
        }

        do {
            let (data, _) = try await URLSession.shared.data(from: url)
            let decodedWeather = try JSONDecoder().decode(Weather.self, from: data)
            DispatchQueue.main.async {
                self.weather = decodedWeather
            }
        } catch {
            DispatchQueue.main.async {
                self.errorMessage = "Error:  Failed to fetch weather: \(error.localizedDescription)"
            }
        }
    }
}


extension WeatherViewModel: CLLocationManagerDelegate {
    
    private func requestLocationPermission() {
           switch locationManager.authorizationStatus {
           case .notDetermined:
               locationManager.requestWhenInUseAuthorization()
           case .denied, .restricted:
               self.errorMessage = "Location access is denied. Please enable it in settings."
           default:
               break
           }
       }
    
    
    private func startLocationUpdatesIfAuthorized() {
        if locationManager.authorizationStatus == .authorizedWhenInUse || locationManager.authorizationStatus == .authorizedAlways {
            locationManager.startUpdatingLocation()
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.first else { return }
        Task {
            await fetchWeather(lat: location.coordinate.latitude, lon: location.coordinate.longitude)
        }
    }
    
    
    
}

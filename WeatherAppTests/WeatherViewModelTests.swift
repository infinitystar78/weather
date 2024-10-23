//
//  WeatherViewModelTests.swift
//  WeatherAppTests
//
//  Created by M W on 20/10/2024.
//
import XCTest
import CoreLocation
@testable import WeatherApp

class MockURLProtocol: URLProtocol {
    static var mockData: Data?
    static var mockError: Error?
    
    override class func canInit(with request: URLRequest) -> Bool {
        return true
    }
    
    override class func canonicalRequest(for request: URLRequest) -> URLRequest {
        return request
    }
    
    override func startLoading() {
        if let error = MockURLProtocol.mockError {
            client?.urlProtocol(self, didFailWithError: error)
            return
        }
        
        if let data = MockURLProtocol.mockData {
            let response = HTTPURLResponse(
                url: request.url ?? URL(string: "https://test.com")!,
                statusCode: 200,
                httpVersion: nil,
                headerFields: nil
            )!
            client?.urlProtocol(self, didReceive: response, cacheStoragePolicy: .notAllowed)
            client?.urlProtocol(self, didLoad: data)
        }
        
        client?.urlProtocolDidFinishLoading(self)
    }
    
    override func stopLoading() {}
}

class MockLocationManager: CLLocationManager {
    var mockLocation: CLLocation?
    private var _mockAuthorizationStatus: CLAuthorizationStatus = .notDetermined
    
    class var authorizationStatus: CLAuthorizationStatus {
        return CLLocationManager().authorizationStatus
    }
    
    func setAuthorizationStatus(_ status: CLAuthorizationStatus) {
        _mockAuthorizationStatus = status
    }
    
    override func startUpdatingLocation() {
        if let location = mockLocation {
            delegate?.locationManager?(self, didUpdateLocations: [location])
        }
    }
}

@MainActor
class WeatherViewModelTests: XCTestCase {
    var viewModel: WeatherViewModel!
    var mockLocationManager: MockLocationManager!
    var mockURLSession: URLSession!
    
    override func setUpWithError() throws {
        let configuration = URLSessionConfiguration.ephemeral
        configuration.protocolClasses = [MockURLProtocol.self]
        mockURLSession = URLSession(configuration: configuration)
        
        mockLocationManager = MockLocationManager()
        let weatherService = WeatherService(urlSession: mockURLSession)
        
        viewModel = WeatherViewModel(weatherService: weatherService)
    }
    
    override func tearDownWithError() throws {
        viewModel = nil
        mockURLSession = nil
        mockLocationManager = nil
        MockURLProtocol.mockData = nil
        MockURLProtocol.mockError = nil
    }
    
    // MARK: - Weather Fetch Tests
    
    func testFetchWeatherSuccess() async throws {
        // Given
        let mockWeatherData = createMockWeatherData(
            cityName: "London",
            temperature: 20.0,
            humidity: 65,
            description: "Clear sky"
        )
        MockURLProtocol.mockData = mockWeatherData
        
        // When
        await viewModel.fetchWeather(for: "London")
        
        // Then
        XCTAssertNotNil(viewModel.weather)
        XCTAssertEqual(viewModel.weather?.name, "London")
        XCTAssertEqual(viewModel.weather?.main.temp, 20.0)
        XCTAssertEqual(viewModel.weather?.main.humidity, 65)
        XCTAssertEqual(viewModel.weather?.weather.first?.description, "Clear sky")
        XCTAssertNil(viewModel.errorMessage)
    }
    
    func testFetchWeatherFailure() async throws {
        // Given
        MockURLProtocol.mockError = NSError(domain: "TestError", code: -1)
        
        // When
        await viewModel.fetchWeather(for: "InvalidCity")
        
        // Then
        XCTAssertNil(viewModel.weather)
        XCTAssertNotNil(viewModel.errorMessage)
        XCTAssertTrue(viewModel.errorMessage?.contains("Error") ?? false)
    }
    
    func testFetchWeatherWithEmptyCity() async {
        // When
        await viewModel.fetchWeather(for: "")
        
        // Then
        XCTAssertNil(viewModel.weather)
        XCTAssertNotNil(viewModel.errorMessage)
        XCTAssertTrue(viewModel.errorMessage?.contains("Invalid") ?? false)
    }
    
    func testFetchWeatherWithInvalidURL() async {
        // Given
        let invalidCharacters = "!@#$%^&*()"
        
        // When
        await viewModel.fetchWeather(for: invalidCharacters)
        
        // Then
        XCTAssertNil(viewModel.weather)
        XCTAssertNotNil(viewModel.errorMessage)
        XCTAssertTrue(viewModel.errorMessage?.contains("Error") ?? false)
    }
    
    // MARK: - Location Tests
    
    func testLocationUpdateSuccess() async throws {
        // Given
        let expectation = expectation(description: "Location update")
        let mockLocation = CLLocation(latitude: 51.5074, longitude: -0.1278)
        mockLocationManager.mockLocation = mockLocation
        mockLocationManager.setAuthorizationStatus(.authorizedWhenInUse)
        
        // Create mock weather data for location
        let mockWeatherData = createMockWeatherData(
            cityName: "London",
            temperature: 20.0,
            humidity: 65,
            description: "Clear sky"
        )
        MockURLProtocol.mockData = mockWeatherData
        
        // When
        Task {
            await viewModel.locationManager(mockLocationManager, didUpdateLocations: [mockLocation])
            expectation.fulfill()
        }
        
        // Then
        await fulfillment(of: [expectation], timeout: 2.0)
        XCTAssertNotNil(viewModel.weather)
        XCTAssertEqual(viewModel.weather?.name, "London")
    }
    
    func testLocationPermissionDenied() {
        // Given
        mockLocationManager.setAuthorizationStatus(.denied)
        
        // When
        viewModel.locationManager(mockLocationManager, didChangeAuthorization: .denied)
        
        // Then
        XCTAssertNotNil(viewModel.errorMessage)
        XCTAssertTrue(viewModel.errorMessage?.contains("Location access is denied") ?? false)
    }
    
    // MARK: - Helper Methods
    
    private func createMockWeatherData(
        cityName: String,
        temperature: Double,
        humidity: Int,
        description: String
    ) -> Data {
        let json = """
        {
            "name": "\(cityName)",
            "main": {
                "temp": \(temperature),
                "humidity": \(humidity)
            },
            "weather": [
                {
                    "description": "\(description)",
                    "icon": "01d"
                }
            ]
        }
        """
        return json.data(using: .utf8)!
    }
}



//
//  WeatherViewModelTests.swift
//  WeatherAppTests
//
//  Created by M W on 20/10/2024.
//
import XCTest
import CoreLocation
@testable import WeatherApp
import Combine

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
            client?.urlProtocol(self, didLoad: data)
            let response = HTTPURLResponse(
                url: request.url ?? URL(string: "https://test.com")!,
                statusCode: 200,
                httpVersion: nil,
                headerFields: nil
            )!
            client?.urlProtocol(self, didReceive: response, cacheStoragePolicy: .notAllowed)
        }
        
        client?.urlProtocolDidFinishLoading(self)
    }
    
    override func stopLoading() {}
}

class MockLocationManager: CLLocationManager {
    var mockLocation: CLLocation?
    private var _mockAuthorizationStatus: CLAuthorizationStatus = .notDetermined
    
    override var authorizationStatus: CLAuthorizationStatus {
        return _mockAuthorizationStatus
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
    var cancellables: Set<AnyCancellable>!
    
    override func setUp() async throws {
        let configuration = URLSessionConfiguration.ephemeral
        configuration.protocolClasses = [MockURLProtocol.self]
        mockURLSession = URLSession(configuration: configuration)
        
        mockLocationManager = MockLocationManager()
        viewModel = WeatherViewModel(
            urlSession: mockURLSession,
            locationManager: mockLocationManager
        )
        cancellables = []
        
        MockURLProtocol.mockData = nil
        MockURLProtocol.mockError = nil
    }
    
    override func tearDown() {
        viewModel = nil
        mockURLSession = nil
        mockLocationManager = nil
        cancellables = nil
        super.tearDown()
    }
    
    // MARK: - Weather Fetch Tests
    
    func testFetchWeatherSuccess() async throws {
        // Given
        let mockWeatherData = createMockWeatherData(
            cityName: "London",
            temperature: 20.0,
            humidity: 65.0,
            description: "Clear sky"
        )
        MockURLProtocol.mockData = mockWeatherData
        
        // When
        await viewModel.fetchWeather(for: "London")
        
        // Then
        XCTAssertNotNil(viewModel.weather)
        XCTAssertEqual(viewModel.weather?.name, "London")
        XCTAssertEqual(viewModel.weather?.main.temp, 20.0)
        XCTAssertEqual(viewModel.weather?.main.humidity, 65.0)
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
        XCTAssertTrue(viewModel.errorMessage?.contains("Failed to fetch weather") ?? false)
    }
    
    func testFetchWeatherWithEmptyCity() async {
        // When
        await viewModel.fetchWeather(for: "")
        
        // Then
        XCTAssertNil(viewModel.weather)
        XCTAssertNotNil(viewModel.errorMessage)
        XCTAssertTrue(viewModel.errorMessage?.contains("Invalid city name") ?? false)
    }
    
    func testFetchWeatherWithInvalidURL() async {
        // Given
        let invalidCharacters = "!@#$%^&*()"
        
        // When
        await viewModel.fetchWeather(for: invalidCharacters)
        
        // Then
        XCTAssertNil(viewModel.weather)
        XCTAssertNotNil(viewModel.errorMessage)
    }
    
    // MARK: - Location Tests
    
    func testLocationUpdateSuccess() async {
        // Given
        let expectation = expectation(description: "Location update")
        let mockLocation = CLLocation(latitude: 51.5074, longitude: -0.1278)
        mockLocationManager.mockLocation = mockLocation
        mockLocationManager.setAuthorizationStatus(.authorizedWhenInUse)
        
        // Create mock weather data for location
        let mockWeatherData = createMockWeatherData(
            cityName: "London",
            temperature: 20.0,
            humidity: 65.0,
            description: "Clear sky"
        )
        MockURLProtocol.mockData = mockWeatherData
        
        // When
        viewModel.$weather
            .dropFirst()
            .sink { _ in
                expectation.fulfill()
            }
            .store(in: &cancellables)
        
        viewModel.locationManager(mockLocationManager, didUpdateLocations: [mockLocation])
        
        // Then
        await fulfillment(of: [expectation], timeout: 2.0)
    }
    
    func testLocationPermissionDenied() async {
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
        humidity: Double,
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

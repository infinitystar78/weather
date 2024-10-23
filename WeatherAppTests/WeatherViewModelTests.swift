//
//  WeatherViewModelTests.swift
//  WeatherAppTests
//
//  Created by M W on 20/10/2024.
//
import XCTest
@testable import WeatherApp

class WeatherViewModelTests: XCTestCase {

    var viewModel: WeatherViewModel!

    override func setUp() {
        super.setUp()
        viewModel = WeatherViewModel()
    }

    override func tearDown() {
        viewModel = nil
        super.tearDown()
    }

    func testFetchWeatherSuccess() async {
        // Assuming "London" is a valid city
        await viewModel.fetchWeather(for: "London")
        
        XCTAssertNotNil(viewModel.weather, "Weather data should be present")
    }

    func testFetchWeatherFailure() async {
        // Assuming "InvalidCity" will cause an error
        await viewModel.fetchWeather(for: "InvalidCity")
        
        XCTAssertNotNil(viewModel.errorMessage, "Error message should be present")
    }
}


//
//  ContentView.swift
//  WeatherApp
//
//  Created by M W on 19/10/2024.
//

import SwiftUI
import CoreLocation

struct ContentView: View {
    @StateObject private var viewModel = WeatherViewModel()
    @State private var searchText = "London"  // Initialize with London
    @FocusState private var isSearchFocused: Bool

    var body: some View {
        ZStack {
            backgroundView
                .edgesIgnoringSafeArea(.all)
            
            VStack(spacing: 20) {
                // Search Bar
                searchBar
                
                // Weather Information
                weatherInfo
                
                // Error Message
                if let error = viewModel.errorMessage {
                    Text(error)
                        .foregroundColor(.red)
                        .padding()
                        .background(Color.white.opacity(0.8))
                        .cornerRadius(10)
                }
                
                // Forecast
                forecastView
            }
            .padding()
        }
        .task {
            // Direct initial fetch with the default city (London)
            await performInitialFetch()
        }
    }

    // This function runs the initial fetch for weather
    private func performInitialFetch() async {
        let trimmedSearch = searchText.trimmingCharacters(in: .whitespaces)
        guard !trimmedSearch.isEmpty else { return }
        await viewModel.fetchWeather(for: trimmedSearch)
    }

    private var searchBar: some View {
        HStack {
            TextField("Enter city", text: $searchText)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .focused($isSearchFocused)
                .padding(10)
                .background(Color.white.opacity(0.8))
                .cornerRadius(15)
                .submitLabel(.search)
                .onSubmit {
                    Task {
                        await performSearch()
                    }
                }
                .autocorrectionDisabled()
                .textInputAutocapitalization(.never)
            
            Button {
                isSearchFocused = false
                Task {
                    await performSearch()
                }
            } label: {
                Image(systemName: "magnifyingglass")
                    .foregroundColor(.white)
                    .padding(10)
                    .background(Color.blue.opacity(0.8))
                    .clipShape(Circle())
            }
        }
        .padding(.horizontal)
    }
    
    private func performSearch() async {
        let trimmedSearch = searchText.trimmingCharacters(in: .whitespaces)
        guard !trimmedSearch.isEmpty else { return }
        
        isSearchFocused = false
        await viewModel.fetchWeather(for: trimmedSearch)
    }
    
    private var weatherInfo: some View {
        Group {
            if let weather = viewModel.weather {
                VStack(spacing: 15) {
                    Text(weather.name)
                        .font(.system(size: 36, weight: .bold, design: .rounded))
                        .foregroundColor(.white)
                    
                    HStack(spacing: 20) {
                        VStack {
                            Text("\(Int(round(weather.main.temp)))°C")
                                .font(.system(size: 48, weight: .medium))
                            Text(weather.weather.first?.description.capitalized ?? "")
                                .font(.system(size: 20, weight: .regular))
                        }
                        
                        VStack(alignment: .leading, spacing: 5) {
                            Label(
                                "\(Int(round(weather.main.humidity)))%",
                                systemImage: "humidity"
                            )
                        }
                    }
                    .foregroundColor(.white)
                }
                .padding()
                .background(Color.black.opacity(0.2))
                .cornerRadius(20)
                .transition(.opacity)
            } else {
                ProgressView()
                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
            }
        }
    }
    
    private var forecastView: some View {
        Group {
            if let forecastList = viewModel.forecast?.list {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 15) {
                        ForEach(forecastList, id: \.dt) { detail in
                            VStack(spacing: 10) {
                                Text(formatDate(detail.dt))
                                    .font(.system(size: 16, weight: .medium))
                                Text("\(Int(round(detail.main.temp)))°C")
                                    .font(.system(size: 20, weight: .bold))
                                Text(detail.weather.first?.description.capitalized ?? "")
                                    .font(.system(size: 14))
                                    .multilineTextAlignment(.center)
                            }
                            .padding()
                            .frame(width: 120)
                            .background(Color.white.opacity(0.2))
                            .cornerRadius(15)
                        }
                    }
                    .padding(.horizontal)
                }
                .transition(.opacity)
            }
        }
    }
    
    private func formatDate(_ timestamp: TimeInterval) -> String {
        let date = Date(timeIntervalSince1970: timestamp)
        let formatter = DateFormatter()
        formatter.dateFormat = "EEE"
        return formatter.string(from: date)
    }
    
    @ViewBuilder
    private var backgroundView: some View {
        if let weatherCondition = viewModel.weather?.weather.first?.description.lowercased() {
            Group {
                switch weatherCondition {
                case let condition where condition.contains("clear"):
                    SunnyAnimationView()
                case let condition where condition.contains("cloud"):
                    CloudyAnimationView()
                case let condition where condition.contains("rain"):
                    RainyAnimationView()
                case let condition where condition.contains("thunder"):
                    ThunderstormAnimationView()
                case let condition where condition.contains("snow"):
                    SnowyAnimationView()
                case let condition where condition.contains("mist") || condition.contains("fog"):
                    FoggyAnimationView()
                default:
                    DefaultAnimationView()
                }
            }
            .transition(.opacity)
            .animation(.easeInOut(duration: 1), value: weatherCondition)
        } else {
            DefaultAnimationView()
        }
    }
}

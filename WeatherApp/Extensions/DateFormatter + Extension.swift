//
//  DateFormatter + Extension.swift
//  WeatherApp
//
//  Created by M W on 21/10/2024.
//

import Foundation

extension DateFormatter {
    static var shortDate: DateFormatter {
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        return formatter
    }
}

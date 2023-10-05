//
//  File.swift
//  
//
//  Created by Devon Martin on 10/3/23.
//

import Foundation

extension Date {
	
	/// Parses the input string to extract and validate the month and day.
	/// Returns a tuple containing the number and text representation of the date if valid.
	static func parse(string: String) -> (number: String, text: String)? {
		guard let date = Int(string) else { return nil }
		
		let month = date / 100
		let day = date % 100
		if month >= 1, month <= 12, day >= 1, day <= daysInMonth(month) {
			let monthName = DateFormatter().shortMonthSymbols[month - 1]
			return (number: string, text: "\(monthName) \(day)")
		}
		return nil
	}
	
	/// Returns the number of days in the month in the current year.
	///
	/// Month is an integer representation of the month. January is 1, February is 2, ...
	static func daysInMonth(_ month: Int) -> Int {
		
		let year = Calendar(identifier: .gregorian).dateComponents([.year], from: .now).year
		
		let dateComponents = DateComponents(year: year, month: month)
		let calendar = Calendar.current
		let date = calendar.date(from: dateComponents)!
		
		let range = calendar.range(of: .day, in: .month, for: date)!
		return range.count
	}
}

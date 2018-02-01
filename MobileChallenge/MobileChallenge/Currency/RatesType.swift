//
//  RatesType.swift
//  MobileChallenge
//
//  Created by Michael Lo on 2018-01-31.
//  Copyright © 2018 Michael Lo. All rights reserved.
//

import Foundation

protocol RatesType {
    var base: String { get }
    var rates: [String: Double] { get }
    var retrieved: Date? { get set }
}

// Should match `http://fixer.io` API rate format
struct FixerRates: RatesType, Codable {
    let base: String
    let rates: [String: Double]
    var retrieved: Date?
}

//
//  RateError.swift
//  MobileChallenge
//
//  Created by Michael Lo on 2018-01-31.
//  Copyright © 2018 Michael Lo. All rights reserved.
//

import Foundation

enum RateError: Swift.Error {
    /// API URL must be valid
    case invalidAPIURL
    /// Server returned an error response
    case responseInvalid(Error?)
    /// JSON from server could not be parsed into our object
    case parsingFailed(Error)
}

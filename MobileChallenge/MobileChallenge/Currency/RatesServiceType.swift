//
//  RatesServiceType.swift
//  MobileChallenge
//
//  Created by Michael Lo on 2018-01-31.
//  Copyright © 2018 Michael Lo. All rights reserved.
//

import Foundation
import RxSwift

protocol RatesServiceType {
    func retrieveCache() -> RatesType?
    func cacheRates(_ rates: RatesType)
    func getRates() -> Single<RatesType>
}

private extension String {
    static let RatesKey = "RatesKey"
}

final class FixerExchangeService: RatesServiceType {
    func retrieveCache() -> RatesType? {
        guard let data = UserDefaults.standard.data(forKey: .RatesKey) else { return nil }
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        do {
            let rates = try decoder.decode(FixerRates.self, from: data)
            return rates
        }
        catch {
            print ("Error \(error)")
            return nil
        }
    }
    
    func cacheRates(_ rates: RatesType) {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        if let fixer = rates as? FixerRates {
            if let encoded = try? encoder.encode(fixer) {
                UserDefaults.standard.set(encoded, forKey: .RatesKey)
            }
        }
    }
    
    func getRates() -> Single<RatesType> {
        let config = URLSessionConfiguration.default
        let session = URLSession(configuration: config)
        let apiUrlString = "https://api.fixer.io/latest"
        guard let url = URL(string: apiUrlString) else {
            return .error(RateError.invalidAPIURL)
        }
        
        return Single.create { observer in
            let task = session.dataTask(with: url, completionHandler: { data, response, error in
                guard error == nil, let data = data else {
                    return observer(.error(RateError.responseInvalid(error)))
                }
                
                // attempt to parse based on `fixer.io` format
                var rates: FixerRates
                let decoder = JSONDecoder()
                do {
                    rates = try decoder.decode(FixerRates.self, from: data)
                    // Add the base rate to the list
                    rates.rates[rates.base] = 1.0
                    rates.retrieved = Date()
                }
                catch {
                    return observer(.error(RateError.parsingFailed(error)))
                }
                
                // hooray
                observer(.success(rates))
            })
            task.resume()
            return Disposables.create {
                task.cancel()
            }
        }
    }
}


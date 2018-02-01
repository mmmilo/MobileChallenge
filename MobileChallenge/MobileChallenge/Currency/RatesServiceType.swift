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
    func getRates() -> Single<RatesType>
}

final class RatesService: RatesServiceType {
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


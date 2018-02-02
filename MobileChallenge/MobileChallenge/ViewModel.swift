//
//  ViewModel.swift
//  MobileChallenge
//
//  Created by Michael Lo on 2018-01-31.
//  Copyright © 2018 Michael Lo. All rights reserved.
//

import Foundation
import RxSwift
import RxCocoa

struct Currency {
    let currency: String
    let value: String
}

class ViewModel {
    private let defaultCurrency = "EUR"
    private let timeLimit: TimeInterval = 60 * 30 // ie. 30 minutes
    
    private let disposeBag = DisposeBag()
    private let dateformatter: DateFormatter = {
        let d = DateFormatter()
        d.dateStyle = .medium
        d.timeStyle = .medium
        return d
    }()
    
    private lazy var baseCurrencySubject: BehaviorRelay<String> = {
        return BehaviorRelay<String>(value: self.defaultCurrency)
    }()
    private let updating = BehaviorRelay<Bool>(value: false)
    private let updatedDateRelay = BehaviorRelay<String>(value: "Last updated: never")
    private let currenciesRelay = BehaviorRelay<[Currency]>(value: [])
    
    private let valueInput: Signal<Double>
    private let ratesService: RatesServiceType
    private let requestCurrencyListObservable: Observable<Void>
    
    /**
     ratesService: DI for RatesServiceType
     requestCurrencyListObservable: Observable to listen to when requesting an update for the list of available currencies
     valueInput: Driver for requesting the currency value to be converted
    */
    init(ratesService: RatesServiceType, requestCurrencyListObservable: Observable<Void>, valueInput: Signal<Double>) {
        self.ratesService = ratesService
        self.requestCurrencyListObservable = requestCurrencyListObservable
        self.valueInput = valueInput.throttle(1)

        var value: Double = 0
        var base: String = ""
        
        /*
        Request updating the rates if the user:
         1) Enters a new value
         2) Attempts to change the base currency
        */
        Observable.combineLatest(self.valueInput.asObservable(), baseCurrencySubject)
            // this filter helps catch if we show/hide the keyboard
            .filter { $0.0 != value || $0.0 == value && $0.1 != base }
            .flatMapLatest { [unowned self] values -> Observable<RatesType> in
                value = values.0
                base = values.1
                return self.updateRates().asObservable()
            }
            .map { rates -> [Currency] in
                return self.generateCurrencies(from: rates, baseCurrency: base, value: value)
            }
            .bind(to: currenciesRelay)
            .disposed(by: disposeBag)
        
        // fire off updating the rates on start
        updateRates().subscribe().disposed(by: disposeBag)
    }
}

extension ViewModel {
    func setBaseCurrency(to currency: String) {
        baseCurrencySubject.accept(currency)
    }
    
    private func generateCurrencies(from rates: RatesType, baseCurrency: String, value: Double) -> [Currency] {
        let formatter = NumberFormatter()
        formatter.usesGroupingSeparator = true
        formatter.groupingSeparator = ""
        formatter.groupingSize = 3
        formatter.minimumFractionDigits = 2;
        formatter.maximumFractionDigits = 2;
        formatter.minimumIntegerDigits = 1
        
        // map the retrieved rates to a UI-ready struct
        let currencies: [Currency] = rates.rates.sorted(by: <).flatMap { r in
            let (currency, rate) = r
            
            // perform conversion from
            // baseCurrency -> our internal baseCurrency -> "current" currency
            guard let baseRate = rates.rates[baseCurrency] else {
                return nil
            }
            let converted = (value / baseRate) * rate
            
            // convert to a `xxx.yy` string format
            guard let stringValue = formatter.string(from: converted as NSNumber) else {
                return nil
            }
            return Currency(currency: currency, value: stringValue)
        }
        return currencies
    }
    
    private func updateRates() -> Single<RatesType> {
        // check local disk for cached rates
        let cached = ratesService.retrieveCache()
        let dateLimit = Date(timeIntervalSinceNow: -timeLimit)
    
        updating.accept(true)
        let updater: Single<RatesType>
        // retrieve from server only if past a certain date
        if let cached = cached, let retrieveDate = cached.retrieved, retrieveDate > dateLimit {
            updater = Single.just(cached)
        }
        else {
            updater = ratesService.getRates()
                .do(onSuccess: { [unowned self] rates in
                    // cache the rates we retrieve from the server
                    self.ratesService.cacheRates(rates)
                })
        }
        return updater
            .do(onSuccess: { [unowned self] rates in
                let time: String
                if let retrieved = rates.retrieved {
                    time = self.dateformatter.string(from: retrieved)
                }
                else {
                    time = "never"
                }
                self.updatedDateRelay.accept("Last updated: \(time)")
            },
                onDispose: {
                self.updating.accept(false)
            })
    }
    
    
}

extension ViewModel {
    var isUpdating: Driver<Bool> {
        return updating.asDriver()
    }
    
    var baseCurrency: Driver<String> {
        return baseCurrencySubject.asDriver()
    }
    
    var currencies: Observable<[Currency]> {
        return currenciesRelay.asObservable()
    }
    
    var lastUpdated: Driver<String> {
        return updatedDateRelay.asDriver()
    }
    
    var requestedChangeCurrency: Observable<[Currency]> {
        return requestCurrencyListObservable
            .flatMap { [unowned self] _ in self.updateRates() }
            .map { [unowned self] rates -> [Currency] in
                // baseCurrency/value don't matter here,
                // we are just updating the list of available currencies
                return self.generateCurrencies(from: rates, baseCurrency: self.defaultCurrency, value: 1)
            }
            .subscribeOn(MainScheduler.instance)
    }
}

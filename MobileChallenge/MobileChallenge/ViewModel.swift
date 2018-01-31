//
//  ViewModel.swift
//  MobileChallenge
//
//  Created by Michael Lo on 2018-01-31.
//  Copyright © 2018 Michael Lo. All rights reserved.
//

import Foundation

class ViewModel {
    init() {
        
    }
}

extension ViewModel {
    var numberOfCurrencies: Int {
        return 10
    }
    
    func currency(at row: Int) -> String {
        return "CAD"
    }
    
    func value(at row: Int) -> String {
        return "0.00"
    }
}

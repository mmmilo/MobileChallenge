//
//  RateCollectionViewCell.swift
//  MobileChallenge
//
//  Created by Michael Lo on 2018-01-31.
//  Copyright © 2018 Michael Lo. All rights reserved.
//

import Foundation
import UIKit

class RateCollectionViewCell: UICollectionViewCell {
    @IBOutlet private weak var currencyLabel: UILabel!
    @IBOutlet private weak var valueLabel: UILabel!
    
    func setup(with currency: Currency) {
        currencyLabel.text = currency.currency
        valueLabel.text = currency.value
    }
}

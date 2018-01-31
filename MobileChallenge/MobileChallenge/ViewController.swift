//
//  ViewController.swift
//  MobileChallenge
//
//  Created by Michael Lo on 2018-01-30.
//  Copyright © 2018 Michael Lo. All rights reserved.
//

import UIKit

class ViewController: UIViewController {
    private let CellIdentifier = "CellIdentifier"
    
    @IBOutlet weak var inputTextfield: UITextField!
    @IBOutlet weak var currencyButton: UIButton!
    @IBOutlet weak var collectionView: UICollectionView!
    private let viewModel = ViewModel()

    override func viewDidLoad() {
        super.viewDidLoad()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
}

extension ViewController: UICollectionViewDataSource {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return viewModel.numberOfCurrencies
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: CellIdentifier, for: indexPath) as? RateCollectionViewCell else {
            fatalError("Unexpected cell type")
        }
        return cell
    }
}

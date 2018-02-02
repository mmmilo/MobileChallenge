//
//  ViewController.swift
//  MobileChallenge
//
//  Created by Michael Lo on 2018-01-30.
//  Copyright © 2018 Michael Lo. All rights reserved.
//

import UIKit
import RxSwift
import RxCocoa

class ViewController: UIViewController {
    private let CellIdentifier = "CellIdentifier"
    
    @IBOutlet weak var inputTextfield: UITextField!
    @IBOutlet weak var currencyButton: UIButton!
    @IBOutlet weak var lastUpdatedLabel: UILabel!
    @IBOutlet weak var collectionView: UICollectionView!
    
    // injection of depdencies
    private lazy var viewModel: ViewModel = {
        let ratesService = FixerExchangeService()
        let valueInput: Signal<Double> = inputTextfield.rx.text.orEmpty.map { Double($0) }.filter { $0 != nil}.map { $0! }.asSignal(onErrorJustReturn: 0)
        let requestCurrencyListObservable = currencyButton.rx.tap.asObservable()
        return ViewModel(ratesService: ratesService, requestCurrencyListObservable: requestCurrencyListObservable, valueInput: valueInput)
    }()
    private let disposeBag = DisposeBag()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // tap to dismiss keyboard
        let tapBackground = UITapGestureRecognizer()
        tapBackground.rx.event
            .subscribe(onNext: { [weak self] _ in
                self?.view.endEditing(true)
            })
            .disposed(by: disposeBag)
        view.addGestureRecognizer(tapBackground)
        
        viewModel.currencies
            .bind(to: collectionView.rx.items(cellIdentifier: CellIdentifier, cellType: RateCollectionViewCell.self)) { (row, element, cell) in
                cell.setup(with: element)
            }
            .disposed(by: disposeBag)
        
        viewModel.isUpdating
            .drive(onNext: { [weak self] isUpdating in
                guard let `self` = self else { return }
                let alpha: CGFloat = isUpdating ? 0.5 : 1.0
                self.collectionView.alpha = alpha
                self.currencyButton.alpha = alpha
                self.currencyButton.isEnabled = !isUpdating
            })
            .disposed(by: disposeBag)
        
        viewModel.lastUpdated
            .drive(lastUpdatedLabel.rx.text)
            .disposed(by: disposeBag)
        
        viewModel.baseCurrency
            .drive(currencyButton.rx.title())
            .disposed(by: disposeBag)
        
        viewModel.requestedChangeCurrency
            .subscribe(onNext: { [weak self] currencies in
                guard let `self` = self else { return }
                let alert = UIAlertController(title: nil, message: "Select a base currency", preferredStyle: .actionSheet)
                
                // selecting a currency
                for currency in currencies {
                    let action = UIAlertAction(title: currency.currency, style: .default) { [weak self] _ in
                        self?.viewModel.setBaseCurrency(to: currency.currency)
                    }
                    alert.addAction(action)
                }
                // cancel
                let cancel = UIAlertAction(title: "Cancel", style: .cancel)
                alert.addAction(cancel)
                
                DispatchQueue.main.async {
                    self.present(alert, animated: true, completion: nil)
                }
            })
            .disposed(by: disposeBag)
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
}

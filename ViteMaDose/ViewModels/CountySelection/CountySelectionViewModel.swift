//
//  CountySelectionViewModel.swift
//  ViteMaDose
//
//  Created by Paul Jeannot on 08/04/2021.
//

import Foundation

protocol CountySelectionViewModelProvider {
    var numberOfRows: Int { get }
    func cellViewModel(at indexPath: IndexPath) -> CountyCellViewDataProvider?
    func didSelectCell(at indexPath: IndexPath)
}

protocol CountySelectionViewModelDelegate: AnyObject {
    func reloadTableView(with counties: Counties)
    func dismissViewController(with county: County)
}

class CountySelectionViewModel: CountySelectionViewModelProvider {
    private let apiService: APIServiceProvider
    private let userDefaults: UserDefaults
    weak var delegate: CountySelectionViewModelDelegate?

    private var allCounties: [County] = []

    var numberOfRows: Int {
        allCounties.count
    }

    // MARK: init

    required init(
        apiService: APIServiceProvider = APIService(),
        counties: Counties,
        userDefaults: UserDefaults = .shared
    ) {
        self.apiService = apiService
        self.allCounties = counties
        self.userDefaults = userDefaults

        delegate?.reloadTableView(with: counties)
    }

    func cellViewModel(at indexPath: IndexPath) -> CountyCellViewDataProvider? {
        guard let county = allCounties[safe: indexPath.row] else {
            assertionFailure("No county found at IndexPath \(indexPath)")
            return nil
        }

        guard let countyName = county.nomDepartement,
              let countyCode = county.codeDepartement
        else {
            return nil
        }

        return CountyCellViewData(
            countyName: countyName,
            countyCode: countyCode
        )
    }

    func didSelectCell(at indexPath: IndexPath) {
        guard let county = allCounties[safe: indexPath.row] else {
            assertionFailure("County not found at indexPath \(indexPath)")
            return
        }

        userDefaults.lastSelectedCountyCode = county.codeDepartement
        delegate?.dismissViewController(with: county)
    }
}

//
//  VaccinationCentresViewModel.swift
//  ViteMaDose
//
//  Created by Victor Sarda on 09/04/2021.
//

import Foundation
import SwiftDate
import UIKit

protocol VaccinationCentresViewModelProvider {
    var county: County { get }
    var numberOfRows: Int { get }
    func fetchVaccinationCentres()
    func cellViewModel(at indexPath: IndexPath) -> VaccinationBookingCellViewModelProvider?
    func bookingLink(at indexPath: IndexPath) -> URL?
}

protocol VaccinationCentresViewModelDelegate: class {
    func reloadTableView(isEmpty: Bool)
    func updateLoadingState(isLoading: Bool)
    func displayError(withMessage message: String)
}

class VaccinationCentresViewModel: VaccinationCentresViewModelProvider {
    private let apiService: APIService
    private var allVaccinationCentres: [VaccinationCentre] = []
    private var isLoading = false {
        didSet {
            delegate?.updateLoadingState(isLoading: isLoading)
        }
    }

    var county: County
    weak var delegate: VaccinationCentresViewModelDelegate?

    var numberOfRows: Int {
        return allVaccinationCentres.count
    }

    init(apiService: APIService = APIService(), county: County) {
        self.apiService = apiService
        self.county = county
    }

    func cellViewModel(at indexPath: IndexPath) -> VaccinationBookingCellViewModelProvider? {
        guard let vaccinationCentre = allVaccinationCentres[safe: indexPath.row] else {
            return nil
        }

        var url: URL?
        if let urlString = vaccinationCentre.url {
            url = URL(string: urlString)
        }

        var dosesText: String?
        if let dosesCount = vaccinationCentre.appointmentCount {
            dosesText = "\(String(dosesCount)) dose(s)"
        }

        let isAvailable = vaccinationCentre.prochainRdv != nil

        var formattedDate: NSMutableAttributedString?
        let region = Region(
            calendar: Calendar.current,
            zone: Zones.current,
            locale: Locale(identifier: "fr_FR")
        )

        var dayString: String?
        var timeString: String?

        if
            let dateString = vaccinationCentre.prochainRdv,
            let date = dateString.toDate(nil, region: region)
        {
            dayString = date.toString(.date(.long))
            timeString = date.toString(.time(.short))
        }

        var partnerLogo: UIImage?
        if let platform = vaccinationCentre.plateforme {
            partnerLogo =  PartnerLogo(rawValue: platform)?.image
        }

        let bookingButtonText = isAvailable ? "Prendre Rendez-Vous" : "Vérifier Ce Centre"
        let imageAttachment = NSTextAttachment()
        imageAttachment.image = UIImage(
            systemName: "arrow.up.right",
            withConfiguration:UIImage.SymbolConfiguration(pointSize: 15, weight: .semibold)
        )?.withTintColor(.white, renderingMode: .alwaysOriginal)

        let bookingButtonAttributedText = NSMutableAttributedString(
            string: bookingButtonText + " ",
            attributes: [
                NSAttributedString.Key.foregroundColor : UIColor.white,
                NSAttributedString.Key.font : UIFont.systemFont(ofSize: 15, weight: .semibold),
            ]
        )

        bookingButtonAttributedText.append(NSAttributedString(attachment: imageAttachment))

        return VaccinationBookingCellViewModel(
            dayText: dayString,
            timeText: timeString,
            addressNameText: vaccinationCentre.nom ?? "Nom du centre indisponible",
            addressText: vaccinationCentre.metadata?.address ?? "Addresse indisponible",
            phoneText: vaccinationCentre.metadata?.phoneNumber,
            bookingButtonText: bookingButtonAttributedText,
            vaccineTypesText: vaccinationCentre.vaccineType?.joined(separator: ", "),
            dosesText: dosesText,
            isAvailable: isAvailable,
            url: url,
            partnerLogo: partnerLogo
        )
    }

    func bookingLink(at indexPath: IndexPath) -> URL? {
        guard
            let bookingUrlString = allVaccinationCentres[safe: indexPath.row]?.url,
            let bookingUrl = URL(string: bookingUrlString),
            bookingUrl.isValid
        else {
            return nil
        }
        return bookingUrl
    }

    private func didFetchVaccinationCentres(_ vaccinationCentres: VaccinationCentres) {
        let isEmpty = vaccinationCentres.centresDisponibles.isEmpty && vaccinationCentres.centresIndisponibles.isEmpty
        allVaccinationCentres = vaccinationCentres.centresDisponibles + vaccinationCentres.centresIndisponibles
        delegate?.reloadTableView(isEmpty: isEmpty)
    }

    private func handleError(_ error: APIEndpoint.APIError) {

    }

    public func fetchVaccinationCentres() {
        guard !isLoading else { return }
        isLoading = true

        guard let countyCode = county.codeDepartement else {
            delegate?.displayError(withMessage: "County code missing")
            return
        }

        let vaccinationCentresEndpoint = APIEndpoint.vaccinationCentres(county: countyCode)

        apiService.fetchVaccinationCentres(vaccinationCentresEndpoint) { [weak self] result in
            self?.isLoading = false

            switch result {
                case let .success(vaccinationCentres):
                    self?.didFetchVaccinationCentres(vaccinationCentres)
                case .failure(let error):
                    self?.handleError(error)
            }
        }
    }
}

private extension Date {
    var formattedDate: String {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "HH:mm E, d MMM y"
        dateFormatter.timeZone = TimeZone.current
        dateFormatter.locale = Locale.current
        return dateFormatter.string(from: self)
    }
}


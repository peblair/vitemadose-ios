//
//  APIService.swift
//  ViteMaDose
//
//  Created by Victor Sarda on 07/04/2021.
//

import Foundation
import APIRequest

protocol APIServiceProvider {
    @discardableResult
    func fetchCounties(completion: @escaping (Counties?, APIResponseStatus) -> Void) -> APIRequest
    @discardableResult
    func fetchVaccinationCentres(country: String, completion: @escaping (VaccinationCentres?, APIResponseStatus) -> Void) -> APIRequest
    @discardableResult
    func fetchStats(completion: @escaping (Stats?, APIResponseStatus) -> Void) -> APIRequest
    @discardableResult
    func fetchContributors(completion: @escaping (Credits?, APIResponseStatus) -> Void) -> APIRequest
}

struct APIService: APIServiceProvider {

    func fetchCounties(completion: @escaping (Counties?, APIResponseStatus) -> Void) -> APIRequest {
        let configuration = APIConfiguration(host: RemoteConfiguration.shared.host)
        return APIRequest(
            "GET",
            path: RemoteConfiguration.shared.countiesListPath,
            configuration: configuration
        ).execute(Counties.self) { data, status in
            DispatchQueue.main.async {
                completion(data, status)
            }
        }
    }

    func fetchVaccinationCentres(country: String, completion: @escaping (VaccinationCentres?, APIResponseStatus) -> Void) -> APIRequest {
        let configuration = APIConfiguration(host: RemoteConfiguration.shared.host)
        return APIRequest(
            "GET",
            path: RemoteConfiguration.shared.countyDataPath(for: country),
            configuration: configuration
        ).execute(VaccinationCentres.self) { data, status in
            DispatchQueue.main.async {
                completion(data, status)
            }
        }
    }

    func fetchStats(completion: @escaping (Stats?, APIResponseStatus) -> Void) -> APIRequest {
        let configuration = APIConfiguration(host: RemoteConfiguration.shared.host)
        return APIRequest(
            "GET",
            path: RemoteConfiguration.shared.statsPath,
            configuration: configuration
        ).execute(Stats.self) { data, status in
            DispatchQueue.main.async {
                completion(data, status)
            }
        }
    }
    
    func fetchContributors(completion: @escaping (Credits?, APIResponseStatus) -> ()) -> APIRequest {
        let configuration = APIConfiguration(host: RemoteConfiguration.shared.host)
        return APIRequest(
            "GET",
            path: RemoteConfiguration.shared.contributorsPath,
            configuration: configuration
        ).execute(Credits.self) { data, status in
            DispatchQueue.main.async {
                completion(data, status)
            }
        }
    }

}

extension APIResponseStatus: LocalizedError {
    public var errorDescription: String? {
        switch self {
        case .error:
            return "Nous rencontrons des problèmes avec le serveur, veuillez réessayer plus tard."
        case .offline:
            return "Il semblerait que vous soyez hors ligne."
        default:
            return "Une erreur est survenue, veuillez réessayer plus tard."
        }
    }
}

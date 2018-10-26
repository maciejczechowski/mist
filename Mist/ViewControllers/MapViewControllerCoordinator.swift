//
//  MapViewControllerCoordinator.swift
//  Mist
//
//  Created by Maciej Czechowski on 26.10.2018.
//  Copyright © 2018 Maciej Czechowski. All rights reserved.
//

import Foundation

class MapViewControllerCoordinator {
    func configureMapViewController(controller: MapViewController) -> Void {
        let apiClient = ApiClient(with: URL(string: "http://api.open-notify.org")!)
        let dataStore = DataStore()
        let issLocator = IssLocator(with: apiClient, with: dataStore)
        controller.issLocator = issLocator
    }
}

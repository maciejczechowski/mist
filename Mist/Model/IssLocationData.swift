//
// Created by Maciej Czechowski on 28/10/2018.
// Copyright (c) 2018 Maciej Czechowski. All rights reserved.
//

import Foundation
import CoreLocation

struct IssLocationData {
    let Status: LocationStatus
    let Position: CLLocationCoordinate2D?
    let Timestamp: Date?
}

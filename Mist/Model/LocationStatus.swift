//
// Created by Maciej Czechowski on 28/10/2018.
// Copyright (c) 2018 Maciej Czechowski. All rights reserved.
//

import Foundation

enum LocationStatus: CustomStringConvertible {
    case initializing, ok, offline

    var description: String {
        switch self {
                // Use Internationalization, as appropriate.
        case .initializing: return NSLocalizedString("INITIALIZING", comment: "")
        case .ok: return NSLocalizedString("OK", comment: "")
        case .offline: return NSLocalizedString("OFFLINE", comment: "")
        }
    }
}
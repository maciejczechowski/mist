//
//  IssPosition.swift
//  Mist
//
//  Created by Maciej Czechowski on 24.10.2018.
//  Copyright © 2018 Maciej Czechowski. All rights reserved.
//

import Foundation

struct IssPosition : Codable {
    var message: String
    var timestamp: Date
    var issPosition: Coordinate
    
    enum CodingKeys: String, CodingKey {
        case message
        case timestamp
        case issPosition = "iss_position"

    }
    
}

//
//  IssCrew.swift
//  Mist
//
//  Created by Maciej Czechowski on 24.10.2018.
//  Copyright © 2018 Maciej Czechowski. All rights reserved.
//

import Foundation

struct IssCrew : Codable {
    var message: String
    var number: Int
    var people: [CrewMember]
}

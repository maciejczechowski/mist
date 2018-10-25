//
//  DataStore.swift
//  Mist
//
//  Created by Maciej Czechowski on 25.10.2018.
//  Copyright © 2018 Maciej Czechowski. All rights reserved.
//

import Foundation
import CoreLocation

public protocol DataStoreProtocol {
    var lastKnownPosition: CLLocationCoordinate2D? { get set}
    var lastKnownPositionDate: Date? { get set}
}

extension CLLocationCoordinate2D {
    
    private static let Lat = "lat"
    private static let Lon = "lon"
    
    typealias CLLocationDictionary = [String: CLLocationDegrees]
    
    var asDictionary: CLLocationDictionary {
        return [CLLocationCoordinate2D.Lat: self.latitude,
                CLLocationCoordinate2D.Lon: self.longitude]
    }
    
    init(dict: CLLocationDictionary) {
        self.init(latitude: dict[CLLocationCoordinate2D.Lat]!,
                  longitude: dict[CLLocationCoordinate2D.Lon]!)
    }
    
}

class DataStore : DataStoreProtocol {
    var lastKnownPosition: CLLocationCoordinate2D? {
        get {
            if let locationDict = UserDefaults.standard.object(forKey: "lastPosition") as? CLLocationCoordinate2D.CLLocationDictionary {
                return CLLocationCoordinate2D(dict: locationDict)
            }
            return nil
        }
        set {
            UserDefaults.standard.set(newValue?.asDictionary, forKey: "lastPosition")
        }
    }
    
    var lastKnownPositionDate: Date? {
        get {
            return UserDefaults.standard.object(forKey: "lastTimestamp") as? Date
        }
        set {
            UserDefaults.standard.set(newValue, forKey: "lastTimestamp")
        }
    }
    
    
}

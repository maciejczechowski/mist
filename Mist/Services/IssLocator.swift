//
//  IssLocator.swift
//  Mist
//
//  Created by Maciej Czechowski on 24.10.2018.
//  Copyright © 2018 Maciej Czechowski. All rights reserved.
//

import Foundation
import RxSwift
import CoreLocation
import RxCocoa

enum LocationStatus {
    case initializing, ok, offline
}

enum MistError: Error {
    case nonSucccess
}

struct IssLocationData {
    let Status: LocationStatus
    let Position: CLLocationCoordinate2D?
    let Timestamp: Date?
}

protocol IssLocatorProtocol {
     func getIssPositions(withInterval seconds: Int) -> Observable<IssLocationData>
}
public class IssLocator : IssLocatorProtocol {

    private let scheduler: SchedulerType;
    private let issApiClient: ApiClientProtocol
    private var dataStore: DataStoreProtocol

    private var lastStoredDate: Date? {
        get {
            return dataStore.lastKnownPositionDate
        }
        set {
            dataStore.lastKnownPositionDate = newValue
        }
    }

    private var lastStoredPosition: CLLocationCoordinate2D? {
        get {
            return dataStore.lastKnownPosition
        }
        set {
            dataStore.lastKnownPosition = newValue
        }
    }


    init(with apiClient: ApiClientProtocol, with dataStore: DataStoreProtocol, using scheduler: SchedulerType = ConcurrentDispatchQueueScheduler(qos: .background)) {
        self.scheduler = scheduler
        self.issApiClient = apiClient
        self.dataStore = dataStore

    }


    func getIssPositions(withInterval seconds: Int) -> Observable<IssLocationData> {
        let networkPositionFetch =
                Observable<Int>
                        .interval(RxTimeInterval(seconds), scheduler: scheduler)
                        .flatMapLatest { _ in
                            self.getPosition().catchError { (err) -> Observable<IssLocationData> in
                                return Observable.just(IssLocationData(Status: LocationStatus.offline, Position: nil, Timestamp: Date()))
                            }
                        }
                        .do(onNext: { (position) in
                            if let cooridnate = position.Position {
                              self.lastStoredPosition = cooridnate
                              self.lastStoredDate = position.Timestamp
                            }
                        })
        
        
        
        let initial = Observable<IssLocationData>.just(IssLocationData(Status: LocationStatus.initializing, Position: lastStoredPosition, Timestamp: lastStoredDate))
        return initial.concat(networkPositionFetch);
    }


    private func getPosition() -> Observable<IssLocationData> {

        return issApiClient
                .getAndParseResponse(t: IssPosition.self, for: "iss-now.json")
                .map { issPosition in
                    guard issPosition.message == "success" else {
                        throw MistError.nonSucccess
                    }
                    
                    var coordinate: CLLocationCoordinate2D?
                    if let position = issPosition.issPosition {
                       coordinate =  CLLocationCoordinate2D(latitude: position.latitude, longitude: position.longitude)
                    }
                    
                    return IssLocationData(Status: LocationStatus.ok,
                                           Position: coordinate,
                            Timestamp: issPosition.timestamp)

                };
    }


}

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


protocol IssLocatorProtocol {
    func getIssPositions(with interval: TimeInterval) -> Observable<IssLocationData>
    func getIssCrew() -> Observable<[String]>
}

public class IssLocator: IssLocatorProtocol {
    


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


    func getIssPositions(with interval: TimeInterval) -> Observable<IssLocationData> {
        let networkPositionFetch =
                Observable<Int>
                        .interval(interval, scheduler: scheduler)
                        .flatMapLatest { _ in
                            self.getPosition().catchError { (err) -> Observable<IssLocationData> in
                                return Observable.just(IssLocationData(Status: LocationStatus.offline, Position: self.lastStoredPosition, Timestamp: self.lastStoredDate))
                            }
                        }
                        .do(onNext: { (position) in
                            if let coordinate = position.Position {
                                self.lastStoredPosition = coordinate
                                self.lastStoredDate = position.Timestamp
                            }
                        })


        let initial = Observable<IssLocationData>.just(
            IssLocationData(Status: LocationStatus.initializing, Position: lastStoredPosition, Timestamp: lastStoredDate))
        return initial.concat(networkPositionFetch);
    }


    func getIssCrew() -> Observable<[String]> {
        return issApiClient
            .getAndParseResponse(t: IssCrew.self, for: "astros.json")
            .map { issCrew in
                guard issCrew.message == "success" else {
                    throw MistError.nonSucccess
                }
                
                return issCrew.people.filter{ crewMember in crewMember.craft == "ISS"}.map{crewMember in crewMember.name }
        };
    }
    
    private func getPosition() -> Observable<IssLocationData> {

        return issApiClient
                .getAndParseResponse(t: IssPosition.self, for: "iss-now.json")
                .map { issPosition in
                    guard issPosition.message == "success" else {
                        throw MistError.nonSucccess
                    }

                    var coordinate: CLLocationCoordinate2D?
                    if let latitudeString = issPosition.issPosition?.latitude,
                       let longitudeString = issPosition.issPosition?.longitude,
                       let latitude = Double(latitudeString),
                       let longitude = Double(longitudeString) {
                        coordinate = CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
                    } else {
                        throw MistError.conversionError
                    }

                    return IssLocationData(Status: LocationStatus.ok,
                            Position: coordinate,
                            Timestamp: issPosition.timestamp)

                };
    }


}

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
    let Timestamp: Date
}

public class IssLocator {

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
                            self.getPosition()
                        }
                        .do(onNext: { (position) in
                            self.lastStoredPosition = position.Position
                            self.lastStoredDate = position.Timestamp
                        })
                        .catchError { (err) -> Observable<IssLocationData> in
                            return Observable.just(IssLocationData(Status: LocationStatus.offline, Position: nil, Timestamp: Date()))
                        }
        
        let initial = Observable<IssLocationData>.just(IssLocationData(Status: LocationStatus.initializing, Position: lastStoredPosition, Timestamp: lastStoredDate ?? Date()))
        return initial.concat(networkPositionFetch);
    }


    private func getPosition() -> Observable<IssLocationData> {

        return issApiClient
                .getAndParseResponse(t: IssPosition.self, for: "iss-now.json")
                .map { issPosition in
                    guard issPosition.message == "success" else {
                        throw MistError.nonSucccess
                    }
                    return IssLocationData(Status: LocationStatus.ok,
                            Position: CLLocationCoordinate2D(latitude: issPosition.issPosition.latitude, longitude: issPosition.issPosition.longitude),
                            Timestamp: Date())

                };
    }


}

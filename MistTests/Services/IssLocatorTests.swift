//
//  IssLocatorTests.swift
//  MistTests
//
//  Created by Maciej Czechowski on 25.10.2018.
//  Copyright © 2018 Maciej Czechowski. All rights reserved.
//

import Foundation
import CoreLocation
import XCTest
import RxSwift
import RxTest
@testable import Mist

class MockDataStore : DataStoreProtocol {
    var lastKnownPosition: CLLocationCoordinate2D?
    var lastKnownPositionDate: Date?
}

class MockApiClient : ApiClientProtocol{
    
    var responseMock : Any?
    
    func getAndParseResponse<T>(t: T.Type, for path: String) -> Observable<T> where T : Codable {
        return responseMock as! Observable<T>
    }
    
}

class IssLocatorTests : XCTestCase {
    
    var mockedDataStore : MockDataStore!
    var mockedApiClient : MockApiClient!
    var testedIssLocator : IssLocator!
    var testScheduler: TestScheduler!
    
    override func setUp() {
        mockedDataStore = MockDataStore()
        mockedApiClient = MockApiClient()
        testScheduler = TestScheduler(initialClock: 0)
        testedIssLocator = IssLocator(with: mockedApiClient!, with: mockedDataStore!, using: testScheduler!)
    }
    
    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }
    
    func testGetIssPositionsStartsWithStoredDataIfPresent() {
        mockedApiClient.responseMock = Observable<IssPosition>.never()
        
        mockedDataStore.lastKnownPosition = CLLocationCoordinate2D(latitude: 21, longitude: 52)
        mockedDataStore.lastKnownPositionDate = Date(timeIntervalSince1970: 1540473254)
        
        
        let res = testScheduler.start{ self.testedIssLocator!.getIssPositions(with: 10.0)}
        XCTAssertEqual(1, res.events.count)
   
        XCTAssertEqual(21, res.events[0].value.element!.Position!.latitude)
        XCTAssertEqual(52, res.events[0].value.element!.Position!.longitude)
        XCTAssertEqual(1540473254, res.events[0].value.element!.Timestamp!.timeIntervalSince1970)
        XCTAssertEqual(LocationStatus.initializing, res.events[0].value.element!.Status)
        
    }

    func testGetIssPositionsStartsWithEmptyDataIfNotInStore() {
        mockedApiClient.responseMock = Observable<IssPosition>.never()
        
        let res = testScheduler.start{ self.testedIssLocator!.getIssPositions(with: 10.0)}
        XCTAssertEqual(1, res.events.count)
        
        XCTAssertNil(res.events[0].value.element!.Position)
        XCTAssertNil(res.events[0].value.element!.Timestamp)
        XCTAssertEqual(LocationStatus.initializing, res.events[0].value.element!.Status)
        
    }

     func testGetIssPositionsUpdatesFromNetworkOnGivenInterval() {
        
        var lat = 51.0
        var lon = 22.0
        var timestamp = testScheduler!.now
        
        let fakeIssRoute = Observable<IssPosition>.create { observer in
            timestamp = self.testScheduler!.now
            observer.onNext(IssPosition(message: "success",
                                        timestamp: timestamp, issPosition: Coordinate(latitude: lat.description, longitude: lon.description)))
            lat += 1
            lon += 1
            
            observer.onCompleted()
            return Disposables.create()
        }
        
        mockedApiClient.responseMock = fakeIssRoute

        //time 200-1000, 4 events expected: (200: initial), (450,700,950: value)
        let res = testScheduler.start{ self.testedIssLocator!.getIssPositions(with: 250) }
  
 
        XCTAssertEqual(4, res.events.count)
        XCTAssertNil(res.events[0].value.element?.Position)
        XCTAssertEqual(LocationStatus.initializing, res.events[0].value.element?.Status)
        
      
        XCTAssertEqual(LocationStatus.ok, res.events[1].value.element?.Status)
        XCTAssertEqual(51.0, res.events[1].value.element?.Position?.latitude)
        XCTAssertEqual(22.0, res.events[1].value.element?.Position?.longitude)
        XCTAssertEqual(Date(timeIntervalSince1970: 450), res.events[1].value.element?.Timestamp)
        XCTAssertEqual(450, res.events[1].time)
        

        XCTAssertEqual(LocationStatus.ok, res.events[2].value.element?.Status)
        XCTAssertEqual(52.0, res.events[2].value.element?.Position?.latitude)
        XCTAssertEqual(23.0, res.events[2].value.element?.Position?.longitude)
        XCTAssertEqual(Date(timeIntervalSince1970: 700), res.events[2].value.element?.Timestamp)
        XCTAssertEqual(700, res.events[2].time)
        
        XCTAssertEqual(LocationStatus.ok, res.events[3].value.element?.Status)
        XCTAssertEqual(53.0, res.events[3].value.element?.Position?.latitude)
        XCTAssertEqual(24.0, res.events[3].value.element?.Position?.longitude)
        XCTAssertEqual(Date(timeIntervalSince1970: 950), res.events[3].value.element?.Timestamp)
        XCTAssertEqual(950, res.events[3].time)
        
    }
    
    func testGetIssPositionsRecoversOnNetworkFailure() {
        var lat = 51.0
        let lon = 22.0
        var timestamp = testScheduler.now
        var iter = 0
        
        let fakeIssRoute = Observable<IssPosition>.create { observer in
            timestamp = self.testScheduler!.now
            
            let scenario = iter % 3;
            switch scenario {
            case 1:
                observer.onNext(IssPosition(message: "failure",
                                            timestamp: timestamp, issPosition: nil))
            case 2:
                observer.onError(NSError(domain: NSURLErrorDomain, code: NSURLErrorTimedOut, userInfo: nil))
          
            default:
                observer.onNext(IssPosition(message: "success",
                                            timestamp: timestamp, issPosition: Coordinate(latitude: lat.description, longitude: lon.description)))
                lat += 1
           }
            iter += 1
            
            observer.onCompleted()
            return Disposables.create()
        }
        
        mockedApiClient.responseMock = fakeIssRoute
        
        //time 200-1000, step by 200, 6 events expected: 200: initial, 350: ok, 500: offline, 650: offline, 800 ok, 950 offline
        let res = testScheduler.start{ self.testedIssLocator!.getIssPositions(with: 150) }
        
        
        XCTAssertEqual(6, res.events.count)
        XCTAssertNil(res.events[0].value.element?.Position)
        XCTAssertEqual(LocationStatus.initializing, res.events[0].value.element?.Status)
        
        
        XCTAssertEqual(LocationStatus.ok, res.events[1].value.element?.Status)
        XCTAssertEqual(51.0, res.events[1].value.element?.Position?.latitude)
        XCTAssertEqual(22.0, res.events[1].value.element?.Position?.longitude)
        
        
        XCTAssertEqual(LocationStatus.offline, res.events[2].value.element?.Status)
        XCTAssertEqual(51.0, res.events[2].value.element?.Position?.latitude)
     
        XCTAssertEqual(LocationStatus.offline, res.events[3].value.element?.Status)
        XCTAssertEqual(51.0, res.events[3].value.element?.Position?.latitude)
        
        XCTAssertEqual(LocationStatus.ok, res.events[4].value.element?.Status)
        XCTAssertEqual(52.0, res.events[4].value.element?.Position?.latitude)
        XCTAssertEqual(22.0, res.events[4].value.element?.Position?.longitude)
        
        
        XCTAssertEqual(LocationStatus.offline, res.events[5].value.element?.Status)
        XCTAssertEqual(52.0, res.events[5].value.element?.Position?.latitude)
        
    }
    
    func testGetIssPositionsUpdatesDataInStoreOnSuccess() {
        let lat = 51.0
        let lon = 22.0
        var timestamp = testScheduler.now
        var iter = 0
        
        let fakeIssRoute = Observable<IssPosition>.create { observer in
            timestamp = self.testScheduler.now
            
            let scenario = iter % 3;
            switch scenario {
            case 1:
                observer.onNext(IssPosition(message: "failure",
                                            timestamp: timestamp, issPosition: nil))
            case 2:
                observer.onError(NSError(domain: NSURLErrorDomain, code: NSURLErrorTimedOut, userInfo: nil))
                
            default:
                observer.onNext(IssPosition(message: "success",
                                            timestamp: timestamp, issPosition: Coordinate(latitude: lat.description, longitude: lon.description)))
               
            }
            iter += 1
            
            observer.onCompleted()
            return Disposables.create()
        }
        
        mockedApiClient.responseMock = fakeIssRoute
        
        XCTAssertNil(mockedDataStore.lastKnownPosition)
        XCTAssertNil(mockedDataStore.lastKnownPositionDate)
        
        
        
        //time 200-1000, step by 200, events expected: 200: initial, 400: ok, 600: offline, 800: offline
        let res = testScheduler.start{ self.testedIssLocator!.getIssPositions(with: 200) }
            XCTAssertEqual(4, res.events.count)
        
          XCTAssertEqual(mockedDataStore.lastKnownPosition?.latitude,51.0)
                XCTAssertEqual(mockedDataStore.lastKnownPosition?.longitude,22.0)
                XCTAssertEqual(mockedDataStore.lastKnownPositionDate, Date(timeIntervalSince1970: 400))
    }
    
    func testGetCrewFailsOnNonSuccessMessage()
    {
        mockedApiClient.responseMock = Observable.just(IssCrew(message: "failure", number: 0, people: []))
        let res = testScheduler.start{ self.testedIssLocator.getIssCrew() }
        XCTAssertEqual(1, res.events.count)
        XCTAssertEqual(MistError.nonSucccess, res.events[0].value.error as? MistError)
        
    }
    
    func testGetCrewReturnsOnlyISSCrew()
    {
        mockedApiClient.responseMock = Observable.just(IssCrew(message: "success", number: 5, people: [
            CrewMember(name: "John Doe", craft: "ISS"),
            CrewMember(name: "Darth Vader", craft: "Death Star"),
            CrewMember(name: "Starman", craft: "Tesla Roadser"),
            CrewMember(name: "John Kowalski", craft: "ISS"),
            ]))
        let res = testScheduler.start{ self.testedIssLocator.getIssCrew() }
        XCTAssertEqual(2, res.events.count)
        XCTAssertEqual("John Doe",res.events[0].value.element![0])
        XCTAssertEqual("John Kowalski",res.events[0].value.element![1])
        
    }
}

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
    
    var mockedDataStore : MockDataStore?
    var mockedApiClient : MockApiClient?
    var testedIssLocator : IssLocator?
    var testScheduler: TestScheduler?
    
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
        mockedApiClient?.responseMock = Observable<IssPosition>.never()
        
        mockedDataStore?.lastKnownPosition = CLLocationCoordinate2D(latitude: 21, longitude: 52)
        mockedDataStore?.lastKnownPositionDate = Date(timeIntervalSince1970: 1540473254)
        
        
        let res = testScheduler?.start{ self.testedIssLocator!.getIssPositions(withInterval: 10)}
        XCTAssertEqual(1, res?.events.count)
   
        XCTAssertEqual(21, res!.events[0].value.element!.Position!.latitude)
        XCTAssertEqual(52, res!.events[0].value.element!.Position!.longitude)
        XCTAssertEqual(1540473254, res!.events[0].value.element!.Timestamp.timeIntervalSince1970)
        XCTAssertEqual(LocationStatus.initializing, res!.events[0].value.element!.Status)
        
    }

    func testGetIssPositionsStartsWithEmptyDataIfNotInStore() {
        mockedApiClient?.responseMock = Observable<IssPosition>.never()
        
        mockedDataStore?.lastKnownPosition = CLLocationCoordinate2D(latitude: 21, longitude: 52)
        mockedDataStore?.lastKnownPositionDate = Date(timeIntervalSince1970: 1540473254)
        
        
        let res = testScheduler?.start{ self.testedIssLocator!.getIssPositions(withInterval: 10)}
        XCTAssertEqual(1, res?.events.count)
        
        XCTAssertEqual(21, res!.events[0].value.element!.Position!.latitude)
        XCTAssertEqual(52, res!.events[0].value.element!.Position!.longitude)
        XCTAssertEqual(1540473254, res!.events[0].value.element!.Timestamp.timeIntervalSince1970)
        XCTAssertEqual(LocationStatus.initializing, res!.events[0].value.element!.Status)
        
    }

     func testGetIssPositionsUpdatesFromNetworkOnGivenInterval() {
    }
    
    func testGetIssPositionsRecoversOnNetworkFailure() {
    }
    
    func testGetIssPositionsUpdatesDataInStore() {
    }
}

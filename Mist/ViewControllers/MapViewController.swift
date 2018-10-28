//
//  MapViewController.swift
//  Mist
//
//  Created by Maciej Czechowski on 24.10.2018.
//  Copyright © 2018 Maciej Czechowski. All rights reserved.
//

import UIKit
import RxSwift
import Mapbox

class MapViewController: UIViewController, MGLMapViewDelegate {

    let RefreshInterval = TimeInterval(5)

    var disposeBag: DisposeBag!
    var issLocator: IssLocatorProtocol!
    var annotation: MGLPointAnnotation!

    @IBOutlet weak var statusLabel: UILabel!

    @IBOutlet weak var mapView: MGLMapView!


    override func viewDidLoad() {
        super.viewDidLoad()

        mapView.styleURL = MGLStyle.satelliteStreetsStyleURL
        mapView.layer.isOpaque = false
        annotation = MGLPointAnnotation()

    }


    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        self.disposeBag = DisposeBag()
        mapView.delegate = self

        let issResuls = issLocator
                .getIssPositions(with: RefreshInterval)
                .asDriver(onErrorJustReturn: IssLocationData(Status: LocationStatus.offline, Position: nil, Timestamp: Date()))


        issResuls
                .map { issLocationData in
                    self.getStatusLabelText(locationData: issLocationData)
                }
                .drive(statusLabel.rx.attributedText)
                .disposed(by: disposeBag)


        issResuls
                .filter {
                    $0.Position != nil
                }
                .map {
                    $0.Position!
                }
                .drive(onNext: { (coordinate) in
                    if self.mapView.annotations == nil {
                        self.annotation.coordinate = coordinate
                        self.mapView.setCenter(self.annotation.coordinate, zoomLevel: 1, direction: 0, animated: true)
                        self.mapView.addAnnotation(self.annotation)
                    }
                    self.annotation?.coordinate = coordinate

                })
                .disposed(by: disposeBag)

        issResuls
                .map { issLocationData in
                    issLocationData.Status == LocationStatus.ok
                }
                .flatMap { _ in
                    self.issLocator.getIssCrew().asDriver(onErrorJustReturn: [])
                }
                .drive(onNext: { crew in
                    self.annotation.title = crew.joined(separator: "\n")
                })
                .disposed(by: disposeBag)

    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        mapView.delegate = nil
        self.disposeBag = nil
    }

    func mapView(_ mapView: MGLMapView, annotationCanShowCallout annotation: MGLAnnotation) -> Bool {
        // Always allow callouts to popup when annotations are tapped.
        return true
    }

    func mapView(_ mapView: MGLMapView, calloutViewFor annotation: MGLAnnotation) -> MGLCalloutView? {
        // Instantiate and return our custom callout view.
        return MultilineCalloutView(representedObject: annotation)
    }

    func getStatusLabelText(locationData: IssLocationData) -> NSAttributedString {
        let lastSeenTemplate = NSLocalizedString("LAST_SEEN", comment: "last seen: {value}")
        var lastSeenDateString: String
        if let date = locationData.Timestamp {
            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "MMM d, HH:mm:ss"
            dateFormatter.timeZone = NSTimeZone.local
            lastSeenDateString = dateFormatter.string(from: date)
        } else {
            lastSeenDateString = NSLocalizedString("NEVER", comment: "")
        }


        let descriptionString = NSMutableAttributedString(string: String.localizedStringWithFormat(lastSeenTemplate, lastSeenDateString))

        let font = UIFont.preferredFont(forTextStyle: UIFont.TextStyle.subheadline)
        let attributes = [
            NSAttributedString.Key.font: font,
            NSAttributedString.Key.foregroundColor: getStatusColor(for: locationData.Status)
        ]

        let statusString = NSAttributedString(string: "\n● \(locationData.Status.description)", attributes: attributes)
        descriptionString.append(statusString)

        return descriptionString
    }

    func getStatusColor(for status: LocationStatus) -> UIColor {
        switch (status) {

        case .initializing:
            return UIColor.darkGray
        case .ok:
            return UIColor.init(red: 3 / 255.0, green: 125 / 255.0, blue: 80 / 255.0, alpha: 1)
        case .offline:
            return UIColor.orange
        }
    }
}


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

class MapViewController: UIViewController, MGLMapViewDelegate{

    let RefreshInterval = TimeInterval(5)
    
    var disposeBag: DisposeBag!
    var issLocator: IssLocatorProtocol!
    var annotation: MGLPointAnnotation?
    
    @IBOutlet weak var statusLabel: UILabel!
  
    @IBOutlet weak var mapView: MGLMapView!
    
    
    override func viewDidLoad() {
        super.viewDidLoad()

         mapView.styleURL = MGLStyle.satelliteStreetsStyleURL
    }
    
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        self.disposeBag = DisposeBag()
        
        let issResuls = issLocator
            .getIssPositions(with: RefreshInterval)
            .asDriver(onErrorJustReturn: IssLocationData(Status: LocationStatus.offline, Position: nil, Timestamp: Date()))
            
            
            
        issResuls
            .map{ issLocationData in self.getStausLabelText(locationData: issLocationData)}
            .drive(statusLabel.rx.attributedText)
            .disposed(by: disposeBag)
        
  
        issResuls
            .filter{ $0.Position != nil}
            .map { $0.Position!}
            .drive(onNext: { (coordinate) in
                if self.annotation == nil{
                    let annotation = MGLPointAnnotation()
                    annotation.coordinate = coordinate
                    self.mapView.setCenter(annotation.coordinate, zoomLevel: 5, direction: 0, animated: true)
                    self.mapView.addAnnotation(annotation)
                    self.annotation = annotation
                }
                self.annotation?.coordinate = coordinate
                
            })
            .disposed(by: disposeBag)
        
        
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        self.disposeBag = nil
    }
    
    func mapView(_ mapView: MGLMapView, annotationCanShowCallout annotation: MGLAnnotation) -> Bool {
        // Always allow callouts to popup when annotations are tapped.
        return true
    }
    
    
    func getStausLabelText(locationData: IssLocationData) -> NSAttributedString {
        let lastSeenTemplate = NSLocalizedString("LAST_SEEN", comment: "last seen: {value}")
        var lastSeenDateString: String
        if let date = locationData.Timestamp {
            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "MMM d, HH:mm:ss"
           lastSeenDateString = dateFormatter.string(from: date)
        } else {
            lastSeenDateString = NSLocalizedString("NEVER", comment: "")
        }
   
       
        let descriptionString = NSMutableAttributedString(string: String.localizedStringWithFormat(lastSeenTemplate, lastSeenDateString))
        
        let font = UIFont.preferredFont(forTextStyle: UIFont.TextStyle.subheadline)
        let attributes = [NSAttributedString.Key.font: font]
        
        let statusString = NSAttributedString(string: "\n"+locationData.Status.description, attributes: attributes)
        descriptionString.append(statusString)
        
        return descriptionString
    }
}


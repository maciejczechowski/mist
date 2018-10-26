//
//  MultilineCalloutView.swift
//  Mist
// based on https://github.com/mapbox/ios-sdk-examples/blob/master/Examples/Swift/CustomCalloutView.swift
//  Created by Maciej Czechowski on 26.10.2018.
//  Copyright © 2018 Maciej Czechowski. All rights reserved.
//

import Foundation
import UIKit
import Mapbox

class MultilineCalloutView: UIView, MGLCalloutView {
    var representedObject: MGLAnnotation
    
    // Allow the callout to remain open during panning.
    let dismissesAutomatically: Bool = false
    let isAnchoredToAnnotation: Bool = true
    
    // https://github.com/mapbox/mapbox-gl-native/issues/9228
    override var center: CGPoint {
        set {
            var newCenter = newValue
            newCenter.y -= bounds.midY
            super.center = newCenter
        }
        get {
            return super.center
        }
    }
    
    lazy var leftAccessoryView = UIView() /* unused */
    lazy var rightAccessoryView = UIView() /* unused */
    
    weak var delegate: MGLCalloutViewDelegate?
    
    let tipHeight: CGFloat = 20.0
    let tipWidth: CGFloat = 20.0
    
    let mainBody: UILabel
    
    required init(representedObject: MGLAnnotation) {
        self.representedObject = representedObject
        self.mainBody = UILabel()
        
        super.init(frame: .zero)
        
        backgroundColor = .white
        
        mainBody.backgroundColor = .white
  
        addSubview(mainBody)
    }
    
    required init?(coder decoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - MGLCalloutView API
    
    func presentCallout(from rect: CGRect, in view: UIView, constrainedTo constrainedRect: CGRect, animated: Bool) {
        view.addSubview(self)
        
        // Prepare title label.
        mainBody.numberOfLines = 0
        mainBody.text = representedObject.title!
        mainBody.sizeToFit()
      
        
        
        
 
        let frameWidth = mainBody.bounds.size.width + 20
        let frameHeight = mainBody.bounds.size.height + 20
        let frameOriginX = rect.origin.x + (rect.size.width/2.0) - (frameWidth/2.0)
        let frameOriginY = rect.origin.y - frameHeight
        
        frame =  CGRect(x: frameOriginX, y: frameOriginY, width: frameWidth, height: frameHeight)
        mainBody.frame.origin = CGPoint(x: 10, y: 10)
        
        if animated {
            alpha = 0
            
            UIView.animate(withDuration: 0.2) { [weak self] in
                self?.alpha = 1
            }
        }
    }
    
    func dismissCallout(animated: Bool) {
        if (superview != nil) {
            if animated {
                UIView.animate(withDuration: 0.2, animations: { [weak self] in
                    self?.alpha = 0
                    }, completion: { [weak self] _ in
                        self?.removeFromSuperview()
                })
            } else {
                removeFromSuperview()
            }
        }
    }
    
    // MARK: - Callout interaction handlers
    
    func isCalloutTappable() -> Bool {
        if let delegate = delegate {
            if delegate.responds(to: #selector(MGLCalloutViewDelegate.calloutViewShouldHighlight)) {
                return delegate.calloutViewShouldHighlight!(self)
            }
        }
        return false
    }
    
    @objc func calloutTapped() {
        if isCalloutTappable() && delegate!.responds(to: #selector(MGLCalloutViewDelegate.calloutViewTapped)) {
            delegate!.calloutViewTapped!(self)
        }
    }
    
    // MARK: - Custom view styling
    
  
}

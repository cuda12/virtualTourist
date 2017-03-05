//
//  TravelLocationsMapViewController.swift
//  VirtualTourist
//
//  Created by Andreas Rueesch on 05.03.17.
//  Copyright © 2017 Andreas Rueesch. All rights reserved.
//

import UIKit
import MapKit

class TravelLocationsMapViewController: UIViewController {

    // MARK: members and outlets

    @IBOutlet weak var mapView: MKMapView!
    @IBOutlet var gestureLongPress: UILongPressGestureRecognizer!
    
    var pinLocations: [CLLocationCoordinate2D]?
    var pinNewAnnotation: MKPointAnnotation?
    
    // MARK: Life cycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // set default location and zoom if app was used before
        if let prevRegionDict = UserDefaults.standard.dictionary(forKey: "prevRegion") {
            print(prevRegionDict)
            
            mapView.setRegion(getMapRegion(fromDict: prevRegionDict as! [String : Double]), animated: true)
        }
        
        // TODO remove hardcoded pin lcoation
        pinLocations = [CLLocationCoordinate2D(latitude: 47.410811, longitude: 8.558599)]
        print(pinLocations!)
        addPinsToMap()
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */
    
    
    @IBAction func droppedPinAction(_ sender: Any) {
        // get the state of the continuous gesture (started, changing, ended)
        let gestureState = (sender as! UILongPressGestureRecognizer).state
        
        // convert touch point within mapview to coordinates
        let coordinats = mapView.convert(gestureLongPress.location(in: mapView), toCoordinateFrom: mapView)
        
        if gestureState == UIGestureRecognizerState.began {
            // create a new pin and add it to the map view
            let annotation = MKPointAnnotation()
            annotation.coordinate = coordinats
            
            pinNewAnnotation = annotation
            mapView.addAnnotation(pinNewAnnotation!)
            
        } else if gestureState == UIGestureRecognizerState.changed {
            // let the user drag the pin around till the finger is lifted
            pinNewAnnotation?.coordinate = coordinats
        
        } else if gestureState == UIGestureRecognizerState.ended {
            // if finger is lifted add coordinates to pin location collection
            
            // TODO check if collection should not contain annotations and corresponding attributes
            // if so use function above to create pin
            pinLocations?.append(coordinats)
        }
        
    }
    

    func addPinsToMap() {
        guard let pinLocations = pinLocations else {
            print("no pin locations available")
            return
        }
        
        for location in pinLocations {
            let annotation = MKPointAnnotation()
            annotation.coordinate = location
            annotation.title = "Pinned Location"
            
            mapView.addAnnotation(annotation)
        }
    }
}


// MARK: Map view delegate methods

extension TravelLocationsMapViewController: MKMapViewDelegate {
    
    func mapView(_ mapView: MKMapView, regionDidChangeAnimated animated: Bool) {
        // TODO decice if all region changes should be stored
        storeMapViewRegion(mapView.region)
    }
    
    func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
        let reusePinId = "pin"
        
        var pinView = mapView.dequeueReusableAnnotationView(withIdentifier: reusePinId) as? MKPinAnnotationView
        
        if pinView == nil {
            pinView = MKPinAnnotationView(annotation: annotation, reuseIdentifier: reusePinId)
            pinView!.canShowCallout = true
            pinView!.pinTintColor = .red
        } else {
            pinView!.annotation = annotation
        }
        
        return pinView
    }

    func mapView(_ mapView: MKMapView, annotationView view: MKAnnotationView, calloutAccessoryControlTapped control: UIControl) {
        print("TODO segue to photo album")
    }
    
    
    
    // MARK: Map presistency helper methods
    
    func storeMapViewRegion(_ region: MKCoordinateRegion) {
        UserDefaults.standard.set(getMapDict(fromRegion: region), forKey: "prevRegion")
        UserDefaults.standard.synchronize()
    }

    
    func getMapDict(fromRegion region: MKCoordinateRegion) -> [String: Double] {
        // converts a map region into a simple map dictionary
        
        var mapDict = [String: Double]()
        
        mapDict["latDelta"] = region.span.latitudeDelta
        mapDict["longDelta"] = region.span.longitudeDelta
        mapDict["latCenter"] = region.center.latitude
        mapDict["longCenter"] = region.center.longitude
        
        return mapDict
    }
    
    
    func getMapRegion(fromDict dict: [String: Double]) -> MKCoordinateRegion {
        
        let span = MKCoordinateSpan(latitudeDelta: dict["latDelta"]!, longitudeDelta: dict["longDelta"]!)
        let region = MKCoordinateRegion(center: CLLocationCoordinate2D(latitude: dict["latCenter"]!, longitude: dict["longCenter"]!), span: span)

        return region
    }
}


































//
//  TravelLocationsMapViewController.swift
//  VirtualTourist
//
//  Created by Andreas Rueesch on 05.03.17.
//  Copyright © 2017 Andreas Rueesch. All rights reserved.
//

import UIKit
import MapKit
import AddressBook
import CoreData

class TravelLocationsMapViewController: UIViewController {

    // MARK: Properties, members and outlets

    @IBOutlet weak var mapView: MKMapView!
    @IBOutlet var gestureLongPress: UILongPressGestureRecognizer!
    
    let appDelegate = UIApplication.shared.delegate as! AppDelegate
    
    var pins = [Pin]()
    var pinNewAnnotation: MKPointAnnotation?
    
    // Porperty for fetchedResultsController
    var fetchedResultsController: NSFetchedResultsController<NSFetchRequestResult>? {
        didSet {
            // whenever the fetchedResultsController changes, perform the fetch and reload the pin annotations
            fetchedResultsController?.delegate = self
            
            // perform fetch
            do {
                try fetchedResultsController?.performFetch()
            } catch let error as NSError {
                print("Error while trying to perform a search: \(error)")
            }
            
            // reload pins
            self.reloadPins()
        }
    }
    
    // MARK: Initializers
    
    // an initializer for swift interface with objective c protocol NSArchiving
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    
    // MARK: Life cycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // set default location and zoom, if app was used before
        if let prevRegionDict = UserDefaults.standard.dictionary(forKey: "prevRegion") {
            mapView.setRegion(getMapRegion(fromDict: prevRegionDict as! [String : Double]), animated: true)
        }
        
        // get the stack
        let stack = appDelegate.stack
        
        // create a fetchrequest
        let fetchrequest = NSFetchRequest<NSFetchRequestResult>(entityName: "Pin")
        fetchrequest.sortDescriptors = [NSSortDescriptor(key: "latitude", ascending: true)]
        
        // create the FetchResultsController
        fetchedResultsController = NSFetchedResultsController(fetchRequest: fetchrequest, managedObjectContext: stack.context, sectionNameKeyPath: nil, cacheName: nil)
        
        // init prev res
        if let prevpins = fetchedResultsController!.fetchedObjects as? [Pin] {
            pins = prevpins
            reloadPins()
        }
    }
    
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    

    
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
        
        if segue.identifier! == "showPhotoAlbum" {
            if let photoAlbumVC = segue.destination as? PhotoAlbumViewController {
                // get the selected pin
                let selectedPin = sender as! Pin
                
                // get the fetched results controller, while filtering out only the photos assigned to the selected pin
                
                // create the fetch request
                let fr = NSFetchRequest<NSFetchRequestResult>(entityName: "Photo")
                fr.sortDescriptors = [NSSortDescriptor(key: "pin", ascending: true)]
                
                let pred = NSPredicate(format: "pin = %@", argumentArray: [selectedPin])
                fr.predicate = pred
                
                // create the fetched results controller
                let fc = NSFetchedResultsController(fetchRequest: fr, managedObjectContext: fetchedResultsController!.managedObjectContext, sectionNameKeyPath: nil, cacheName: nil)
                
                // inject selected pin to photoAlbumVC
                photoAlbumVC.pin = selectedPin
                photoAlbumVC.fetchedResultsController = fc
            }
        }
    }
    
    
    @IBAction func droppedPinAction(_ sender: Any) {
        // get the state of the continuous gesture (started, changing, ended)
        let gestureState = (sender as! UILongPressGestureRecognizer).state
        
        // convert touch point within mapview to coordinates
        let coordinates = mapView.convert(gestureLongPress.location(in: mapView), toCoordinateFrom: mapView)
        
        if gestureState == UIGestureRecognizerState.began {
            // create a new pin annotation and add it to the map view
            let annotation = MKPointAnnotation()
            annotation.coordinate = coordinates
            
            pinNewAnnotation = annotation
            mapView.addAnnotation(pinNewAnnotation!)
            
        } else if gestureState == UIGestureRecognizerState.changed {
            // let the user drag the pin around till the finger is lifted
            pinNewAnnotation?.coordinate = coordinates
        
        } else if gestureState == UIGestureRecognizerState.ended {
            // if finger is lifted create a new instance of the Pin entity
            
            let pin = Pin(latitude: coordinates.latitude, longitude: coordinates.longitude, title: "\(coordinates.latitude) \(coordinates.longitude)", context: self.fetchedResultsController!.managedObjectContext)
            
            backwardGeocoding(coordinates: coordinates, completionHandlerBwdGeocoding: { (result, error) in
                if error == nil {
                    pin.title = result
                }
            })
        }
    }
    
    func reloadPins() {
        // remove all annotations to avoid any double annotations
        mapView.removeAnnotations(mapView.annotations)
        
        // add annotations for all pins
        for pin in pins {
            let annotation = MKPointAnnotation()
            annotation.coordinate = CLLocationCoordinate2D(latitude: pin.latitude, longitude: pin.longitude)
            mapView.addAnnotation(annotation)
        }
    }
}


// MARK: Map view delegate methods

extension TravelLocationsMapViewController: MKMapViewDelegate {
    
    func mapView(_ mapView: MKMapView, regionDidChangeAnimated animated: Bool) {
        // make any region change persistent
        storeMapViewRegion(mapView.region)
    }
    
    func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
        let reusePinId = "pin"
        
        var pinView = mapView.dequeueReusableAnnotationView(withIdentifier: reusePinId) as? MKPinAnnotationView
        
        if pinView == nil {
            pinView = MKPinAnnotationView(annotation: annotation, reuseIdentifier: reusePinId)
            pinView!.canShowCallout = false
            pinView!.pinTintColor = .red
        } else {
            pinView!.annotation = annotation
        }
        
        return pinView
    }
    
    func mapView(_ mapView: MKMapView, didSelect view: MKAnnotationView) {
        // check wich pin entity called the segue - if a valid pin is selected open photo ablum immediately
        
        // get the coordinates of the selected pin annotation
        let selectedPinCoordinates = view.annotation!.coordinate
        
        // compare the coordinates with the Pins array till match is found
        var selectedPin: Pin?
        for pin in pins {
            if pin.latitude == selectedPinCoordinates.latitude && pin.longitude == selectedPinCoordinates.longitude {
                selectedPin = pin
                break
            }
        }
        
        // deselect annotation
        mapView.deselectAnnotation(view.annotation, animated: true)
        
        if let selectedPin = selectedPin {
            performSegue(withIdentifier: "showPhotoAlbum", sender: selectedPin)
        }
    }
    
    
    // MARK: Map Helpers
    
    func backwardGeocoding(coordinates: CLLocationCoordinate2D, completionHandlerBwdGeocoding: @escaping (_ locationDiscription: String, _ error: Error?) -> Void) {
        let location = CLLocation(latitude: coordinates.latitude, longitude: coordinates.longitude)
        CLGeocoder().reverseGeocodeLocation(location) { (placemarks, error) in
            guard let placemark = placemarks?.first else {
                // if no placemark was found return the error and use cooridnates as description
                completionHandlerBwdGeocoding("\(coordinates.latitude) \(coordinates.longitude)", error)
                return
            }
            
            // if an area of interest is available return it, otherwise build a string from the name, city and country. if this fails aswell return the coordinates
            if let areaOfInterest = placemark.areasOfInterest?.first {
                completionHandlerBwdGeocoding(areaOfInterest, nil)
            } else {
                var outputElements = [String]()
                
                if let name = placemark.name {
                    outputElements.append(name)
                }
                if let city = placemark.addressDictionary?["City"] as? String {
                    outputElements.append(city)
                }
                if let country = placemark.country {
                    outputElements.append(country)
                }
                
                if outputElements.count > 0 {
                    completionHandlerBwdGeocoding(outputElements.joined(separator: ", "), nil)
                } else {
                    completionHandlerBwdGeocoding("\(coordinates.latitude) \(coordinates.longitude)", nil)
                }
            }
        }
    }
    
    
    // MARK: Map persistency helper methods
    
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
        // converts a saved map dictionary back to a map region
        
        let span = MKCoordinateSpan(latitudeDelta: dict["latDelta"]!, longitudeDelta: dict["longDelta"]!)
        let region = MKCoordinateRegion(center: CLLocationCoordinate2D(latitude: dict["latCenter"]!, longitude: dict["longCenter"]!), span: span)

        return region
    }
}


// MARK: NSFetchedResultsControllerDelagete methods

extension TravelLocationsMapViewController: NSFetchedResultsControllerDelegate {
    
    func controller(_ controller: NSFetchedResultsController<NSFetchRequestResult>, didChange anObject: Any, at indexPath: IndexPath?, for type: NSFetchedResultsChangeType, newIndexPath: IndexPath?) {
        // insert pin into array
        if type == .insert {
            self.pins.insert(anObject as! Pin, at: newIndexPath!.row)
        }
    }
    
    func controllerDidChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
        // reload pins and store contains
        self.reloadPins()
        self.appDelegate.stack.save()
    }
}




























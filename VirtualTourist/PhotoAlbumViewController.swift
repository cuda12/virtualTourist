//
//  PhotoAlbumViewController.swift
//  VirtualTourist
//
//  Created by Andreas Rueesch on 06.05.17.
//  Copyright © 2017 Andreas Rueesch. All rights reserved.
//

import UIKit
import MapKit
import CoreData

class PhotoAlbumViewController: UIViewController {
    
    // MARK: Members
    
    var pin: Pin!
    var numberOfPlaceholders = 0
    
    let appDelegate = UIApplication.shared.delegate as! AppDelegate
    
    @IBOutlet weak var mapView: MKMapView!
    @IBOutlet weak var photoCollectionView: UICollectionView!
    @IBOutlet weak var flowLayout: UICollectionViewFlowLayout!
    
    // Porperty for fetchedResultsController
    var fetchedResultsController: NSFetchedResultsController<NSFetchRequestResult>? {
        didSet {
            // whenever the fetchedResultsController changes, perform the fetch
            fetchedResultsController?.delegate = self
            
            // perform fetch
            do {
                print("do fetch")
                try fetchedResultsController?.performFetch()
            } catch let error as NSError {
                print("Error while trying to perform a search: \(error)")
            }
        }
    }
    
    // MARK: Life cycle
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        
        print("photo album for \(pin) loaded")
    
        addLocationPinAndCenter(atLat: pin.latitude, atLong: pin.longitude)
        
        // set layout of collection view cells
        setFlowLayout()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        // TODO if pin contains photos load them
        
        if (pin.photos?.count)! > 0 {
            print("reloading previously stored images")
            
            // reload previously stored data
            photoCollectionView.reloadData()
        } else {
            // get a new photoalbum
            loadNewPhotoAlbumForLoaction()
        }
    }
    
    
    // MARK: Load photo album actions
    
    private func loadNewPhotoAlbumForLoaction() {
        // TODO
        print("get a new photo album")
        
        // get Image URLs from Flicker
        FlickerClient.sharedInstance.getImageUrls(forLat: pin.latitude, forLong: pin.longitude) { (data, errorMsg) in
            if let data = data {
                print(data)
                print("loaded images URL")
                
            } else {
                print(errorMsg!)
            }
        }
        
        // add placeholders
        
        // drop all images from current pin
        
        // download images in background and add to pin
        
        // reload the collection's view content
        
    }
    
    
    @IBAction func loadNewCollection(_ sender: Any) {
        
        print("Gonna load a new collection")
        
        loadNewPhotoAlbumForLoaction()
    }
    
}

// MARK: NSFetchedResultsControllerDelagete methods

extension PhotoAlbumViewController: NSFetchedResultsControllerDelegate {
    
    func controllerWillChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
        print("controller will change content")
    }
    
    func controller(_ controller: NSFetchedResultsController<NSFetchRequestResult>, didChange anObject: Any, at indexPath: IndexPath?, for type: NSFetchedResultsChangeType, newIndexPath: IndexPath?) {
        
        print("ns fetched results controller delegate did change method called")
        
        // todo switch type to add, remove or insert pins
        print("Todo")
    }
    
    func controllerDidChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
        print("controller did change content")
        // TODO reload data
        // TODOself.appDelegate.stack.save()
    }
}


// MARK: Collection View data source

extension PhotoAlbumViewController: UICollectionViewDataSource {
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        // if pin does not contain any images - load number of placeholders (initially equal to zero)
        guard let numberOfPhotos = pin.photos?.count, numberOfPhotos > 0 else {
            print("laod \(numberOfPlaceholders) placeholders")
            return numberOfPlaceholders
        }
        
        print("load \(numberOfPhotos) actual photos")
        return numberOfPhotos
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "PhotoAlbumCell", for: indexPath) as! PhotoAlbumCollectionViewCell
        
        // load placeholders if no photos loaded yet
        guard let numberOfPhotos = pin.photos?.count, numberOfPhotos > 0 else {
            print("add placeholder")
            cell.imageView.image = UIImage(named: "placeholderImg")
            return cell
        }
        
        let photo = fetchedResultsController?.object(at: indexPath) as! Photo
        print("add image")
        cell.imageView.image = UIImage(data: photo.imageData! as Data)
        
        return cell
    }
    
    
    // MARK: Collection View Helper
    
    func setFlowLayout() {
        let space: CGFloat = 3.0
        let dimension: CGFloat
        
        if UIDeviceOrientationIsPortrait(UIDevice.current.orientation) {
            dimension = (view.frame.size.width - (2 * space)) / 3.0
        } else {
            dimension = (view.frame.size.width - (4 * space)) / 5.0
        }
        
        flowLayout.minimumLineSpacing = space
        flowLayout.minimumInteritemSpacing = space
        
        flowLayout.itemSize = CGSize(width: dimension, height: dimension)
    }
}

extension PhotoAlbumViewController: UICollectionViewDelegate {
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        //let photo = pin.Photos[(indexPath as NSIndexPath).row]
        
        print("TODO delete photo at: \((indexPath as NSIndexPath).row)")
    }
    
}



// MARK: Map Kit delegats methods

extension PhotoAlbumViewController: MKMapViewDelegate {
    
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
    
    func addLocationPinAndCenter(atLat lat: Double, atLong long: Double) {
        
        // add a pin annotation
        let coordinates = CLLocationCoordinate2D(latitude: lat, longitude: long)
        let annotation = MKPointAnnotation()
        annotation.coordinate = coordinates
        // TODO decide if title and subtitle wanted
        
        mapView.addAnnotation(annotation)
        
        // set region
        let regionRadius: CLLocationDistance = 2000         // in meters
        let coordinateRegion = MKCoordinateRegionMakeWithDistance(coordinates, regionRadius, regionRadius)
        
        mapView.setRegion(coordinateRegion, animated: true)
    }
}

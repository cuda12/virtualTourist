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
    @IBOutlet weak var activityIndicator: UIActivityIndicatorView!
    @IBOutlet weak var activityIndicatorLabel: UILabel!
    @IBOutlet weak var buttonNewCollection: UIBarButtonItem!
    @IBOutlet weak var labelNoImages: UILabel!
    
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
        
        // set-up view
        enableView(enable: true)
        
        // check if pin has perviously stored photos, otherwise load a new set
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
        // disable view, show download indication
        enableView(enable: false)
        
        // get Image URLs from Flickr
        FlickerClient.sharedInstance.getImageUrls(forLat: pin.latitude, forLong: pin.longitude) { (data, errorMsg) in
            if let data = data {
                print(data)
                print("loaded images URL")
                
                // add placeholders
                performUIUpdatesOnMain {
                    self.numberOfPlaceholders = data.count
                    self.photoCollectionView.reloadData()
                }
                
                // actually download images from the received url
                for photoUrl in data {
                    print("Ill download the image from \(photoUrl)")
                    
                    if let imageData = try? Data(contentsOf: URL(string: photoUrl)!) {
                        let photo = Photo(imageData: imageData as NSData, context: self.appDelegate.stack.context)
                        photo.pin = self.pin
                    }
                    
                    // update collection view immediately
                    performUIUpdatesOnMain {
                        self.photoCollectionView.reloadData()
                    }
                }
            } else {
                if errorMsg! == "No Images found" {
                    self.showAlert(title: "No images found for pin", details: "head to the pin's location an post some pics on Flickr, then generate a new collection")
                } else {
                    self.showAlert(title: "Error connecting to Flickr", details: "make sure you are connected to the internet")
                }
            }
            
            // housekeeping
            performUIUpdatesOnMain {
                // reset placeholder counter to zero (hence if a photo delete no placeholder is added)
                self.numberOfPlaceholders = 0
                
                // reenable view
                self.enableView(enable: true)
                
            }
        }
    }
    
    private func deletePhotoAlbum() {
        print("Drop all images")
        
        pin.removeFromPhotos(pin.photos!)
        numberOfPlaceholders = 0
    }
    
    @IBAction func loadNewCollection(_ sender: Any) {
        deletePhotoAlbum()
        print("Gonna load a new collection")
        loadNewPhotoAlbumForLoaction()
    }
    
    // MARK: UI Helper
    
    func enableView(enable: Bool) {
        view.alpha = enable ? 1.0 : 0.5
        activityIndicator.isHidden = enable
        activityIndicatorLabel.isHidden = enable
        buttonNewCollection.isEnabled = enable
    }
    
    // MARK: Alert Controller
    
    func showAlert(title: String, details: String) {
        let alertController = UIAlertController()
        
        alertController.title = title
        alertController.message = details
        alertController.addAction(UIAlertAction(title: "Cancel", style: UIAlertActionStyle.cancel))
        
        present(alertController, animated: true, completion: nil)
    }
}

// MARK: NSFetchedResultsControllerDelagete methods

extension PhotoAlbumViewController: NSFetchedResultsControllerDelegate {
    
    func controllerDidChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
        // reload data of collection view and store changes
        photoCollectionView.reloadData()
        appDelegate.stack.save()
    }
}


// MARK: Collection View data source

extension PhotoAlbumViewController: UICollectionViewDataSource {
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        // if pin does not contain any images - load number of placeholders (initially equal to zero)
        guard let numberOfPhotos = pin.photos?.count, numberOfPhotos > numberOfPlaceholders else {
            labelNoImages.isHidden = numberOfPlaceholders == 0 ? false : true
            
            print("laod \(numberOfPlaceholders) placeholders")
            return numberOfPlaceholders
        }
        
        labelNoImages.isHidden = true
        print("load \(numberOfPhotos) actual photos")
        return numberOfPhotos
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "PhotoAlbumCell", for: indexPath) as! PhotoAlbumCollectionViewCell
        
        // load placeholders if photo is not available yet
        
        let numberOfPhotos = pin.photos?.count ?? 0
        
        if indexPath.row < numberOfPhotos {
            print("add image")
            let photo = fetchedResultsController?.object(at: indexPath) as! Photo
            cell.imageView.image = UIImage(data: photo.imageData! as Data)
        } else {
            print("add placeholder")
            cell.imageView.image = UIImage(named: "placeholderImg")
        }
        
        return cell
    }
    
    
    // MARK: Collection View Helper
    
    func setFlowLayout() {
        let space: CGFloat = 2.0
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
        // delete tapped images
        pin.removeFromPhotos(fetchedResultsController?.object(at: indexPath) as! Photo)
    }
}



// MARK: Map Kit delegats methods

extension PhotoAlbumViewController: MKMapViewDelegate {
    
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
    
    func addLocationPinAndCenter(atLat lat: Double, atLong long: Double) {
        
        // add a pin annotation
        let coordinates = CLLocationCoordinate2D(latitude: lat, longitude: long)
        let annotation = MKPointAnnotation()
        annotation.coordinate = coordinates
        annotation.title = pin.title
        annotation.subtitle = "visited \(getShortDateString(date: pin.creationDate!))"
        
        mapView.addAnnotation(annotation)
        mapView.selectAnnotation(annotation, animated: true)
        
        // set region
        let regionRadius: CLLocationDistance = 2000         // in meters
        let coordinateRegion = MKCoordinateRegionMakeWithDistance(coordinates, regionRadius, regionRadius)
        
        mapView.setRegion(coordinateRegion, animated: true)
    }
    
    
    // MARK: helper methods
    
    func getShortDateString(date: Date) -> String {
        // return a short date string with the users local defaults
        let dfmt = DateFormatter()
        dfmt.dateStyle = .short
        dfmt.timeStyle = .short
        dfmt.doesRelativeDateFormatting = true
        dfmt.locale = Locale.current
        
        return dfmt.string(from: date)
    }
}


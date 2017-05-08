//
//  FlickerClient.swift
//  VirtualTourist
//
//  Created by Andreas Rueesch on 06.05.17.
//  Copyright © 2017 Andreas Rueesch. All rights reserved.
//

import Foundation
import GameplayKit

class FlickerClient {
    
    // MARK: Shared Instance
    static let sharedInstance = FlickerClient()
    
    
    func getImageUrls(forLat lat: Double, forLong long: Double, completionHandler: @escaping (_ data: [String]?, _ errorMsg: String?) -> Void) {
        
        // check how many pages are available
        getImageUrlsFromFlickr(forLat: lat, forLong: long) { (photoData, errorMsg) in
            
            // make sure request was successful
            guard let photoData = photoData else {
                completionHandler(nil, errorMsg!)
                return
            }
            
            // select a random page (only first 4000 returned from flickr api)
            guard let pages = photoData[Constants.FlickrResponseKeys.Pages] as? Int, pages > 0 else {
                completionHandler(nil, "Error no pages found in request")
                return
            }
            
            let indexRandomPage = Int(arc4random_uniform(UInt32(min(pages, 16) - 1))) + 1
            
            print("index random page \(indexRandomPage)")
            
            
            // get Image URL for x random images from selected page
            self.getImageUrlsFromFlickr(forLat: lat, forLong: long, atPage: indexRandomPage, completionHandler: { (photoData, errorMsg) in
                
                // make sure request was successful
                guard let photoData = photoData else {
                    completionHandler(nil, errorMsg!)
                    return
                }

                guard let photos = photoData[Constants.FlickrResponseKeys.Photo] as? [[String: AnyObject]] else {
                    completionHandler(nil, "No Images found")
                    return
                }
                
                // select maximal x random images from the page
                let randomIndexes = GKRandomSource.sharedRandom().arrayByShufflingObjects(in: Array(0...(photos.count-1)))
                var photoUrls: [String] = []
                
                for idx in 0...(min(Constants.MaxNumbersImageToReturn, photos.count)-1) {
                    let randomPhoto = photos[randomIndexes[idx] as! Int]
                    if let photoUrl = randomPhoto[Constants.FlickrResponseKeys.MediumURL] as? String {
                        photoUrls.append(photoUrl)
                    }
                }
                
                completionHandler(photoUrls, nil)
            })
        }
    }
    

    private func getImageUrlsFromFlickr(forLat lat: Double, forLong long: Double, atPage pageId: Int? = nil, completionHandler: @escaping (_ data: [String: AnyObject]?, _ errorMsg: String?) -> Void) {

        // build request URL for Flickr API
        var methodParameters: [String: AnyObject] = [
            Constants.FlickrParameterKeys.SafeSearch: Constants.FlickrParameterValues.UseSafeSearch as AnyObject,
            Constants.FlickrParameterKeys.Extras: Constants.FlickrParameterValues.MediumURL as AnyObject,
            Constants.FlickrParameterKeys.APIKey: Constants.FlickrParameterValues.APIKey as AnyObject,
            Constants.FlickrParameterKeys.Method: Constants.FlickrParameterValues.SearchMethod as AnyObject,
            Constants.FlickrParameterKeys.Format: Constants.FlickrParameterValues.ResponseFormat as AnyObject,
            Constants.FlickrParameterKeys.NoJSONCallback: Constants.FlickrParameterValues.DisableJSONCallback as AnyObject,
            Constants.FlickrParameterKeys.BoundingBox : bboxString(lat: lat, long: long) as AnyObject
        ]
        
        if let pageId = pageId {
            methodParameters[Constants.FlickrParameterKeys.Page] = pageId as AnyObject?
        }
        
        // make the request
        let request = URLRequest(url: flickrURLFromParameters(methodParameters))
        
        performTaskOnFlickerAPI(request: request) { (data, error) in
            
            // check if no error occured getting the data
            guard let data = data, let photosDict = data[Constants.FlickrResponseKeys.Photos] as? [String: AnyObject] else {
                completionHandler(nil, "Error loading data from flicker")
                return
            }
            
            // check if location returned some photos
            guard let photos = photosDict[Constants.FlickrResponseKeys.Photo] as? [[String: AnyObject]], (photos.count != 0) else {
                completionHandler(nil, "No Images found")
                return
            }
            
            // call the completion handler with the retrieved data
            completionHandler(photosDict, nil)
        }
    }
    
    private func performTaskOnFlickerAPI(request: URLRequest, completionHandler: @escaping (_ data: [String: AnyObject]?, _ error: NSError?) -> Void) {
        
        // create a shared URL session
        let session = URLSession.shared
        
        // build and execute the task
        let task = session.dataTask(with: request) { (data, response, error) in
            guard let data = data else {
                completionHandler(nil, error as NSError?)
                return
            }
            
            // parse stripped data as json
            do {
                let jsonData = try JSONSerialization.jsonObject(with: data, options: .allowFragments) as! [String: AnyObject]
                completionHandler(jsonData, nil)
            } catch {
                let userErrMsg = NSError(domain: "performTaskOnFlickerAPI", code: 0, userInfo: [NSLocalizedDescriptionKey: "cant parse response to json"])
                completionHandler(nil, userErrMsg)
            }
        }
        task.resume()
    }
    
    
    // MARK: Helper for Creating a URL from Parameters
    // according to Jarrod Parkes
    
    private func flickrURLFromParameters(_ parameters: [String: AnyObject]) -> URL {
        
        var components = URLComponents()
        components.scheme = Constants.Flickr.APIScheme
        components.host = Constants.Flickr.APIHost
        components.path = Constants.Flickr.APIPath
        components.queryItems = [URLQueryItem]()
        
        for (key, value) in parameters {
            let queryItem = URLQueryItem(name: key, value: "\(value)")
            components.queryItems!.append(queryItem)
        }
        
        return components.url!
    }

    private func bboxString(lat: Double, long: Double) -> String {
        let leftBound = max(long - Constants.Flickr.SearchBBoxHalfWidth, Constants.Flickr.SearchLonRange.0)
        let rightBound = min(long + Constants.Flickr.SearchBBoxHalfWidth, Constants.Flickr.SearchLonRange.1)
        let lowerBound = max(lat - Constants.Flickr.SearchBBoxHalfHeight, Constants.Flickr.SearchLatRange.0)
        let upperBound = min(lat + Constants.Flickr.SearchBBoxHalfHeight, Constants.Flickr.SearchLatRange.1)
        
        return "\(leftBound),\(lowerBound),\(rightBound),\(upperBound)"
    }

}


// MARK: Flicker API Constants

extension FlickerClient {
    
    // according to Jarrod Parkes FlickerFinder App
    
    struct Constants {
        
        // MARK: Virtual Tourist
        
        static let MaxNumbersImageToReturn = 50
        
        // MARK: Flickr
        struct Flickr {
            static let APIScheme = "https"
            static let APIHost = "api.flickr.com"
            static let APIPath = "/services/rest"
            
            static let SearchBBoxHalfWidth = 0.01
            static let SearchBBoxHalfHeight = 0.01
            static let SearchLatRange = (-90.0, 90.0)
            static let SearchLonRange = (-180.0, 180.0)
        }
        
        // MARK: Flickr Parameter Keys
        struct FlickrParameterKeys {
            static let Method = "method"
            static let APIKey = "api_key"
            static let GalleryID = "gallery_id"
            static let Extras = "extras"
            static let Format = "format"
            static let NoJSONCallback = "nojsoncallback"
            static let SafeSearch = "safe_search"
            static let Text = "text"
            static let BoundingBox = "bbox"
            static let Page = "page"
        }
        
        // MARK: Flickr Parameter Values
        struct FlickrParameterValues {
            static let SearchMethod = "flickr.photos.search"
            static let APIKey = "d7d34d4ca42e03106774b3a395819772"
            static let ResponseFormat = "json"
            static let DisableJSONCallback = "1"
            static let GalleryPhotosMethod = "flickr.galleries.getPhotos"
            static let GalleryID = "5704-72157622566655097"
            static let MediumURL = "url_m"
            static let UseSafeSearch = "1"
        }
        
        // MARK: Flickr Response Keys
        struct FlickrResponseKeys {
            static let Status = "stat"
            static let Photos = "photos"
            static let Photo = "photo"
            static let Title = "title"
            static let MediumURL = "url_m"
            static let Pages = "pages"
            static let Total = "total"
        }
        
        // MARK: Flickr Response Values
        struct FlickrResponseValues {
            static let OKStatus = "ok"
        }
    }
}

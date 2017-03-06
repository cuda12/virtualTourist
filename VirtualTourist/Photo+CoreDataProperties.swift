//
//  Photo+CoreDataProperties.swift
//  VirtualTourist
//
//  Created by Andreas Rueesch on 06.03.17.
//  Copyright © 2017 Andreas Rueesch. All rights reserved.
//

import Foundation
import CoreData


extension Photo {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<Photo> {
        return NSFetchRequest<Photo>(entityName: "Photo");
    }

    @NSManaged public var imageData: NSData?
    @NSManaged public var pin: Pin?

}

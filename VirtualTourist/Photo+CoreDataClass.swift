//
//  Photo+CoreDataClass.swift
//  VirtualTourist
//
//  Created by Andreas Rueesch on 06.03.17.
//  Copyright © 2017 Andreas Rueesch. All rights reserved.
//

import Foundation
import CoreData

@objc(Photo)
public class Photo: NSManagedObject {

    convenience init(imageData: NSData, context: NSManagedObjectContext) {
        if let ent = NSEntityDescription.entity(forEntityName: "Photo", in: context) {
            self.init(entity: ent, insertInto: context)
            self.imageData = imageData
            
        } else {
            fatalError("unable to find entity name (Photo)!")
        }
    }
}

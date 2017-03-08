//
//  Pin+CoreDataClass.swift
//  VirtualTourist
//
//  Created by Andreas Rueesch on 06.03.17.
//  Copyright © 2017 Andreas Rueesch. All rights reserved.
//

import Foundation
import CoreData

@objc(Pin)
public class Pin: NSManagedObject {

    convenience init(latitude: Double, longitude: Double, title: String?, context: NSManagedObjectContext) {
        if let ent = NSEntityDescription.entity(forEntityName: "Pin", in: context) {
            self.init(entity: ent, insertInto: context)
            self.latitude = latitude
            self.longitude = longitude
            self.title = title
            self.creationDate = Date()
            
        } else {
            fatalError("unable to find entity name (Pin)!")
        }
    }
}

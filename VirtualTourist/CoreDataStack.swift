//
//  CoreDataStack.swift
//  VirtualTourist
//
//  Created by Andreas Rueesch on 05.03.17.
//  Copyright © 2017 Andreas Rueesch. All rights reserved.
//
//  in accordance to the Udacity CoreDataStack struct written by Fernadnod Rodriguez Romero
//

import CoreData

struct CoreDataStack {
    
    
    // MARK:  - Properties
    
    private let model: NSManagedObjectModel
    private let cooridnator: NSPersistentStoreCoordinator
    private let modelUrl: URL
    private let dbUrl: URL
    let persistingContext: NSManagedObjectContext
    let context: NSManagedObjectContext
    
    
    // MARK:  - Initializers
    
    init?(modelName: String) {
        
        // assume the model is in the main bundle 
        guard let modelUrl = Bundle.main.url(forResource: modelName, withExtension: "momd") else {
            print("unable to find \(modelName) in the main bundle")
            return nil
        }
        self.modelUrl = modelUrl
        
        // create a model from the url
        guard let model = NSManagedObjectModel(contentsOf: modelUrl) else {
            print("unable to create a model from \(modelUrl)")
            return nil
        }
        self.model = model
        
        // create the store coordinater
        cooridnator = NSPersistentStoreCoordinator(managedObjectModel: model)
        
        // create the contexts and connect them to the coordinator
        persistingContext = NSManagedObjectContext(concurrencyType: .privateQueueConcurrencyType)
        persistingContext.persistentStoreCoordinator = cooridnator
        
        context = NSManagedObjectContext(concurrencyType: .mainQueueConcurrencyType)
        context.parent = persistingContext
        
        // add a sqlite store located in the documents folder
        let filemanager = FileManager.default
        guard let docUrl = filemanager.urls(for: .documentDirectory, in: .userDomainMask).first else {
            print("unable to reach the documents folder")
            return nil
        }
        self.dbUrl = docUrl.appendingPathComponent("model.sqlite")
        
        // options for migration
        let migrationOptions = [NSInferMappingModelAutomaticallyOption: true,
                                NSMigratePersistentStoresAutomaticallyOption: true]
        do {
            try cooridnator.addPersistentStore(ofType: NSSQLiteStoreType, configurationName: nil, at: dbUrl, options: migrationOptions)
        } catch {
            print("unable to add store at \(dbUrl)")
        }
    }
}


// MARK:  - Save data methods

extension CoreDataStack {
    func save() {
        context.performAndWait() {
            if self.context.hasChanges {
                do {
                    try self.context.save()
                } catch {
                    fatalError("error while saving main context: \(error)")
                }
                
                // now we save in the background
                self.persistingContext.perform() {
                    do {
                        try self.persistingContext.save()
                    } catch {
                        fatalError("error whil saving persisting context: \(error)")
                    }
                }
            }
        }
    }
}








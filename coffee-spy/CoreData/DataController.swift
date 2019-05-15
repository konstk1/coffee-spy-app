//
//  DataController.swift
//  coffee-spy
//
//  Created by Konstantin Klitenik on 5/14/19.
//  Copyright © 2019 KK. All rights reserved.
//

import Foundation
import CoreData

class DataController: NSObject {
    static let shared = DataController()
    
    lazy var persistentContainer: NSPersistentContainer = {
        let container = NSPersistentContainer(name: "CoffeeSpy")
        container.loadPersistentStores(completionHandler: { (_, error) in
            if let error = error as NSError? {
                fatalError("Unresolved error \(error), \(error.userInfo)")
            }
        })
        return container
    }()
    
    lazy var mainObjectContext: NSManagedObjectContext  = {
        return self.persistentContainer.viewContext
    }()
    
    func saveContext(_ context: NSManagedObjectContext, saveParent: Bool = true) {
        guard context.hasChanges else { return }
        
        do {
            // save this context and, if requested, its parent to propage changes to persistent store
            try context.save()
            if saveParent {
                try context.parent?.save()
            }
        } catch {
            let nserror = error as NSError
            print("Unresolved error \(nserror), \(nserror.userInfo)")
        }
    }
    
    func saveMainContext() {
        saveContext(mainObjectContext);
    }
    
    func makeChildContext() -> NSManagedObjectContext {
        let childContext = NSManagedObjectContext(concurrencyType: .mainQueueConcurrencyType)
        childContext.parent = mainObjectContext
        return childContext
    }
}

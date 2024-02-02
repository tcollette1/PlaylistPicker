//
//  CoreData.swift
//  PlaylistPicker
//
//  Created by Thomas Collette on 7/27/21.
//

import UIKit
import CoreData

// MARK: - Core Data stack

class CoreDataManager {
    static let shared = CoreDataManager()
    private init() {}
    private lazy var persistentContainer: NSPersistentContainer = {
        let container = NSPersistentContainer(name: "PlaylistPicker")
        container.loadPersistentStores(completionHandler: { _, error in
            _ = error.map { fatalError("Unresolved error \($0)") }
        })
        return container
    }()
    
    var mainContext: NSManagedObjectContext {
        return persistentContainer.viewContext
    }
}

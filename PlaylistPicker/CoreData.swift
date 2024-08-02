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
    static let shared = CoreDataManager() // 13
    private init() {}
    private lazy var persistentContainer: NSPersistentContainer = { // 14
        let container = NSPersistentContainer(name: "PlaylistPicker") // 18
        container.loadPersistentStores(completionHandler: { _, error in // 26
            _ = error.map { fatalError("Unresolved error \($0)") }
        })
        return container
    }()
    
    var mainContext: NSManagedObjectContext {
        return persistentContainer.viewContext // 34
    }
}

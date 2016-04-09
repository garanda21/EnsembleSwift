//
//  AppDelegate.swift
//  EnsembleExample
//
//  Created by Oskari Rauta on 7.2.2016.
//  Copyright © 2016 Oskari Rauta. All rights reserved.
//

import UIKit
import CoreData
import Ensembles

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate, CDEPersistentStoreEnsembleDelegate {

    var window: UIWindow?
    var ensemble:CDEPersistentStoreEnsemble!
    var cloudFileSystem:CDEICloudFileSystem!
    var managedObjectContext: NSManagedObjectContext!
    
    func application(application: UIApplication, didFinishLaunchingWithOptions launchOptions: [NSObject: AnyObject]?) -> Bool {
        setUpCoreData()
        
       // CDESetCurrentLoggingLevel(CDELoggingLevel.Verbose.rawValue)
        
        let modelURL = NSBundle.mainBundle().URLForResource("EnsembleExample", withExtension: "momd")!
        cloudFileSystem = CDEICloudFileSystem(ubiquityContainerIdentifier: nil)
        
        ensemble = CDEPersistentStoreEnsemble(ensembleIdentifier: "EnsembleOnly", persistentStoreURL: storeURL(), managedObjectModelURL: modelURL, cloudFileSystem: cloudFileSystem!)
        ensemble.delegate = self
        
        
        
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "localSaveOccurred:", name: CDEMonitoredManagedObjectContextDidSaveNotification, object: nil)
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "cloudDataDidDownload:", name: CDEICloudFileSystemDidDownloadFilesNotification, object: nil)
        
        syncWithCompletion { completed in
            if completed {
                print("SUCCESSS")
            }
            else {
                print("FAIL")
            }
        }
        
        return true
    }
    
    func setUpCoreData() {
        
        let modelURL = NSBundle.mainBundle().URLForResource("EnsembleExample", withExtension: "momd")!
        guard let model = NSManagedObjectModel(contentsOfURL: modelURL) else { fatalError("cannot use model") }
        
        do {
            try NSFileManager.defaultManager().createDirectoryAtURL(storeDirectoryURL(), withIntermediateDirectories: true, attributes: nil)
        }
        catch {
            fatalError("cannot create dir")
        }
        
        let coordinator = NSPersistentStoreCoordinator(managedObjectModel: model)
        //NSDictionary *options = @{NSMigratePersistentStoresAutomaticallyOption: @YES, NSInferMappingModelAutomaticallyOption: @YES};
        
        let failureReason = "There was an error creating or loading the application's saved data."
        
        do {
            try coordinator.addPersistentStoreWithType(NSSQLiteStoreType, configuration: nil, URL: storeURL(), options: nil)
            
            managedObjectContext = NSManagedObjectContext.init(concurrencyType: .MainQueueConcurrencyType)
            managedObjectContext.persistentStoreCoordinator = coordinator
            managedObjectContext.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy
            
        } catch {
            // Report any error we got.
            var dict = [String: AnyObject]()
            dict[NSLocalizedDescriptionKey] = "Failed to initialize the application's saved data"
            dict[NSLocalizedFailureReasonErrorKey] = failureReason
            
            dict[NSUnderlyingErrorKey] = error as NSError
            let wrappedError = NSError(domain: "YOUR_ERROR_DOMAIN", code: 9999, userInfo: dict)
            // Replace this with code to handle the error appropriately.
            // abort() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
            NSLog("Unresolved error \(wrappedError), \(wrappedError.userInfo)")
            abort()
        }
    }
    
    func saveContext () {
        if managedObjectContext.hasChanges {
            do {
                try managedObjectContext.save()
            } catch {
                // Replace this implementation with code to handle the error appropriately.
                // abort() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
                let nserror = error as NSError
                NSLog("Unresolved error \(nserror), \(nserror.userInfo)")
                abort()
            }
        }
    }
    
    func storeDirectoryURL() -> NSURL {
        
        let directoryURL = try! NSFileManager.defaultManager().URLForDirectory(.DocumentDirectory, inDomain: .UserDomainMask, appropriateForURL: nil, create: true)
        return directoryURL
    }
    
    func storeURL() -> NSURL {
        let url = storeDirectoryURL().URLByAppendingPathComponent("store.sqlite")
        return url
    }

    // MARK: - Sync
    
    func applicationDidEnterBackground(application: UIApplication) {
        print("Did Enter Background Save from App Delegate")
        
        let identifier = UIApplication.sharedApplication().beginBackgroundTaskWithExpirationHandler(nil)
        //saveContext()
        
        syncWithCompletion { (completed) -> Void in
            if completed {
                UIApplication.sharedApplication().endBackgroundTask(identifier)
            }
        }
    }
    
    func applicationWillEnterForeground(application: UIApplication) {
        syncWithCompletion { (completed) -> Void in
            
        }
    }
    
    func localSaveOccurred(note:NSNotification) {
        print("Local Save!!")
        syncWithCompletion { (completed) -> Void in
            
        }
    }
    
    func cloudDataDidDownload(note:NSNotification) {
        print("Cloud Save!!")
        syncWithCompletion { (completed) -> Void in
            
        }
    }
    
    func syncWithCompletion(completion:(completed:Bool) -> Void) {
        
        if !ensemble.leeched {
            ensemble.leechPersistentStoreWithCompletion { error in
                if error != nil {
                    print("cannot leech \(error!.localizedDescription)")
                    completion(completed: false)
                }
                else {
                    print("leached!!")
                    completion(completed: true)
                }
            }
        }
        else {
            ensemble.mergeWithCompletion{ error in
                if error != nil {
                    print("cannot merge \(error!.localizedDescription)")
                    completion(completed: false)
                }
                else {
                    print("merged!!")
                    completion(completed: true)
                }
            }
        }
    }
    
    // MARK: - Ensemble Delegate Methods
    
    func persistentStoreEnsemble(ensemble: CDEPersistentStoreEnsemble!, didSaveMergeChangesWithNotification notification: NSNotification!) {
        
        print("Database was updated from iCloud")
        
        
        managedObjectContext.mergeChangesFromContextDidSaveNotification(notification)
        NSNotificationCenter.defaultCenter().postNotificationName("DB_UPDATED", object: nil)
    }
    
    func persistentStoreEnsemble(ensemble: CDEPersistentStoreEnsemble!, globalIdentifiersForManagedObjects objects: [AnyObject]!) -> [AnyObject]! {
        return (objects as NSArray).valueForKeyPath("uniqueIdentifier") as! [AnyObject]
    }
    
}


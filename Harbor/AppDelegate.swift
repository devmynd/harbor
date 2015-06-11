//
//  AppDelegate.swift
//  Harbor
//
//  Created by Erin Hochstatter on 11/6/14.
//  Copyright (c) 2014 ekh. All rights reserved.
//

import Cocoa

@NSApplicationMain
class AppDelegate: NSObject, NSApplicationDelegate {
    
    var preferencesPaneWindow: PreferencesPaneWindow?
    var statusView: StatusView?
    var projectList: [Project]?
    let currentRunLoop: NSRunLoop = NSRunLoop.currentRunLoop()
    
    func applicationDidFinishLaunching(aNotification: NSNotification) {
        
        self.fetchApiKeys { (projects) -> () in
            print(projects.count)
        }
        
        preferencesPaneWindow = PreferencesPaneWindow(windowNibName: "PreferencesPaneWindow")
        preferencesPaneWindow?.prefManagedObjectContext = self.managedObjectContext!
        print(self.managedObjectContext!)
        statusView = StatusView()
        fetchRefreshRate()
    }
    
    func showPopover(sender: AnyObject) {
        let popoverViewController = PopoverViewController(nibName: "Popover", bundle: nil)
        statusView!.showPopoverWithViewController(popoverViewController!)
    }
    
    func hidePopover(sender: AnyObject) {
        statusView!.hidePopover()
    }
    
    func applicationWillTerminate(aNotification: NSNotification) {
        // Insert code here to tear down your application
    }
    
    // MARK: CoreData Fetch
    func fetchRefreshRate() {
        let request: NSFetchRequest = NSFetchRequest(entityName: "DMAccount")
        request.sortDescriptors = [NSSortDescriptor(key: "accountDescription", ascending: true)]
    
        do {
            let account = try managedObjectContext!.executeFetchRequest(request).first as? DMAccount
            if let refreshRate = account?.refreshRate {
                setupTimer((refreshRate as NSString).doubleValue)
            } else {
                setupTimer(120)
            }
        } catch let error as NSError {
            print(error)
        }
    }
    
    func setupTimer(refreshRate: Double) {
        
       
        let timer = NSTimer(timeInterval: refreshRate, target: self, selector:"updateData", userInfo: nil, repeats: true)
        currentRunLoop.addTimer(timer, forMode: NSDefaultRunLoopMode)
        
        print("refresh rate: \(refreshRate)")
    }
    
    func updateData(){
        fetchApiKeys { (projects) -> () in
            self.statusView!.updateUI()
            print("updateData completion block")
        }
    }
    
    func fetchApiKeys(completionClosure: (projects: [Project]) -> ()) {
        
        let request: NSFetchRequest = NSFetchRequest(entityName: "DMAccount")
        request.sortDescriptors = [NSSortDescriptor(key: "accountDescription", ascending: true)]
        
        var errorPointer: NSErrorPointer = NSErrorPointer()
        
        var projectArray: [Project] = []
        
        if let fetchResults = managedObjectContext!.executeFetchRequest(request) as? [DMAccount] {
            for account in fetchResults {
                
                self.retrieveProjectsForAccount(account, completionClosure: { (projects) -> () in
                    projectArray += projects
                    completionClosure(projects: projectArray)
                })
                print("apiKey: \(account.apiKey)")
            }
        } else {
            print("fetch error on Popover for apiKey")
        }
    }
    
    func fetchProjectsWithID(id: String) -> [DMProject] {
        
        let request: NSFetchRequest = NSFetchRequest(entityName: "DMProject")
        let projectIdPredicate = NSPredicate(format: "id == %@", id)
        request.predicate = projectIdPredicate
        
        let sortDescriptor: NSSortDescriptor = NSSortDescriptor(key: "repositoryName", ascending: true)
        request.sortDescriptors = [sortDescriptor]
        
        var errorPointer: NSErrorPointer = NSErrorPointer()
        
        let fetchResults = managedObjectContext!.executeFetchRequest(request) as? [DMProject]
        
        return fetchResults!
        
    }
    
    func processProject (hash: AnyObject, account: DMAccount) {
        let project = Project()
        project.id = Int(hash.objectForKey("id") as! NSNumber)
        project.repositoryName = (hash.objectForKey("repository_name") as! String)
        let dmProjectFetchResults = self.fetchProjectsWithID("\(project.id!)")
        
        if dmProjectFetchResults.count == 0 {
            project.active = true;
            
            let dmProject: DMProject = NSEntityDescription.insertNewObjectForEntityForName("DMProject", inManagedObjectContext: self.managedObjectContext!) as! DMProject
            
            dmProject.id = "\(project.id!)"
            dmProject.repositoryName = project.repositoryName!
            dmProject.account = account
            dmProject.active = true
            let errorPointer: NSErrorPointer = NSErrorPointer()
            
            do {
                try self.managedObjectContext?.save()
            } catch var error as NSError {
                errorPointer.memory = error
            }
            
        } else if dmProjectFetchResults.count == 1 {
            
            project.active = dmProjectFetchResults.first?.active.boolValue
            
        } else {
            print("more than one project with ID: \(project.id!)")
        }
        
        let projectBuildJson: Array<AnyObject> = hash.objectForKey("builds") as! Array<AnyObject>
        
        for buildHash in projectBuildJson {
            
            let build = Build()
            build.id =  Int(buildHash.objectForKey("id") as! NSNumber)
            build.uuid =  (buildHash.objectForKey("uuid") as! String)
            build.status =  (buildHash.objectForKey("status") as! String)
            build.commitId =  (buildHash.objectForKey("commit_id") as! String)
            build.message =  (buildHash.objectForKey("message") as! String)
            build.branch =  (buildHash.objectForKey("branch") as! String)
            
            project.builds.append(build)
        }
        
        if project.active == true {
            self.projectList?.append(project)
            
            if project.builds.first!.status == "testing"{
                print("\(project.repositoryName!) & \(project.builds.first!.status!)")
                self.statusView?.hasPendingBuild = false
                
            } else if project.builds.first!.status != "success" {
                print("\(project.repositoryName!) & \(project.builds.first!.status!)")
                self.statusView!.hasFailedBuild = true
            }
        }
    }
    
    
    
    
    func retrieveProjectsForAccount(account: DMAccount, completionClosure: (projects: [Project]) -> ()){
        
        let urlWithKey = "https://www.codeship.io/api/v1/projects.json?api_key=" + account.apiKey
        let urlRequest: NSURLRequest = NSURLRequest(URL: NSURL(string:urlWithKey)!);
        
        NSURLConnection.sendAsynchronousRequest(urlRequest, queue: NSOperationQueue.mainQueue()) { (urlResponse, data, error) -> Void in
            
            let responseDictionary: NSDictionary = NSJSONSerialization.JSONObjectWithData(data, options: NSJSONReadingOptions.AllowFragments) as! NSDictionary
            self.projectList = []
            
            let projectsArray: Array<AnyObject> = responseDictionary.objectForKey("projects") as!Array
            
            self.statusView?.hasFailedBuild = false
            self.statusView?.hasPendingBuild = false
            
            for hash in projectsArray {
                if let repository_name = hash.objectForKey("repository_name") as? String {
                    self.processProject(hash, account: account)
                }
            }
            self.statusView!.updateUI()
            completionClosure(projects: self.projectList!)
            
        }
    }
    
    // MARK: - Core Data stack
    
    lazy var applicationDocumentsDirectory: NSURL = {
        // The directory the application uses to store the Core Data store file. This code uses a directory named "ekh.Harbor" in the user's Application Support directory.
        let urls = NSFileManager.defaultManager().URLsForDirectory(.ApplicationSupportDirectory, inDomains: .UserDomainMask)
        let appSupportURL = urls[urls.count - 1] as NSURL
        return appSupportURL.URLByAppendingPathComponent("dvm.Harbor")
        }()
    
    lazy var managedObjectModel: NSManagedObjectModel = {
        // The managed object model for the application. This property is not optional. It is a fatal error for the application not to be able to find and load its model.
        let modelURL = NSBundle.mainBundle().URLForResource("Harbor", withExtension: "momd")!
        return NSManagedObjectModel(contentsOfURL: modelURL)!
        }()
    
    lazy var persistentStoreCoordinator: NSPersistentStoreCoordinator? = {
        // The persistent store coordinator for the application. This implementation creates and return a coordinator, having added the store for the application to it. (The directory for the store is created, if necessary.) This property is optional since there are legitimate error conditions that could cause the creation of the store to fail.
        let fileManager = NSFileManager.defaultManager()
        var shouldFail = false
        var error: NSError? = nil
        var failureReason = "There was an error creating or loading the application's saved data."
        
        // Make sure the application files directory is there
        let propertiesOpt: [NSObject: AnyObject]?
        do {
            propertiesOpt = try self.applicationDocumentsDirectory.resourceValuesForKeys([NSURLIsDirectoryKey])
        } catch var error1 as NSError {
            error = error1
            propertiesOpt = nil
        } catch {
            fatalError()
        }
        if let properties = propertiesOpt {
            if !properties[NSURLIsDirectoryKey]!.boolValue {
                failureReason = "Expected a folder to store application data, found a file \(self.applicationDocumentsDirectory.path)."
                shouldFail = true
            }
        } else if error!.code == NSFileReadNoSuchFileError {
            error = nil
            do {
                dtry fileManager.createDirectoryAtPath(self.applicationDocumentsDirectory.path!, withIntermediateDirectories: true, attributes: nil)
            } catch var error1 as NSError {
                error = error1
            } catch {
                fatalError()
            }
        }
        
        // Create the coordinator and store
        var coordinator: NSPersistentStoreCoordinator?
        if !shouldFail && (error == nil) {
            coordinator = NSPersistentStoreCoordinator(managedObjectModel: self.managedObjectModel)
            let url = self.applicationDocumentsDirectory.URLByAppendingPathComponent("Harbor.storedata")
            do {
                try coordinator!.addPersistentStoreWithType(NSXMLStoreType, configuration: nil, URL: url, options: nil)
            } catch var error1 as NSError {
                error = error1
                coordinator = nil
            } catch {
                fatalError()
            }
        }
        
        if shouldFail || (error != nil) {
            // Report any error we got.
            let dict = NSMutableDictionary()
            dict[NSLocalizedDescriptionKey] = "Failed to initialize the application's saved data"
            dict[NSLocalizedFailureReasonErrorKey] = failureReason
            if error != nil {
                dict[NSUnderlyingErrorKey] = error
            }
            error = NSError(domain: "YOUR_ERROR_DOMAIN", code: 9999, userInfo: dict as [NSObject : AnyObject])
            NSApplication.sharedApplication().presentError(error!)
            return nil
        } else {
            return coordinator
        }
        }()
    
    lazy var managedObjectContext: NSManagedObjectContext? = {
        // Returns the managed object context for the application (which is already bound to the persistent store coordinator for the application.) This property is optional since there are legitimate error conditions that could cause the creation of the context to fail.
        let coordinator = self.persistentStoreCoordinator
        if coordinator == nil {
            return nil
        }
        var managedObjectContext = NSManagedObjectContext()
        managedObjectContext.persistentStoreCoordinator = coordinator
        return managedObjectContext
        }()
    
    // MARK: - Core Data Saving and Undo support
    
    @IBAction func saveAction(sender: AnyObject!) {
        // Performs the save action for the application, which is to send the save: message to the application's managed object context. Any encountered errors are presented to the user.
        if let moc = self.managedObjectContext {
            if !moc.commitEditing() {
                NSLog("\(NSStringFromClass(self.dynamicType)) unable to commit editing before saving")
            }
            var error: NSError? = nil
            if moc.hasChanges && !moc.save() {
                NSApplication.sharedApplication().presentError(error!)
            }
        }
    }
    
    func windowWillReturnUndoManager(window: NSWindow) -> NSUndoManager? {
        // Returns the NSUndoManager for the application. In this case, the manager returned is that of the managed object context for the application.
        if let moc = self.managedObjectContext {
            return moc.undoManager
        } else {
            return nil
        }
    }
    
    func applicationShouldTerminate(sender: NSApplication) -> NSApplicationTerminateReply {
        // Save changes in the application's managed object context before the application terminates.
        
        if let moc = managedObjectContext {
            if !moc.commitEditing() {
                NSLog("\(NSStringFromClass(self.dynamicType)) unable to commit editing to terminate")
                return .TerminateCancel
            }
            
            if !moc.hasChanges {
                return .TerminateNow
            }
            
            var error: NSError? = nil
            do {
                try moc.save()
            } catch var error1 as NSError {
                error = error1
                // Customize this code block to include application-specific recovery steps.
                let result = sender.presentError(error!)
                if (result) {
                    return .TerminateCancel
                }
                
                let question = NSLocalizedString("Could not save changes while quitting. Quit anyway?", comment: "Quit without saves error question message")
                let info = NSLocalizedString("Quitting now will lose any changes you have made since the last successful save", comment: "Quit without saves error question info");
                let quitButton = NSLocalizedString("Quit anyway", comment: "Quit anyway button title")
                let cancelButton = NSLocalizedString("Cancel", comment: "Cancel button title")
                let alert = NSAlert()
                alert.messageText = question
                alert.informativeText = info
                alert.addButtonWithTitle(quitButton)
                alert.addButtonWithTitle(cancelButton)
                
                let answer = alert.runModal()
                if answer == NSAlertFirstButtonReturn {
                    return .TerminateCancel
                }
            }
        }
        // If we got here, it is time to quit.
        return .TerminateNow
    }
    
}


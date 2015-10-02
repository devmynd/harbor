//
//  AppDelegate.swift
//  Harbor
//
//  Created by Erin Hochstatter on 6/25/15.
//  Copyright © 2015 DevMynd. All rights reserved.
//

import Cocoa
import Alamofire

@NSApplicationMain
class AppDelegate: NSObject, NSApplicationDelegate, StatusMenuDelegate {

    @IBOutlet weak var statusItemMenu: StatusMenu!
    
    var preferencesWindowController: PreferencesPaneWindowController!
    var projects: [Project]?
    let defaults = NSUserDefaults()
    
    var projectsProvider: ProjectsInteractor!
    var timerCoordinator: TimerCoordinator!
    var settingsManager:  SettingsManager!
    
    override init() {
        super.init()
        
        // inject the proper modules
        Injector
            .module(CoreModuleType.self, CoreModule()).start()
    }
    
    func applicationDidFinishLaunching(aNotification: NSNotification) {
        self.preferencesWindowController = PreferencesPaneWindowController(windowNibName: "PreferencesPaneWindowController")
        
        self.projectsProvider = core().inject()
        self.timerCoordinator = core().inject()
        self.settingsManager  = core().inject()

        //
//        Uncomment to Clear keychain & Defaults for testing.
//
//        KeychainWrapper.removeObjectForKey("ApiKey")
//        defaults.removeObjectForKey("RefreshRate")
//        defaults.removeObjectForKey("DisabledProjects")

        self.statusItemMenu.statusMenuDelegate = self
        self.statusItemMenu.createCoreMenuItems()
   
        // run startup logic
        self.startup()
    }
    
    //
    // MARK: Startup
    //
    
    private func startup() {
        self.timerCoordinator.startTimer()
        self.refreshProjects()
    }
    
    private func refreshProjects() {
        if !self.settingsManager.apiKey.isEmpty {
            self.projectsProvider.refreshProjects()
        } else {
            self.showPreferencesPane()
        }
    }
   
   
    //
    // MARK: StatusMenuDelegate
    //
    
    func statusMenuDidSelectPreferences(statusMenu: StatusMenu) {
        self.showPreferencesPane()
    }
    
    private func showPreferencesPane() {
        self.preferencesWindowController.window?.center()
        self.preferencesWindowController.window?.orderFront(self)
        
        // Show your window in front of all other apps
        NSApp.activateIgnoringOtherApps(true)
    }
        
}


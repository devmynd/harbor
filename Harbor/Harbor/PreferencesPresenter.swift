//
//  PreferencesPresenter.swift
//  Harbor
//
//  Created by Erin Hochstatter on 9/23/15.
//  Copyright © 2015 DevMynd. All rights reserved.
//

import Foundation
import Cocoa

class PreferencesPresenter {
    
    //
    // MARK: Dependencies
    //
    
    private let projectsStore   = ProjectsProvider.instance
    private let settingsManager = SettingsManager.instance
    
    //
    // MARK: Properties
    //
    
    private weak var view: PreferencesView!

    private var apiKey:       String = ""
    private var refreshRate:  Double = 60.0
    private var needsRefresh: Bool   = true
    private var allProjects:  [Project]

    init(view: PreferencesView) {
        self.view = view
        self.allProjects = [Project]()
    }
    
    //
    // MARK: Presentation Cycle
    //
    
    func didInitialize() {
        self.projectsStore.addHandler(self.refreshProjects)
    }
    
    func didBecomeActive() {
        self.refreshIfNecessary()
    }
    
    func didResignActive() {
        self.refreshIfNecessary()
    }
    
    private func refreshIfNecessary() {
        if(self.needsRefresh) {
            self.refreshConfiguration()
            self.needsRefresh = false
        }
    }
    
    private func setNeedsRefresh() {
        if(!self.needsRefresh) {
            self.needsRefresh = true
        }
    }
    
    //
    // MARK: Preferences
    //
    
    func savePreferences() {
        let existingApiKey = self.settingsManager.apiKey
        
        // persist our configuration
        self.settingsManager.apiKey = self.apiKey
        self.settingsManager.refreshRate = self.refreshRate
        
        // serialize the hidden projects
        self.settingsManager.disabledProjectIds = self.allProjects.reduce([Int]()) { (var memo, project) in
            if !project.isEnabled {
                memo.append(project.id)
            }
            return memo
        }
        
        self.needsRefresh = false
        
        if existingApiKey != self.settingsManager.apiKey {
            (NSApplication.sharedApplication().delegate as? AppDelegate)?.refreshProjects()
//            self.projectsStore.refreshProjects()
        }
    }
    
    func updateApiKey(apiKey: String) {
        self.apiKey = apiKey
        self.setNeedsRefresh()
    }
    
    func updateRefreshRate(refreshRate: String) {
        self.refreshRate = (refreshRate as NSString).doubleValue
        self.setNeedsRefresh()
    }
    
    private func refreshConfiguration() {
        // load data from user defaults
        self.refreshRate = self.settingsManager.refreshRate
        self.apiKey = self.settingsManager.apiKey
        
        // update our view after refreshing
        self.view.updateApiKey(self.apiKey)
        self.view.updateRefreshRate(self.refreshRate.description)
    }
    
    //
    // MARK: Projects
    //
    
    var numberOfProjects: Int {
        get { return self.allProjects.count }
    }
    
    func projectAtIndex(index: Int) -> Project {
        return self.allProjects[index];
    }
    
    func toggleEnabledStateForProjectAtIndex(index: Int) {
        let project = self.projectAtIndex(index)
        project.isEnabled = !project.isEnabled
    
        self.setNeedsRefresh()
    }

    private func refreshProjects(projects: [Project]) {
        self.allProjects = projects
                
        // notify the view that the projects refreshed
        self.view.updateProjects(self.allProjects)
    }
    
    //
    // MARK: Accessors
    //
    
    private var defaults: NSUserDefaults {
        get { return NSUserDefaults.standardUserDefaults() }
    }
}
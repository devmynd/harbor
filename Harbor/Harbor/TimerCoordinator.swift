//
//  TimerCoordinator.swift
//  Harbor
//
//  Created by Erin Hochstatter on 9/24/15.
//  Copyright © 2015 DevMynd. All rights reserved.
//

import Foundation

class TimerCoordinator : NSObject {

    static let instance = TimerCoordinator(
        runLoop:          NSRunLoop.mainRunLoop(),
        projectsProvider: ProjectsProvider.instance,
        settingsManager:  SettingsManager.instance
    )
    
    //
    // MARK: Dependencies
    //
    
    var currentRunLoop:   RunLoop!          = nil
    var projectsProvider: ProjectsProvider! = nil
    var settingsManager:  SettingsManager!  = nil
    
    //
    // MARK: Properties
    //
    
    private var currentTimer: NSTimer?
    
    init(runLoop: RunLoop, projectsProvider: ProjectsProvider, settingsManager: SettingsManager) {
        self.currentRunLoop   = runLoop
        self.projectsProvider = projectsProvider
        self.settingsManager  = settingsManager
        
        super.init()
        
        settingsManager.observeNotification(.RefreshRate) { notification in
            self.startTimer()
        }
    }
    
    //
    // MARK: Scheduling
    //
    
    func startTimer() -> NSTimer? {
        return self.setupTimer(self.settingsManager.refreshRate)
    }
    
    private func setupTimer(refreshRate: Double) -> NSTimer? {
        // cancel current timer if necessary
        self.currentTimer?.invalidate()
        self.currentTimer = nil
        
        if !refreshRate.isZero {
            self.currentTimer = NSTimer(timeInterval: refreshRate, target: self, selector:"handleUpdateTimer:", userInfo: nil, repeats: true)
            self.currentRunLoop.addTimer(self.currentTimer!, forMode: NSDefaultRunLoopMode)
        }
        
        return self.currentTimer
    }
    
    func handleUpdateTimer(timer: NSTimer) {
        if(timer == self.currentTimer) {
            self.projectsProvider.refreshProjects()
        }
    }
    
}
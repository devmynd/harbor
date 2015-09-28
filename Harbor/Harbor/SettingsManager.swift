//
//  SettingsManager.swift
//  Harbor
//
//  Created by Erin Hochstatter on 9/24/15.
//  Copyright © 2015 DevMynd. All rights reserved.
//

import Foundation

public class SettingsManager {
    
    private enum Key: String {
        case ApiKey             =   "ApiKey"
        case RefreshRate        =   "RefreshRate"
        case DisabledProjects   =   "DisabledProjects"
    }

    static let instance: SettingsManager = SettingsManager(
        userDefaults: NSUserDefaults.standardUserDefaults(),
        keychain: KeychainWrapper(),
        notificationCenter: NSNotificationCenter.defaultCenter()
    )

    //
    // MARK: Properties
    //
    
    private let defaults:           UserDefaults
    private let keychain:           Keychain
    private let notificationCenter: NotificationCenter
    
    public var apiKey: String {
        didSet {
            keychain.setString(self.apiKey, forKey: Key.ApiKey.rawValue)
            self.postNotification(.ApiKey)
        }
    }
    
    public var refreshRate: Double {
        didSet {
            self.defaults.setDouble(self.refreshRate, forKey: Key.RefreshRate.rawValue)
            self.postNotification(.RefreshRate)
        }
    }
    
    public var disabledProjectIds: [Int] {
        didSet {
            self.defaults.setObject(self.disabledProjectIds, forKey: Key.DisabledProjects.rawValue)
            self.postNotification(.DisabledProjects)
        }
    }
    
    public init(userDefaults: UserDefaults, keychain: Keychain, notificationCenter: NotificationCenter) {
        self.defaults           = userDefaults
        self.keychain           = keychain
        self.notificationCenter = notificationCenter

        self.refreshRate = self.defaults.doubleForKey(Key.RefreshRate.rawValue)
        
        if let disabledProjectIds = self.defaults.objectForKey(Key.DisabledProjects.rawValue) as? [Int]{
            self.disabledProjectIds = disabledProjectIds
        } else {
            self.disabledProjectIds = [Int]()
        }
        
        if let apiKey = keychain.stringForKey(Key.ApiKey.rawValue) {
            self.apiKey = apiKey
        } else {
            self.apiKey = ""
        }
    }
    
}

//
// MARK: Notifications
//

extension SettingsManager {
    
    public enum NotificationName: String {
        case ApiKey             =   "ApiKey"
        case RefreshRate        =   "RefreshRate"
        case DisabledProjects   =   "DisabledProjects"
    }
    
    func observeNotification(notification: SettingsManager.NotificationName, handler: (NSNotification -> Void)) -> NSObjectProtocol {
        return self.notificationCenter.addObserverForName(notification.rawValue, object: nil, queue: nil, usingBlock: handler)
    }
    
    private func postNotification(notification: SettingsManager.NotificationName) {
        self.notificationCenter.postNotificationName(notification.rawValue, object: nil)
    }
    
}

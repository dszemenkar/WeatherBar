//
//  AppDelegate.swift
//  WeatherBar
//
//  Created by David Szemenkar on 2018-03-08.
//  Copyright © 2018 David Szemenkar. All rights reserved.
//

import Cocoa

@NSApplicationMain
class AppDelegate: NSObject, NSApplicationDelegate {
    
    var feed: JSON?
    var displayMode = 0
    var updateDisplayTimer: Timer?
    var fetchFeedTimer: Timer?
    
    let statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
    
    func applicationDidFinishLaunching(_ aNotification: Notification) {
        
        statusItem.button?.title = "Fetching..."
        statusItem.menu = NSMenu()
        addConfigurationMenuItem()
        loadSettings()
        
        let defaultSettings = ["latitude" : "51.507222", "logitude" : "-0.1275", "units" : "0"]
        UserDefaults.standard.register(defaults: defaultSettings)
        
        let nc = NotificationCenter.default
        nc.addObserver(self, selector: #selector(loadSettings), name: Notification.Name("SettingsChanged"), object: nil)
        
    }
    
    func applicationWillTerminate(_ aNotification: Notification) {
        // Insert code here to tear down your application
    }
    
    func addConfigurationMenuItem() {
        
        let seperator = NSMenuItem(title: "Settings", action: #selector(showSettings), keyEquivalent: "")
        
        statusItem.menu?.addItem(seperator)
    }
    
    @objc func showSettings(_ sender: NSMenuItem) {
        
        updateDisplayTimer?.invalidate()
        
        let storyboard = NSStoryboard(name: NSStoryboard.Name(rawValue: "Main"), bundle: nil)
        guard let vc = storyboard.instantiateController(withIdentifier: NSStoryboard.SceneIdentifier(rawValue: "ViewController")) as? ViewController else { return }
        
        let popoverView = NSPopover()
        popoverView.contentViewController = vc
        popoverView.behavior = .transient
        popoverView.show(relativeTo: statusItem.button!.bounds, of: statusItem.button!, preferredEdge: .maxY)
    }
    
    @objc func fetchFeed() {
        
        let defaults = UserDefaults.standard
        
        DispatchQueue.global(qos: .utility).async { [unowned self] in
            
            //1
            let latitude = defaults.double(forKey: "latitude")
            let longitude = defaults.double(forKey: "longitude")
            
            var dataSource = "https://api.darksky.net/forecast/\(API_KEY)/\(latitude),\(longitude)"
            
            if defaults.integer(forKey: "units") == 0 {
                
                dataSource += "?units=si"
            }
            
            //2
            guard let url = URL(string: dataSource) else { return }
            guard let data = try? Data(contentsOf: url) else {
                DispatchQueue.main.async { [unowned self] in
                    
                    self.statusItem.button?.title = "Bad API call"
                    
                }
                return
            }
            
            //3
            let newFeed = JSON(data: data)
            
            DispatchQueue.main.async {
                
                self.feed = newFeed
                self.updateDisplay()
                self.refreshSubmenuItems()
            }
            
        }
        
    }
    
    @objc func loadSettings() {
        
        fetchFeedTimer = Timer.scheduledTimer(timeInterval: 60 * 5, target: self, selector: #selector(fetchFeed), userInfo: nil, repeats: true)
        
        fetchFeedTimer?.tolerance = 60
        
        fetchFeed()
    }
    
    func updateDisplay() {
        
        guard let feed = feed else { return }
        var text = "Error"
        
        //show current temperature
        let summary = feed["currently"]["summary"].string ?? ""
            
        if let temperature = feed["currently"]["temperature"].int {
            text = "\(summary) \(temperature)°"
        }
            

        statusItem.button?.title = text
    }
    
    @objc func changeDisplayMode() {
        
        displayMode += 1
        
        if displayMode > 3 {
            displayMode = 0
        }
        
        updateDisplay()
    }
    
    func refreshSubmenuItems() {
        
        guard let feed = feed else { return }
        
        statusItem.menu?.removeAllItems()
        
        for forecast in feed["hourly"]["data"].arrayValue.prefix(10) {
            
            let date = Date(timeIntervalSince1970: forecast["time"].doubleValue)
            let formatter = DateFormatter()
            formatter.timeStyle = .short
            
            let formattedDate = formatter.string(from: date)
            
            let summary = forecast["summary"].stringValue
            let temperature = forecast["temperature"].intValue
            let title = "\(formattedDate): \(summary) (\(temperature)°)"
            
            let menuItem = NSMenuItem(title: title, action: nil, keyEquivalent: "")
            
            statusItem.menu?.addItem(menuItem)
        }
        
        statusItem.menu?.addItem(NSMenuItem.separator())
        addConfigurationMenuItem()
    }
    
    
}


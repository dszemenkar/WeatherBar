//
//  ViewController.swift
//  WeatherBar
//
//  Created by David Szemenkar on 2018-03-08.
//  Copyright © 2018 David Szemenkar. All rights reserved.
//

import Cocoa
import MapKit

class ViewController: NSViewController {

    @IBOutlet var mapView: MKMapView!
    @IBOutlet var apiKey: NSTextField!
    @IBOutlet var statusBarOption: NSPopUpButton!
    
    @IBOutlet var units: NSSegmentedControl!
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
    }

    override var representedObject: Any? {
        didSet {
        // Update the view, if already loaded.
        }
    }

    @IBAction func showPoweredBy(_ sender: Any) {
        NSWorkspace.shared.open(URL(string: "https://darksky.net/poweredby/")!)
    }
    override func viewWillAppear() {
        let defaults = UserDefaults.standard
        let savedLat = defaults.double(forKey: "latitude")
        let savedLong = defaults.double(forKey: "longitude")
        let savedUnits = defaults.integer(forKey: "units")
        
        units.selectedSegment = savedUnits
        
        let savedLocation = CLLocationCoordinate2D(latitude: savedLat, longitude: savedLong)
        addPin(at: savedLocation)
        mapView.centerCoordinate = savedLocation
        
        let recognizer = NSClickGestureRecognizer(target: self, action: #selector(mapTapped))
        mapView.addGestureRecognizer(recognizer)
    }
    
    func addPin(at coordinate: CLLocationCoordinate2D){
        let annotation = MKPointAnnotation()
        annotation.coordinate = coordinate
        annotation.title = "Weather location"
        mapView.addAnnotation(annotation)
    }
    @objc func mapTapped(recognizer: NSClickGestureRecognizer){
        mapView.removeAnnotations(mapView.annotations)
        let location = recognizer.location(in: mapView)
        let coordinate = mapView.convert(location, toCoordinateFrom: mapView)
        addPin(at: coordinate)
    }
    
    override func viewWillDisappear() {
        super.viewWillDisappear()
        
        let defaults = UserDefaults.standard
        let annotation = mapView.annotations[0]
        
        defaults.set(annotation.coordinate.latitude, forKey: "latitude")
        defaults.set(annotation.coordinate.longitude, forKey: "longitude")
        defaults.set(units.selectedSegment, forKey: "units")
        
        let nc = NotificationCenter.default
        nc.post(name: NSNotification.Name("SettingsChanged"), object: nil)
        
        
    }
}


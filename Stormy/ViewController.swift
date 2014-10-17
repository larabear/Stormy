//
//  ViewController.swift
//  Stormy
//
//  Created by larabear on 10/16/14.
//  Copyright (c) 2014 larabear. All rights reserved.
//

import UIKit
import CoreLocation
class ViewController: UIViewController, CLLocationManagerDelegate {
    
    @IBOutlet weak var iconView: UIImageView!
    @IBOutlet weak var currentTimeLabel: UILabel!
    @IBOutlet weak var tempertureLabel: UILabel!
    @IBOutlet weak var humidityLabel: UILabel!
    @IBOutlet weak var precipitationLabel: UILabel!
    @IBOutlet weak var summaryLabel: UILabel!
    @IBOutlet weak var refreshButton: UIButton!
    @IBOutlet weak var refreshActivityIndicator: UIActivityIndicatorView!
    @IBOutlet weak var cityLabel: UILabel!
    
    private let apiKey="23fb96deeebf83a6be954db07bb0b286"
    let locationManager = CLLocationManager()
    var longtitude:Double!
    var latitude:Double!
    var city:String!
    var firstLocationRetrieve:Bool=false
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        refreshActivityIndicator.hidden=true
        self.locationManager.requestAlwaysAuthorization() // Ask for Authorisation from the User.
        
        // For use in foreground
        
        self.locationManager.requestWhenInUseAuthorization()
        
        if (CLLocationManager.locationServicesEnabled())
        {
            locationManager.delegate = self
            locationManager.desiredAccuracy = kCLLocationAccuracyNearestTenMeters
            locationManager.startUpdatingLocation()
        }

    }
    
    func getCurrentWeatherData()->Void{
        let baseUrl=NSURL(string: "https://api.forecast.io/forecast/\(apiKey)/")
        var coor = NSString(format:"%.3f,%.3f", latitude!, longtitude!)
        let forecastUrl=NSURL(string: coor, relativeToURL: baseUrl)
        let sharedSession=NSURLSession.sharedSession()
        let downloadTask: NSURLSessionDownloadTask = sharedSession.downloadTaskWithURL(forecastUrl, completionHandler: { (location: NSURL!, response: NSURLResponse!, error: NSError!) -> Void in
            //            var urlContents=NSString.stringWithContentsOfURL(location, encoding: NSUTF8StringEncoding,error: nil)
            //            println(urlContents)
            if(error==nil){
                let dataObject=NSData(contentsOfURL:location)
                let weatherDictionary: NSDictionary=NSJSONSerialization.JSONObjectWithData(dataObject, options: nil, error: nil) as NSDictionary//json object to dictionary
                let currentWeather=Current(weatherDictionary: weatherDictionary)
                dispatch_async(dispatch_get_main_queue(), { () -> Void in
                    self.tempertureLabel.text="\(currentWeather.temperature)"
                    self.iconView.image = currentWeather.icon!
                    self.currentTimeLabel.text = "At \(currentWeather.currentTime!) it is"
                    self.humidityLabel.text = "\(currentWeather.humidity)"
                    self.precipitationLabel.text = "\(currentWeather.precipProbability)"
                    self.summaryLabel.text = "\(currentWeather.summary)"
                    self.cityLabel.text="\(self.city!)"
                    self.refreshActivityIndicator.stopAnimating()
                    self.refreshActivityIndicator.hidden=true
                    self.refreshButton.hidden=false
                })
            }else{
                let networkIssueController=UIAlertController(title: "Error", message: "Unable to load data. Connectivity error!", preferredStyle: .Alert)
                let okButton=UIAlertAction(title: "OK", style: .Default, handler: nil)
                networkIssueController.addAction(okButton)
                let cancelButton=UIAlertAction(title: "Cancel", style: .Cancel, handler: nil)
                networkIssueController.addAction(cancelButton)
                dispatch_async(dispatch_get_main_queue(), { () -> Void in
                    self.refreshActivityIndicator.stopAnimating()
                    self.refreshActivityIndicator.hidden=true
                    self.refreshButton.hidden=false
                })
                self.presentViewController(networkIssueController, animated: true, completion: nil)
            }
        })
        downloadTask.resume()
        
    }
    
    @IBAction func refresh() {
        firstLocationRetrieve=false
        refreshButton.hidden=true
        refreshActivityIndicator.hidden=false
        refreshActivityIndicator.startAnimating()
        locationManager.startUpdatingLocation()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    func locationManager(manager: CLLocationManager!, didFailWithError error: NSError!) {
        
        println("Error while updating location \(error.localizedDescription)")
        
    }
    func locationManager(manager:CLLocationManager, didUpdateLocations location:[CLLocation]!) {
        let currentLocation : CLLocation = location.last!
        longtitude=currentLocation.coordinate.longitude
        latitude=currentLocation.coordinate.latitude
        CLGeocoder().reverseGeocodeLocation(manager.location, completionHandler: {(placemarks, error)->Void in
                if (error != nil) {
                println(error.localizedDescription)
                return
                
            }
            if placemarks.count > 0 {
                let pm = placemarks[0] as CLPlacemark
                self.displayLocationInfo(pm)
            } else {
                println("Problem with the data received from geocoder")
            }
        })
        getCurrentWeatherData()
    }
    func displayLocationInfo(placemark: CLPlacemark) {
        //stop updating location to save battery life
        locationManager.stopUpdatingLocation()
        if(placemark.locality != nil&&placemark.administrativeArea != nil){
            city=("\(placemark.locality), \(placemark.administrativeArea)")
        }
    }

}


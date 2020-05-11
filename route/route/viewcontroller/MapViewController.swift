//
//  MapViewController.swift
//  route
//
//  Created by flower on 06/09/2019.
//  Copyright © 2019 waterflower. All rights reserved.
//

import UIKit
import CoreLocation
import GoogleMaps
import Firebase
import MessageUI

class MapViewController: UIViewController, GMSMapViewDelegate, CLLocationManagerDelegate, MFMailComposeViewControllerDelegate {

    @IBOutlet weak var googleMapView: GMSMapView!
    @IBOutlet weak var rightmenuView: UIView!
    @IBOutlet weak var dateLabel: UILabel!
    @IBOutlet weak var drawBtn: UIButton!{
        didSet{
            drawBtn.backgroundColor = UIColor.white
            drawBtn.setTitleColor(UIColor.black, for: .normal)
        }
    }
    @IBOutlet weak var rotuesettingView: UIView!
    @IBOutlet weak var routeTitleTextView: UITextField!
    @IBOutlet weak var settingTodayButton: UIButton! {
        didSet{
            settingTodayButton.backgroundColor = UIColor.black
            settingTodayButton.setTitleColor(UIColor.white, for: .normal)
        }
    }
    @IBOutlet weak var settingDailyButton: UIButton! {
        didSet{
            settingDailyButton.backgroundColor = UIColor.white
            settingDailyButton.setTitleColor(UIColor.black, for: .normal)
        }
    }
    @IBOutlet weak var settingEventTextView: UITextView!
    @IBOutlet weak var settingcancelButton: UIButton!
    @IBOutlet weak var settingAddButton: UIButton!
    
    var route_type = "today" // today, daily
    var new_marker:GMSMarker?
    var setting_marker_coordinate: CLLocationCoordinate2D?
    var new_polyline: GMSPolyline?
    var selected_marker: DeleteMarker?
    var drawn_type = "new"//// what is drawn type i.e when shows setting window(from drawn new route or clicking setting marker) new and existing
    
    lazy var canvasView:CanvasView = {
        
        var overlayView = CanvasView(frame: self.googleMapView.frame)
        overlayView.isUserInteractionEnabled = true
        overlayView.delegate = self
        return overlayView
        
    }()
    
    var locationManager = HelperLocationManager.sharedInstance
    var isDrawingModeEnabled = false
    var coordinates = [CLLocationCoordinate2D]()
    var userDrawablePolygons = [GMSPolyline]()
    var polygonDeleteMarkers = [DeleteMarker]()
    
    ///////   for activity indicator  //////////
    var activityIndicator: UIActivityIndicatorView = UIActivityIndicatorView();
    var overlayView:UIView = UIView();
    
    ///////  send email view
    var sendemailview = SendEmailView()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        sendemailview = Bundle.main.loadNibNamed("SendEmailView", owner: self, options: nil)?.first as! SendEmailView
        
        self.settingEventTextView.layer.borderWidth = 1
        self.settingEventTextView.layer.borderColor = UIColor.black.cgColor
        googleMapView.delegate = self
        self.googleMapView.isMyLocationEnabled = true
        
        let nc = NotificationCenter.default // Note that default is now a property, not a method call
        nc.addObserver(forName:.sendLocation,object:nil, queue:nil) {  notification in
            // Handle notification
            guard let userInfo = notification.userInfo,let currentLocation = userInfo["location"] as? CLLocation else {
                
                return
            }
            
            let cameraPos = GMSCameraPosition(target: currentLocation.coordinate, zoom: 15, bearing: 0, viewingAngle: 0)
            self.googleMapView.animate(to: cameraPos)
            
            
        }
        self.addPolylines(select_route_type: "today")
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    override func viewWillAppear(_ animated: Bool) {
        if Global.selected_route_create_time != 0 {
            
            self.dateLabel.text = Global.selected_route_title
            
            self.startActivityIndicator()
            let _ =  userDrawablePolygons.map{ $0.map = nil }
            let _ = polygonDeleteMarkers.map{ $0.map = nil}
            polygonDeleteMarkers.removeAll()
            userDrawablePolygons.removeAll()
            
            var coordinate2d_array = [CLLocationCoordinate2D]()
            let ref = Database.database().reference()
            ref.child("routes").child(Auth.auth().currentUser!.uid).observeSingleEvent(of: .value, with: {(snapshot) in
                for child in snapshot.children {
                    if let child = child as? DataSnapshot, let value = child.value {
                        let db_route_type = (value as! [String: AnyObject])["route_type"] as? String
                        let db_create_time = (value as! [String: AnyObject])["create_time"] as? Int
                        
                        let db_route_event = (value as! [String: AnyObject])["route_event"] as? String
                        let db_route_title = (value as! [String: AnyObject])["route_title"] as? String
                        if db_create_time == Global.selected_route_create_time {
                            child.ref.child("coordinate").observeSingleEvent(of: .value, with: {(sub_snapshot) in
                                for sub_child in sub_snapshot.children {
                                    let sub_child = sub_child as! DataSnapshot
                                    let latlng_string = sub_child.value as! String
                                    let latlng: [String] = latlng_string.components(separatedBy: " ")
                                    
                                    let lat = Double(latlng[0]) as! CLLocationDegrees
                                    let lng = Double(latlng[1]) as! CLLocationDegrees
                                    coordinate2d_array.append(CLLocationCoordinate2D(latitude: lat, longitude: lng))
                                }
                                let path = GMSMutablePath()
                                for loc in coordinate2d_array {
                                    path.add(loc)
                                }
                                
                                let newpolygon = GMSPolyline(path: path)
                                newpolygon.strokeWidth = 3
                                newpolygon.strokeColor = UIColor.black
                                newpolygon.map = self.googleMapView
                                self.userDrawablePolygons.append(newpolygon)
                                self.addPolygonDeleteAnnotation(endCoordinate: coordinate2d_array.last!, polygon: newpolygon, route_title: db_route_title!, route_type: db_route_type!, route_event: db_route_event!, create_time: db_create_time!)
                                coordinate2d_array = []
                            })
                        }
                    }
                }
                self.stopActivityIndicator()
                Global.selected_route_create_time = 0
            })
        }
    }
    
    func  addPolylines(select_route_type: String) {
        self.startActivityIndicator()
        
        let _ =  userDrawablePolygons.map{ $0.map = nil }
        let _ = polygonDeleteMarkers.map{ $0.map = nil}
        polygonDeleteMarkers.removeAll()
        userDrawablePolygons.removeAll()
        
        var coordinate2d_array = [CLLocationCoordinate2D]()
        let ref = Database.database().reference()
        ref.child("routes").child(Auth.auth().currentUser!.uid).observeSingleEvent(of: .value, with: {(snapshot) in
            for child in snapshot.children {
                if let child = child as? DataSnapshot, let value = child.value {
                    let db_route_type = (value as! [String: AnyObject])["route_type"] as? String
                    let db_create_time = (value as! [String: AnyObject])["create_time"] as? Int
                    let current_date = Date()
                    let dateVar = Date.init(timeIntervalSince1970: TimeInterval(db_create_time!)/1000)
                    let dateFormatter = DateFormatter()
                    dateFormatter.dateFormat = "yyyy"
                    let db_year = dateFormatter.string(from: dateVar)
                    let current_year = dateFormatter.string(from: current_date)
                    dateFormatter.dateFormat = "MM"
                    let db_month = dateFormatter.string(from: dateVar)
                    let current_month = dateFormatter.string(from: current_date)
                    dateFormatter.dateFormat = "dd"
                    let db_day = dateFormatter.string(from: dateVar)
                    let current_day = dateFormatter.string(from: current_date)
                    if select_route_type == "today" {
//                        if db_route_type != select_route_type {
//                            continue
//                        }

                        if db_year != current_year || db_month != current_month || db_day != current_day {
                            continue
                        }
                    } else if select_route_type == "daily" {
                        if (db_route_type == "today") && (db_year != current_year || db_month != current_month || db_day != current_day) {
                            continue
                        }
                    }
                   
                    let db_route_event = (value as! [String: AnyObject])["route_event"] as? String
                    let db_route_title = (value as! [String: AnyObject])["route_title"] as? String
                
                    child.ref.child("coordinate").observeSingleEvent(of: .value, with: {(sub_snapshot) in
                        for sub_child in sub_snapshot.children {
                            let sub_child = sub_child as! DataSnapshot
                            let latlng_string = sub_child.value as! String
                            let latlng: [String] = latlng_string.components(separatedBy: " ")
                            
                            let lat = Double(latlng[0]) as! CLLocationDegrees
                            let lng = Double(latlng[1]) as! CLLocationDegrees
                            coordinate2d_array.append(CLLocationCoordinate2D(latitude: lat, longitude: lng))
//                                if coordinate2d_array.count > 2 {
//                                    self.addPolyGonInMapView(drawableLoc: coordinate2d_array)
//                                }
                        }
                        let path = GMSMutablePath()
                        for loc in coordinate2d_array {
                            path.add(loc)
                        }
                        
                        let newpolygon = GMSPolyline(path: path)
                        newpolygon.strokeWidth = 3
                        newpolygon.strokeColor = UIColor.black
                        newpolygon.map = self.googleMapView
                        self.userDrawablePolygons.append(newpolygon)
                        self.addPolygonDeleteAnnotation(endCoordinate: coordinate2d_array.last!, polygon: newpolygon, route_title: db_route_title!, route_type: db_route_type!, route_event: db_route_event!, create_time: db_create_time!)
                        coordinate2d_array = []
                    })
                }
            }
            self.stopActivityIndicator()
        })
    }
    
    @IBAction func rightmenuButtonClick(_ sender: Any) {
        if self.rightmenuView.isHidden {
            self.rightmenuView.isHidden = false
        } else {
            self.rightmenuView.isHidden = true
        }
    }
    
    @IBAction func inviteButtonAction(_ sender: Any) {
        self.rightmenuView.isHidden = true
       
        sendemailview.frame.size.width = UIScreen.main.bounds.width * 0.8
        sendemailview.frame.size.height = 135
        sendemailview.center = CGPoint(x: self.view.frame.size.width / 2, y: self.view.frame.size.height / 2)
        sendemailview.layer.cornerRadius = 5
        sendemailview.emailTextField.text = ""
        sendemailview.inviteButton.addTarget(self, action: #selector(MapViewController.invitebuttonaction(sender:)), for: .touchUpInside)
        sendemailview.cancelButton.addTarget(self, action: #selector(MapViewController.invitecancelbuttonaction(sender:)), for: .touchUpInside)
        self.view.addSubview(sendemailview)
    }
    
    @objc func invitebuttonaction(sender: UIButton) {
        self.sendemailview.removeFromSuperview()
        let mailComposeViewController = configureMailComposer()
        if MFMailComposeViewController.canSendMail(){
            self.present(mailComposeViewController, animated: true, completion: nil)
        }else{
            self.createAlert(title: "Warning!", message: "Can't send email.")
        }
    }
    
    func configureMailComposer() -> MFMailComposeViewController{
        let mailComposeVC = MFMailComposeViewController()
        mailComposeVC.mailComposeDelegate = self
        mailComposeVC.setToRecipients([self.sendemailview.emailTextField.text!])
        mailComposeVC.setSubject("Invite")
        mailComposeVC.setMessageBody("Check out My Blockwatch, I use it to monitor roadblocks and plan my itinerary for the day. Get it at. Then the link", isHTML: false)
        return mailComposeVC
    }
    
    //MARK: - MFMail compose method
    func mailComposeController(_ controller: MFMailComposeViewController, didFinishWith result: MFMailComposeResult, error: Error?) {
        controller.dismiss(animated: true, completion: nil)
    }
    
    @objc func invitecancelbuttonaction(sender: UIButton) {
        self.sendemailview.removeFromSuperview()
    }
    
    @IBAction func todayrouteButtonClick(_ sender: Any) {
        self.rightmenuView.isHidden = true
        self.dateLabel.text = "Routes for today"
        self.addPolylines(select_route_type: "today")
    }
    
    @IBAction func allrouteButtonClick(_ sender: Any) {
        self.rightmenuView.isHidden = true
        self.dateLabel.text = "Frequently used routes"
        self.addPolylines(select_route_type: "daily")
    }
    
    @IBAction func drawButtonClick(_ sender: Any) {
        if drawBtn.backgroundColor == UIColor.white {
            self.coordinates.removeAll()
            self.googleMapView.addSubview(canvasView)
            drawBtn.backgroundColor = UIColor.red
            drawBtn.setTitleColor(UIColor.white, for: .normal)
        } else {
            self.canvasView.removeFromSuperview()
            drawBtn.backgroundColor = UIColor.white
            drawBtn.setTitleColor(UIColor.black, for: .normal)
        }
    }
    
    func createPolygonFromTheDrawablePoints(){
        
        let numberOfPoints = self.coordinates.count
        //do not draw in mapview a single point
        if numberOfPoints > 2 { addPolyGonInMapView(drawableLoc: coordinates) }//neglects a single touch
//        coordinates = []
        self.canvasView.image = nil
        self.canvasView.removeFromSuperview()
        
        drawBtn.backgroundColor = UIColor.white
        drawBtn.setTitleColor(UIColor.black, for: .normal)
    }
    
    func  addPolyGonInMapView( drawableLoc:[CLLocationCoordinate2D]){
        
        isDrawingModeEnabled = true
        let path = GMSMutablePath()
        for loc in drawableLoc {
            path.add(loc)
        }

        let newpolygon = GMSPolyline(path: path)
        newpolygon.strokeWidth = 3
        newpolygon.strokeColor = UIColor.black
        newpolygon.map = self.googleMapView
        userDrawablePolygons.append(newpolygon)
        self.new_polyline = newpolygon
        self.setting_marker_coordinate = drawableLoc.last
    }
    
    func addPolygonDeleteAnnotation(endCoordinate location:CLLocationCoordinate2D, polygon:GMSPolyline, route_title: String, route_type: String, route_event: String, create_time: Int){
        
        let marker = DeleteMarker(location: location,polygon: polygon, route_title: route_title, route_type: route_type, route_event: route_event, create_time: create_time)
        let deletePolygonView = UIView(frame: CGRect(x: 0, y: 0, width: 30, height: 30))
        deletePolygonView.layer.cornerRadius = 15
        deletePolygonView.backgroundColor = UIColor.white
        let imageView = UIImageView(frame: CGRect(x: 0, y: 0, width: 16, height: 16))
        imageView.center = deletePolygonView.center
        imageView.image = UIImage(named: "setting-mark")
        deletePolygonView.addSubview(imageView)
        marker.iconView = deletePolygonView
        marker.map = googleMapView
        polygonDeleteMarkers.append(marker)
        
        self.new_marker = marker
    }
    
    func mapView(_ mapView: GMSMapView, didTap marker: GMSMarker) -> Bool {
        
        //do not accept touch of current location marker
        if let setting_marker = marker as? DeleteMarker{
            self.selected_marker = setting_marker
            //// display route setting view
            self.route_type = setting_marker.route_type!
            if self.route_type == "today" {
                let route_create_time = setting_marker.create_time
                let current_date = Date()
                let dateVar = Date.init(timeIntervalSince1970: TimeInterval(route_create_time!)/1000)
                let dateFormatter = DateFormatter()
                dateFormatter.dateFormat = "yyyy"
                let db_year = dateFormatter.string(from: dateVar)
                let current_year = dateFormatter.string(from: current_date)
                dateFormatter.dateFormat = "MM"
                let db_month = dateFormatter.string(from: dateVar)
                let current_month = dateFormatter.string(from: current_date)
                dateFormatter.dateFormat = "dd"
                let db_day = dateFormatter.string(from: dateVar)
                let current_day = dateFormatter.string(from: current_date)
                
                if db_year == current_year && db_month == current_month && db_day == current_day {
                    self.settingTodayButton.backgroundColor = UIColor.black
                    self.settingTodayButton.setTitleColor(UIColor.white, for: .normal)
                    settingDailyButton.backgroundColor = UIColor.white
                    settingDailyButton.setTitleColor(UIColor.black, for: .normal)
                } else {
                    self.settingTodayButton.backgroundColor = UIColor.white
                    self.settingTodayButton.setTitleColor(UIColor.black, for: .normal)
                    settingDailyButton.backgroundColor = UIColor.white
                    settingDailyButton.setTitleColor(UIColor.black, for: .normal)
                }
            } else {
                self.settingTodayButton.backgroundColor = UIColor.white
                self.settingTodayButton.setTitleColor(UIColor.black, for: .normal)
                settingDailyButton.backgroundColor = UIColor.black
                settingDailyButton.setTitleColor(UIColor.white, for: .normal)
            }
            self.routeTitleTextView.text = setting_marker.route_title
            self.routeTitleTextView.isEnabled = false
            self.settingEventTextView.text = setting_marker.route_event
            self.settingAddButton.setTitle("Update", for: .normal)
            self.settingcancelButton.isHidden = false
            self.rotuesettingView.isHidden = false
            
            self.drawn_type = "existing"
            self.new_marker = marker
            return true
        }
        return false
    }
    
    @IBAction func settingTodayButtonAction(_ sender: Any) {
        self.settingTodayButton.backgroundColor = UIColor.black
        self.settingTodayButton.setTitleColor(UIColor.white, for: .normal)
        
        settingDailyButton.backgroundColor = UIColor.white
        settingDailyButton.setTitleColor(UIColor.black, for: .normal)
        self.route_type = "today"
    }
    
    @IBAction func settingDailyButtonAction(_ sender: Any) {
        settingDailyButton.backgroundColor = UIColor.black
        settingDailyButton.setTitleColor(UIColor.white, for: .normal)
        
        self.settingTodayButton.backgroundColor = UIColor.white
        self.settingTodayButton.setTitleColor(UIColor.black, for: .normal)
        self.route_type = "daily"
    }
    
    @IBAction func addrouteButtonAction(_ sender: Any) {
        
        let route_title = self.routeTitleTextView.text
        let route_event = self.settingEventTextView.text

        if(route_title == "") {
            self.createAlert(title: "Warning!", message: "Please input Route Title.")
            return
        }
        
        self.startActivityIndicator()
        
        var geoloc_string_array = [String]()
        var geoloc_string: String?
        for loc in self.coordinates {
            geoloc_string = "\(loc.latitude) \(loc.longitude)"
            geoloc_string_array.append(geoloc_string!)
        }
        let currentDateMillisecond = Int(Date().timeIntervalSince1970 * 1000)
        
        let ref = Database.database().reference()
        if self.settingAddButton.titleLabel!.text == "Add" {
            let post_data = [
                "route_title": route_title!,
                "route_event": route_event!,
                "route_type": self.route_type,
                "coordinate": geoloc_string_array,
                "create_time": currentDateMillisecond
            ] as [String: Any]
            ref.child("routes").child(Auth.auth().currentUser!.uid).child(String(currentDateMillisecond)).updateChildValues(post_data)
        } else {
            let post_data = [
                "route_title": route_title!,
                "route_event": route_event!,
                "route_type": self.route_type,
                "create_time": currentDateMillisecond
                ] as [String: Any]
            
            ref.child("routes").child(Auth.auth().currentUser!.uid).observeSingleEvent(of: .value, with: {(snapshot) in
                snapshot.children.forEach({(child) in
                    if let child = child as? DataSnapshot, let value = child.value {
                        let route_create_time = (value as! [String: AnyObject])["create_time"]
                        if route_create_time as? Int == self.selected_marker?.create_time {
                            child.ref.updateChildValues(post_data)
                        }
                    }
                })
            })
        }
        if self.settingcancelButton.isHidden == true {
            addPolygonDeleteAnnotation(endCoordinate: self.setting_marker_coordinate!, polygon: self.new_polyline!, route_title: route_title!, route_type: self.route_type, route_event: route_event!, create_time: currentDateMillisecond)
        }
        self.rotuesettingView.isHidden = true
        self.coordinates = []
        
        self.stopActivityIndicator()
    }

    @IBAction func removerouteButtonAction(_ sender: Any) {
        self.coordinates = []
        if self.drawn_type == "new" {
            userDrawablePolygons.remove(at: userDrawablePolygons.count - 1)
            self.new_polyline?.map = nil
        } else {
            if let setting_marker = self.new_marker as? DeleteMarker {
                if let index = userDrawablePolygons.firstIndex(of: setting_marker.drawPolygon) {
                    userDrawablePolygons.remove(at: index)
                }
                if let  indexToRemove =  polygonDeleteMarkers.firstIndex(of: setting_marker) {
                    polygonDeleteMarkers.remove(at: indexToRemove)
                }
                
                setting_marker.drawPolygon.map = nil
                setting_marker.map = nil
            }
        }
        
        self.rotuesettingView.isHidden = true
    }
    
    @IBAction func settingviewCancelButtonAction(_ sender: Any) {
        self.rotuesettingView.isHidden = true
    }
    
    
    
    func createAlert(title: String, message: String) {
        let alert = UIAlertController(title: title, message:message, preferredStyle: UIAlertController.Style.alert)
        alert.addAction(UIAlertAction(title: "OK", style: UIAlertAction.Style.default, handler: {(action) in alert.dismiss(animated: true, completion: nil)
            
        }))
        self.present(alert, animated: true, completion: nil)
    }
    
    func startActivityIndicator() {
        activityIndicator.center = self.view.center;
        activityIndicator.hidesWhenStopped = true;
        activityIndicator.style = UIActivityIndicatorView.Style.whiteLarge;
        activityIndicator.color = UIColor.black
        view.addSubview(activityIndicator);
        activityIndicator.startAnimating();
        overlayView = UIView(frame:view.frame);
        view.addSubview(overlayView);
        UIApplication.shared.beginIgnoringInteractionEvents();
    }
    
    func stopActivityIndicator() {
        self.activityIndicator.stopAnimating();
        self.overlayView.removeFromSuperview();
        if UIApplication.shared.isIgnoringInteractionEvents {
            UIApplication.shared.endIgnoringInteractionEvents();
        }
    }
    
}


extension MapViewController:NotifyTouchEvents{
    
    func touchBegan(touch:UITouch){
        
        let location = touch.location(in: self.googleMapView)
        let coordinate = self.googleMapView.projection.coordinate(for: location)
        self.coordinates.append(coordinate)
        
    }
    
    func touchMoved(touch:UITouch){
        
        let location = touch.location(in: self.googleMapView)
        let coordinate = self.googleMapView.projection.coordinate(for: location)
        self.coordinates.append(coordinate)
        
    }
    
    func touchEnded(touch:UITouch){
        
        let location = touch.location(in: self.googleMapView)
        let coordinate = self.googleMapView.projection.coordinate(for: location)
        self.coordinates.append(coordinate)
        createPolygonFromTheDrawablePoints()
        
        //// display route setting view
        self.route_type = "today"
        self.settingTodayButton.backgroundColor = UIColor.black
        self.settingTodayButton.setTitleColor(UIColor.white, for: .normal)
        settingDailyButton.backgroundColor = UIColor.white
        settingDailyButton.setTitleColor(UIColor.black, for: .normal)
        self.routeTitleTextView.text = ""
        self.routeTitleTextView.isEnabled = true
        self.settingEventTextView.text = ""
        self.settingAddButton.setTitle("Add", for: .normal)
        self.settingcancelButton.isHidden = true
        self.rotuesettingView.isHidden = false
        
        self.drawn_type = "new"
    }
}

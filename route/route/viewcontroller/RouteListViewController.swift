//
//  RouteListViewController.swift
//  route
//
//  Created by flower on 07/09/2019.
//  Copyright © 2019 waterflower. All rights reserved.
//

import UIKit
import Firebase

class RouteListViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {

    @IBOutlet weak var routetypeLabel: UILabel!
    @IBOutlet weak var routelistTableView: UITableView!
    @IBOutlet weak var rightmenuView: UIView!
    
    var route_array = [[String: AnyObject]]()
    var selected_route_type = "today"
    
    ///////   for activity indicator  //////////
    var activityIndicator: UIActivityIndicatorView = UIActivityIndicatorView();
    var overlayView:UIView = UIView();
    
    override func viewDidLoad() {
        super.viewDidLoad()

        self.routetypeLabel.text = "Routes for today"
        self.getRouteList(route_type: "today")
        
        self.rightmenuView.layer.borderWidth = 1
        self.rightmenuView.layer.borderColor = UIColor.black.cgColor
        
    }
    
    func getRouteList(route_type: String) {
        self.startActivityIndicator()
        self.route_array.removeAll()
        let ref = Database.database().reference()
        ref.child("routes").child(Auth.auth().currentUser!.uid).observeSingleEvent(of: .value, with: {(snapshot) in
//            snapshot.children.forEach({(child) in
            for child in snapshot.children {
                if let child = child as? DataSnapshot, let value = child.value {
                    let db_route_type = (value as! [String: AnyObject])["route_type"] as? String
//                    if db_route_type == route_type {
                        let create_time = (value as! [String: AnyObject])["create_time"] as? Int
                    let current_date = Date()
                    let dateVar = Date.init(timeIntervalSince1970: TimeInterval(create_time!)/1000)
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
                    if route_type == "today" {
//                            if db_route_type != route_type {
//                                continue
//                            }
                        if db_year != current_year || db_month != current_month || db_day != current_day {
                            continue
                        }
                    } else if route_type == "daily" {
                        if (db_route_type == "today") && (db_year != current_year || db_month != current_month || db_day != current_day) {
                            continue
                        }
                    }
                    self.route_array.append(child.value as! [String: AnyObject])
//                    }
                }
            }
//            })
            self.routelistTableView.reloadData()
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
    
    @IBAction func todayrouteButtonClick(_ sender: Any) {
        self.rightmenuView.isHidden = true
        self.routetypeLabel.text = "Routes for today"
        self.getRouteList(route_type: "today")
    }
    
    @IBAction func allrouteButtonClick(_ sender: Any) {
        self.rightmenuView.isHidden = true
        self.routetypeLabel.text = "Frequently used routes"
        self.getRouteList(route_type: "daily")
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.route_array.count
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 100
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "routelisttableviewcell") as? RouteListTableViewCell
        cell!.selectionStyle = UITableViewCell.SelectionStyle.none
        
        cell?.routetitleLabel.text = self.route_array[indexPath.row]["route_title"] as? String
        cell?.routeeventLabel.text = self.route_array[indexPath.row]["route_event"] as? String

        let millitime = self.route_array[indexPath.row]["create_time"] as? Int
        let dateVar = Date.init(timeIntervalSince1970: TimeInterval(millitime!)/1000)
        let current_date = Date()
        
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
        
//        if self.route_array[indexPath.row]["route_type"] as? String == "today" {
//            cell?.routetypeLabel.text = "Today"
//        } else {
//            cell?.routetypeLabel.text = "Daily"
//        }
        if db_year == current_year && db_month == current_month && db_day == current_day {
            cell?.routetypeLabel.text = "Today"
        } else {
            cell?.routetypeLabel.text = "Daily"
        }
       
//        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "dd-MM-yyyy hh:mm"
        cell?.routecreatetimeLabel.text = dateFormatter.string(from: dateVar)
        
        return cell!
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        Global.selected_route_create_time = self.route_array[indexPath.row]["create_time"] as! Int
        Global.selected_route_type = self.route_array[indexPath.row]["route_title"] as! String
        Global.selected_route_title = self.route_array[indexPath.row]["route_title"] as! String
        self.tabBarController?.selectedIndex = 0
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

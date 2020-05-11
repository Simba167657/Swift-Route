//
//  DeleteMarker.swift
//  googlemap
//
//  Created by flower on 06/09/2019.
//  Copyright © 2019 waterflower. All rights reserved.
//

import UIKit
import GoogleMaps

class DeleteMarker: GMSMarker {
    
    var drawPolygon:GMSPolyline
    var markers:[GMSMarker]?
    var route_title: String?
    var route_type: String?
    var route_event: String?
    var create_time: Int?
    
    init(location:CLLocationCoordinate2D, polygon:GMSPolyline, route_title: String, route_type: String, route_event: String, create_time: Int) {
        
        
        self.drawPolygon = polygon
        self.route_title = route_title
        self.route_type = route_type
        self.route_event = route_event
        self.create_time = create_time
        super.init()
        super.position = location
        
    }
    
}


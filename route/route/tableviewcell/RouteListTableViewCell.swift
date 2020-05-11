//
//  RouteListTableViewCell.swift
//  route
//
//  Created by flower on 07/09/2019.
//  Copyright © 2019 waterflower. All rights reserved.
//

import UIKit

class RouteListTableViewCell: UITableViewCell {

    
    @IBOutlet weak var routetitleLabel: UILabel!
    @IBOutlet weak var routecreatetimeLabel: UILabel!
    @IBOutlet weak var routeeventLabel: UILabel!
    @IBOutlet weak var routetypeLabel: UILabel!
    
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }

}

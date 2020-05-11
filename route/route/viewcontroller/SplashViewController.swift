//
//  SplashViewController.swift
//  route
//
//  Created by flower on 05/09/2019.
//  Copyright © 2019 waterflower. All rights reserved.
//

import UIKit
import Firebase

class SplashViewController: UIViewController {

    ///////   for activity indicator  //////////
    var activityIndicator: UIActivityIndicatorView = UIActivityIndicatorView();
    var overlayView:UIView = UIView();
    
    override func viewDidLoad() {
        super.viewDidLoad()

        DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) {
            if UserDefaults.standard.bool(forKey: "signin") {
                let email = UserDefaults.standard.string(forKey: "email")
                let password = UserDefaults.standard.string(forKey: "password")
                
                self.startActivityIndicator()
                Auth.auth().signIn(withEmail: email!, password: password!, completion: ({(user, error) in
                    self.stopActivityIndicator()
                    if error != nil {
                        if AuthErrorCode(rawValue: error!._code) == .userDisabled {
                            self.createAlert(title: "Warning!", message: "Your account have been disabled.")
                        } else if AuthErrorCode(rawValue: error!._code) == .networkError {
                            self.createAlert(title: "Warning!", message: "Network Error.")
                        } else if AuthErrorCode(rawValue: error!._code) == .wrongPassword {
                            self.createAlert(title: "Warning!", message: "Password is incorrect.")
                        } else if AuthErrorCode(rawValue: error!._code) == .userNotFound {
                            self.createAlert(title: "Warning!", message: "Email is incorrect.")
                        } else {
                            self.createAlert(title: "Warning!", message: "There is error in server.")
                        }
                        
                    } else {
                        
                        let mainStoryboard: UIStoryboard = UIStoryboard(name: "Main", bundle: nil)
                        let controller = mainStoryboard.instantiateViewController(withIdentifier: "TabBarController") as! UITabBarController
                        
                        
                        var item = controller.tabBar.items![0]
                        item.image = self.makeThumbnailFromText(text: "Home")
                        item.title = nil;
                        
                        item = controller.tabBar.items![1]
                        item.image = self.makeThumbnailFromText(text: "Notification")
                        item.title = nil
                        
                        item = controller.tabBar.items![2]
                        item.image = self.makeThumbnailFromText(text: "Profile")
                        item.title = nil
                        
                        item = controller.tabBar.items![3]
                        item.image = self.makeThumbnailFromText(text: "Routes")
                        item.title = nil
                        
                        self.tabBarItem.title = nil
                        
                        self.navigationController?.pushViewController(controller, animated: true)
                    }
                    
                }))
            } else {
                let mainStoryboard: UIStoryboard = UIStoryboard(name: "Main", bundle: nil)
                let equipmentVC = mainStoryboard.instantiateViewController(withIdentifier: "SignInViewController") as! SignInViewController
                self.navigationController?.pushViewController(equipmentVC, animated: true)
            }
            
            
            
        }
    }
    

    func createAlert(title: String, message: String) {
        let alert = UIAlertController(title: title, message:message, preferredStyle: UIAlertController.Style.alert)
        alert.addAction(UIAlertAction(title: "OK", style: UIAlertAction.Style.default, handler: {(action) in alert.dismiss(animated: true, completion: nil)
            
        }))
        self.present(alert, animated: true, completion: nil)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(true)
        self.navigationController?.setNavigationBarHidden(true, animated: true)
    }
    
//    override func viewWillDisappear(_ animated: Bool) {
//        super.viewWillDisappear(true)
//        self.navigationController?.setNavigationBarHidden(false, animated: false)
//    }
    
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
    
    func makeThumbnailFromText(text: String) -> UIImage {
        // some variables that control the size of the image we create, what font to use, etc.
        
        struct LineOfText {
            var string: String
            var size: CGSize
        }
        
        let imageSize = CGSize(width: 100, height: 80)
        let fontSize: CGFloat = 13.0
        let fontName = "HelveticaNeue-Bold"
        let font = UIFont(name: fontName, size: fontSize)!
        let lineSpacing = fontSize * 1.2
        
        // set up the context and the font
        
        UIGraphicsBeginImageContextWithOptions(imageSize, false, 0)
        let attributes = [NSAttributedString.Key.font: font]
        
        // some variables we use for figuring out the words in the string and how to arrange them on lines of text
        
        let words = text.components(separatedBy: " ")
        var lines = [LineOfText]()
        var lineThusFar: LineOfText?
        
        // let's figure out the lines by examining the size of the rendered text and seeing whether it fits or not and
        // figure out where we should break our lines (as well as using that to figure out how to center the text)
        
        for word in words {
            let currentLine = lineThusFar?.string == nil ? word : "\(lineThusFar!.string) \(word)"
            let size = currentLine.size(withAttributes: attributes)
            if size.width > imageSize.width && lineThusFar != nil {
                lines.append(lineThusFar!)
                lineThusFar = LineOfText(string: word, size: word.size(withAttributes: attributes))
            } else {
                lineThusFar = LineOfText(string: currentLine, size: size)
            }
        }
        if lineThusFar != nil { lines.append(lineThusFar!) }
        
        // now write the lines of text we figured out above
        
        let totalSize = CGFloat(lines.count - 1) * lineSpacing + fontSize
        let topMargin = (imageSize.height - totalSize) / 2.0
        
        for (index, line) in lines.enumerated() {
            let x = (imageSize.width - line.size.width) / 2.0
            let y = topMargin + CGFloat(index) * lineSpacing
            line.string.draw(at: CGPoint(x: x, y: y), withAttributes: attributes)
        }
        
        let image = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        
        return image!
    }

}

//
//  SignInViewController.swift
//  route
//
//  Created by flower on 05/09/2019.
//  Copyright © 2019 waterflower. All rights reserved.
//

import UIKit
import Firebase

class SignInViewController: UIViewController {

    @IBOutlet weak var scrollview: UIScrollView!
    @IBOutlet weak var emailTextField: UITextField!
    @IBOutlet weak var passwordTextField: UITextField!
    
    ///////   for activity indicator  //////////
    var activityIndicator: UIActivityIndicatorView = UIActivityIndicatorView();
    var overlayView:UIView = UIView();
    
    override func viewDidLoad() {
        super.viewDidLoad()

        ////  dismiss keyboard   ///////
        let tap: UITapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(self.dismissKeyboard))
        view.addGestureRecognizer(tap)
        tap.cancelsTouchesInView = false
        
        
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillShow), name:UIResponder.keyboardWillShowNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillHide), name:UIResponder.keyboardWillHideNotification, object: nil)
    }
    
    @objc func dismissKeyboard() {
        view.endEditing(true)
    }
    
    @objc func keyboardWillShow(notification:NSNotification){
        
        var userInfo = notification.userInfo!
        var keyboardFrame:CGRect = (userInfo[UIResponder.keyboardFrameBeginUserInfoKey] as! NSValue).cgRectValue
        keyboardFrame = self.view.convert(keyboardFrame, from: nil)
        
        var contentInset:UIEdgeInsets = self.scrollview.contentInset
        contentInset.bottom = keyboardFrame.size.height
        scrollview.contentInset = contentInset
    }
    
    @objc func keyboardWillHide(notification:NSNotification){
        
        let contentInset:UIEdgeInsets = UIEdgeInsets.zero
        scrollview.contentInset = contentInset
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        return true
    }
    
    func isValidEmail(email_str: String) -> Bool {
        let regExp = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,64}"
        let emailTest = NSPredicate(format: "SELF MATCHES %@", regExp)
        return emailTest.evaluate(with: email_str)
    }
    
    
    @IBAction func signinButtonAction(_ sender: Any) {
        
        let email = self.emailTextField.text!
        let password = self.passwordTextField.text!
        
        if !isValidEmail(email_str: email) {
            self.createAlert(title: "Warning!", message: "Please input valid email address.")
            return
        }
        if password.count < 6 {
            self.createAlert(title: "Warning!", message: "Password have to be at lease 6 characters.")
            return
        }
        
        self.startActivityIndicator()
        Auth.auth().signIn(withEmail: email, password: password, completion: ({(user, error) in
            self.stopActivityIndicator()
            if error != nil {
                if AuthErrorCode(rawValue: error!._code) == .userDisabled {
                    self.createAlert(title: "Warning!", message: "Your account have been disabled.")
                } else if AuthErrorCode(rawValue: error!._code) == .networkError {
                    self.createAlert(title: "Warning!", message: "Network Error.")
                } else if AuthErrorCode(rawValue: error!._code) == .wrongPassword {
                    self.createAlert(title: "Warning!", message: "Password is incorrect. Please try again.")
                } else if AuthErrorCode(rawValue: error!._code) == .userNotFound {
                    self.createAlert(title: "Warning!", message: "Email is incorrect. Please try again.")
                } else {
                    self.createAlert(title: "Warning!", message: "There is error in server. Please try again.")
                }
                return
            }
            
            UserDefaults.standard.set(email, forKey: "email")
            UserDefaults.standard.set(password, forKey: "password")
            UserDefaults.standard.set(true, forKey: "signin")
            
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
        }))
        
    }
    
    @IBAction func signupButtonAction(_ sender: Any) {
        let mainStoryboard: UIStoryboard = UIStoryboard(name: "Main", bundle: nil)
        let signinVC = mainStoryboard.instantiateViewController(withIdentifier: "SignUpViewController") as! SignUpViewController
        self.navigationController?.pushViewController(signinVC, animated: true)
    }
    
    @IBAction func forgotpasswordButtonAction(_ sender: Any) {
        let mainStoryboard: UIStoryboard = UIStoryboard(name: "Main", bundle: nil)
        let signinVC = mainStoryboard.instantiateViewController(withIdentifier: "ForgotPasswordViewController") as! ForgotPasswordViewController
        self.navigationController?.pushViewController(signinVC, animated: true)
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

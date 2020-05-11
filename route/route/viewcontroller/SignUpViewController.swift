//
//  SignUpViewController.swift
//  route
//
//  Created by flower on 05/09/2019.
//  Copyright © 2019 waterflower. All rights reserved.
//

import UIKit
import Firebase

class SignUpViewController: UIViewController {

    @IBOutlet weak var emailTextField: UITextField!
    @IBOutlet weak var passwordTextField: UITextField!
    @IBOutlet weak var confirmTextField: UITextField!
    @IBOutlet weak var scrollview: UIScrollView!
    
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
    
    @IBAction func registerButtonAction(_ sender: Any) {
        let email = self.emailTextField.text!
        let password = self.passwordTextField.text!
        let confirm = self.confirmTextField.text!
        
        if !isValidEmail(email_str: email) {
            createAlert(title: "Warning!", message: "Please input valid email address.")
            return
        }
        if password.count < 6 {
            createAlert(title: "Warning!", message: "Password have to be at lease 6 characters.")
            return
        }
        if password != confirm {
            createAlert(title: "Warning!", message: "Password doesn't match.")
            return
        }
        
        self.startActivityIndicator()
        
        Auth.auth().createUser(withEmail: email, password: password, completion: {(user, error) in
            self.stopActivityIndicator()
            if(error != nil) {
                self.stopActivityIndicator()
                if AuthErrorCode(rawValue: error!._code) == .emailAlreadyInUse {
                    self.createAlert(title: "Warning!", message: "Your email address is already exist!")
                } else if AuthErrorCode(rawValue: error!._code) == .networkError {
                    self.createAlert(title: "Warning!", message: "Network Error.")
                } else {
                    self.createAlert(title: "Warning!", message: "There is issue in server. Please try again!")
                }
                return
            }
//            let ref = Database.database().reference()
//            let post_data = [
//                "name": "",
//                "email":email,
//                "avatar_url": "",
//                ] as [String : Any]
            
            
//            ref.child("users").child(Auth.auth().currentUser!.uid).setValue(post_data, withCompletionBlock: {err, ref in
//                self.stopActivityIndicator()
//                if err != nil {
//                    self.createAlert(title: "Warning!", message: "Network error.")
//                } else {
//                    let mainStoryboard: UIStoryboard = UIStoryboard(name: "Main", bundle: nil)
//                    let signinVC = mainStoryboard.instantiateViewController(withIdentifier: "SignInViewController") as! SignInViewController
//                    self.navigationController?.pushViewController(signinVC, animated: true)
//                }
//            })
            
            let mainStoryboard: UIStoryboard = UIStoryboard(name: "Main", bundle: nil)
            let signinVC = mainStoryboard.instantiateViewController(withIdentifier: "SignInViewController") as! SignInViewController
            self.navigationController?.pushViewController(signinVC, animated: true)
            
        })
        
    }
    
    @IBAction func signinButtonAction(_ sender: Any) {
        let mainStoryboard: UIStoryboard = UIStoryboard(name: "Main", bundle: nil)
        let signinVC = mainStoryboard.instantiateViewController(withIdentifier: "SignInViewController") as! SignInViewController
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

}

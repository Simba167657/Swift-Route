//
//  ProfileViewController.swift
//  route
//
//  Created by flower on 06/09/2019.
//  Copyright © 2019 waterflower. All rights reserved.
//

import UIKit
import Firebase
import Kingfisher

class ProfileViewController: UIViewController, UINavigationControllerDelegate, UIImagePickerControllerDelegate {

    @IBOutlet weak var scrollview: UIScrollView!
    @IBOutlet weak var avatarImageView: UIImageView!
    @IBOutlet weak var nameTextField: UITextField!
    @IBOutlet weak var emailLabel: UILabel!
    @IBOutlet weak var passwordTextField: UITextField!
    @IBOutlet weak var confirmPasswordTextField: UITextField!
    
    ///////   for activity indicator  //////////
    var activityIndicator: UIActivityIndicatorView = UIActivityIndicatorView();
    var overlayView:UIView = UIView();
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        startActivityIndicator()
        let ref = Database.database().reference()
        ref.child("users").queryOrderedByKey().observeSingleEvent(of: .value, with: {snapshot in
            for child in snapshot.children {
                let snap = child as! DataSnapshot
                let dic = snap.value as! [String: Any]
                if dic["email"] as! String == UserDefaults.standard.string(forKey: "email")! {
                    self.nameTextField.text = dic["name"] as? String
                    self.passwordTextField.text = UserDefaults.standard.string(forKey: "password")
                    self.confirmPasswordTextField.text = UserDefaults.standard.string(forKey: "password")
                    self.emailLabel.text = dic["email"] as? String
                    if dic["avatar_url"] as? String != "" {
                        let image_url = URL(string: dic["avatar_url"] as! String)
                        self.avatarImageView.kf.setImage(with: image_url)
                    }
                    
                }
            }
            self.stopActivityIndicator()
        })
        
        

        let pictureTap = UITapGestureRecognizer(target: self, action: #selector(ProfileViewController.imageTapped))
        self.avatarImageView.addGestureRecognizer(pictureTap)
        self.avatarImageView.isUserInteractionEnabled = true
        
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
    
    @objc func imageTapped() {
        let imagePickerController = UIImagePickerController()
        imagePickerController.delegate = self
        
        let actionSheet = UIAlertController(title: "Photo Source", message: "Choose a source", preferredStyle: .actionSheet)
        actionSheet.addAction(UIAlertAction(title: "Camera", style: .default, handler: {(action: UIAlertAction) in
            imagePickerController.sourceType = .camera
            self.present(imagePickerController, animated: true, completion: nil)
        }))
        actionSheet.addAction(UIAlertAction(title: "Photo Gallery", style: .default, handler: {(action: UIAlertAction) in
            imagePickerController.sourceType = .photoLibrary
            self.present(imagePickerController, animated: true, completion: nil)
        }))
        actionSheet.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
        actionSheet.popoverPresentationController?.sourceView = self.view;
        actionSheet.popoverPresentationController?.barButtonItem = self.navigationItem.leftBarButtonItem
        actionSheet.popoverPresentationController?.sourceRect = CGRect(x: self.view.bounds.midX, y: self.view.bounds.maxY, width: 0, height: 0)
        self.present(actionSheet, animated: true, completion: nil)
    }
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        let image = info[UIImagePickerController.InfoKey.originalImage] as! UIImage
//        self.avatarImageView.image = image
        picker.dismiss(animated: true, completion: nil)
        
        startActivityIndicator();
        self.uploadImage(image) { url in
            if url != nil {
//                let email = UserDefaults.standard.string(forKey: "email")
                
                let email = UserDefaults.standard.string(forKey: "email")!
                let post_data = [
                    "name": self.nameTextField.text!,
                    "email":email,
                    "avatar_url": url!.absoluteString,
                    ] as [String : Any]
//                let ref = Database.database().reference()
//                ref.child("users").child(Auth.auth().currentUser!.uid).setValue(post_data)
                self.upload_data(post_data: post_data)
                self.avatarImageView.image = image

            } else {
                self.createAlert(title: "Warning!", message: "Network error.")
            }
            self.stopActivityIndicator()
        }
    }
    
    func upload_data(post_data: [String: Any]) {
        self.startActivityIndicator()
        let ref = Database.database().reference()
        ref.child("users").child(Auth.auth().currentUser!.uid).updateChildValues(post_data)
        self.stopActivityIndicator()
    }
    
    @IBAction func saveButtonClick(_ sender: Any) {
        let name = self.nameTextField.text!
        let password = self.passwordTextField.text!
        let confirm = self.confirmPasswordTextField.text!
        
        if password != UserDefaults.standard.string(forKey: "password") {
            self.passwordAlert(title: "Notice!", message: "Do you really want to change your password?", password: password, confirm: confirm)
        } else {
            let email = UserDefaults.standard.string(forKey: "email")!
            let post_data = [
                "name": name,
                "email":email
                ] as [String : Any]
            self.upload_data(post_data: post_data)
        }
        

    }
    
    func createAlert(title: String, message: String) {
        let alert = UIAlertController(title: title, message:message, preferredStyle: UIAlertController.Style.alert)
        alert.addAction(UIAlertAction(title: "OK", style: UIAlertAction.Style.default, handler: {(action) in alert.dismiss(animated: true, completion: nil)
            
        }))
        self.present(alert, animated: true, completion: nil)
    }
    
    func passwordAlert(title: String, message: String, password: String, confirm: String) {
        let alert = UIAlertController(title: title, message:message, preferredStyle: UIAlertController.Style.alert)
        alert.addAction(UIAlertAction(title: "OK", style: UIAlertAction.Style.default, handler: {(action) in alert.dismiss(animated: true, completion: nil)
            if password.count < 6 {
                self.createAlert(title: "Warning!", message: "Password have to be at lease 6 characters.")
                return
            }
            if password != confirm {
                self.createAlert(title: "Warning!", message: "Password doesn't match.")
                return
            }
            self.startActivityIndicator()
            Auth.auth().currentUser?.updatePassword(to: password, completion: {(error) in
                self.stopActivityIndicator()
                if error != nil {
                    self.createAlert(title: "Warning!", message: "Error occured. Please try again.")
                } else {
                    self.createAlert(title: "Success!", message: "Password have been changed successfully.");
                    UserDefaults.standard.set(password, forKey: "password")
                }
            })
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

extension ProfileViewController {
    func uploadImage(_ image: UIImage, completion: @escaping (_ url: URL?) -> ()) {
        let currentDate = Date()
        let currentDateMillisecond = Int(currentDate.timeIntervalSince1970 * 1000)
        let upload_image = image.resized(withPercentage: 0.1)
        let filename = "\(currentDateMillisecond).png"
        let storageRef = Storage.storage().reference().child(filename)
        let imgData = upload_image!.pngData()
        let metaData = StorageMetadata()
        metaData.contentType = "image/png"
        storageRef.putData(imgData!, metadata: metaData) { (metadata, error) in
            if error == nil {
                print("success_______________")
                storageRef.downloadURL(completion: {(url, error) in
                    completion(url!)
                })
            } else {
                print("error to upload image_____________")
                completion(nil)
            }
        }
    }
    
    func saveImage(profileURL: URL, purchase_status: Bool, completion: @escaping (_ success: Bool?) -> ()) {
        let ref = Database.database().reference()
        let post_data = [
//            "name": self.post_name,
//            "link": self.link,
//            "earning": self.earning_double,
//            "category": self.selected_category_index,
//            "created_at": Firebase.ServerValue.timestamp(),
//            "visit_count": 0,
//            "image_url": profileURL.absoluteString,
//            "purchase_state": purchase_status
            "name": "dddd"
            ] as [String : Any]
        
        
        ref.childByAutoId().setValue(post_data, withCompletionBlock: {err, ref in
            if err != nil {
                completion(false)
            } else {
                completion(true)
            }
        })
    }
}


extension UIImage {
    func resized(withPercentage percentage: CGFloat) -> UIImage? {
        let canvas = CGSize(width: size.width * percentage, height: size.height * percentage)
        return UIGraphicsImageRenderer(size: canvas, format: imageRendererFormat).image {
            _ in draw(in: CGRect(origin: .zero, size: canvas))
        }
    }
    func resized(toWidth width: CGFloat) -> UIImage? {
        let canvas = CGSize(width: width, height: CGFloat(ceil(width/size.width * size.height)))
        return UIGraphicsImageRenderer(size: canvas, format: imageRendererFormat).image {
            _ in draw(in: CGRect(origin: .zero, size: canvas))
        }
    }
}

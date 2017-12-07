//
//  ViewController.swift
//  ForcedPerspectives App
//
//  Created by StemDot on 12/5/17.
//  Copyright © 2017 Stemdot Business Solution. All rights reserved.
//

import UIKit

class ViewController: UIViewController {

    @IBOutlet var loadedImage: UIImageView!
    @IBOutlet var imagetitle: UILabel!
    @IBOutlet var grabNewImage: UIButton!
    @IBOutlet var errorLabel: UILabel!
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        self.errorLabel.isHidden = true
    }

    @IBAction func grabNewImageFromFlicker(_ sender: Any) {
        setUIEnabled(false)
        self.loadedImage.isHidden = false
        self.errorLabel.isHidden = false
        getImageFromFlicker()
    }
    // MARK: Configure UI
    
    private func setUIEnabled(_ enabled: Bool) {
        imagetitle.isEnabled = enabled
        grabNewImage.isEnabled = enabled
        
        if enabled {
            grabNewImage.alpha = 1.0
        } else {
            grabNewImage.alpha = 0.5
        }
    }
    
    private func getImageFromFlicker(){
        //now firts create a url parameters to pass with the url
        let urlParameters = [Constants.FlickrParameterKeys.Method:Constants.FlickrParameterValues.GalleryPhotosMethod,
                             Constants.FlickrParameterKeys.APIKey: Constants.FlickrParameterValues.APIKey,
                             Constants.FlickrParameterKeys.GalleryID:Constants.FlickrParameterValues.GalleryIDForced,
                             Constants.FlickrParameterKeys.Format:Constants.FlickrParameterValues.ResponseFormat,
                             Constants.FlickrParameterKeys.Extras:Constants.FlickrParameterValues.MediumURL,
                             Constants.FlickrParameterKeys.NoJSONCallback:Constants.FlickrParameterValues.DisableJSONCallback]
        
        print("url parameters constants \(urlParameters)")
        //now add this parameter to base url
        let urlString = Constants.Flickr.APIBaseURL + escapedParameters(urlParameters as [String:AnyObject])
        print("Url with parameters \(urlString)")
        
        let url = URL(string: urlString)
        
        //add the request type
        let urlRequest = URLRequest(url: url!)
        
        let task = URLSession.shared.dataTask(with: urlRequest){(data,response,error) in
            
            //this function is used to display the error message if anything goes wrong
            func displayError(error:String){
                print(error)
                print("Url at the time of error \(String(describing: url))")
                performUIUpdatesOnMain {
                      self.errorLabel.isHidden = false
                      self.errorLabel.text = error+"😱"
                    self.loadedImage.isHidden = true
                    self.setUIEnabled(true)
                }
            }
            
            //check for the
            /* GUARD: Was there an error? */
            guard (error == nil) else {
                displayError(error: "There was an error with your request: )")
                return
            }
            
            /* GUARD: Did we get a successful 2XX response? */
            guard let statusCode = (response as? HTTPURLResponse)?.statusCode, statusCode >= 200 && statusCode <= 299 else {
                displayError(error: "Your request returned a status code other than 2xx!")
                return
            }
            
            /* GUARD: Was there any data returned? */
            guard let data = data else {
                displayError(error: "No data was returned by the request!")
                return
            }
            
                //now convert the json data to swf array or dictionery
            
                    let parsedResult:[String:AnyObject]!
                    
                    do{
                        parsedResult = try JSONSerialization.jsonObject(with: data, options: .allowFragments) as! [String : AnyObject]
                    }catch{
                        displayError(error: "Could not parse the data as JSON: '\(data)'")
                        return
                    }
            
            /* GUARD: Did Flickr return an error (stat != ok)? */
            guard let stat = parsedResult[Constants.FlickrResponseKeys.Status] as? String, stat == Constants.FlickrResponseValues.OKStatus else {
                displayError(error: "Flickr API returned an error. See error code and message in \(parsedResult)")
                return
            }
            
            /* GUARD: Are the "photos" and "photo" keys in our result? */
            guard let photosDictionary = parsedResult[Constants.FlickrResponseKeys.Photos] as? [String:AnyObject], let _ = photosDictionary[Constants.FlickrResponseKeys.Photo] as? [[String:AnyObject]] else {
                displayError(error: "Cannot find keys '\(Constants.FlickrResponseKeys.Photos)' and '\(Constants.FlickrResponseKeys.Photo)' in \(parsedResult)")
                return
            }
            
                    //now go the step by step and get the photo and title
                    if let photosDictionary = parsedResult[Constants.FlickrResponseKeys.Photos] as? [String:AnyObject]{
                        //print(photosDictionary)
                        //now get the photo array
                        if let photoArray = photosDictionary[Constants.FlickrResponseKeys.Photo] as? [[String:AnyObject]]{
                             //print(photo[0])
                            //genarte the random number to display the random image
                            let randomPhotoImdex = Int(arc4random_uniform(UInt32(photoArray.count)))
                            //get the random dictionary from photos array
                            let photoDicitionary = photoArray[randomPhotoImdex] as [String:AnyObject]
                            
                            //noew get the title and image from dicitionary
                            if let imageUrlString = photoDicitionary[Constants.FlickrResponseKeys.MediumURL] as? String,
                                let imageTitle = photoDicitionary[Constants.FlickrResponseKeys.Title] as? String{
                                
                                //now convert string url into image url
                                let imageUrl  = URL(string:imageUrlString)
                                
                                //now get the image data from url
                                if let imagedata = try? Data(contentsOf:imageUrl!){
                                    performUIUpdatesOnMain {
                                        self.loadedImage.image = UIImage(data:imagedata)
                                        self.imagetitle.text = imageTitle
                                        self.setUIEnabled(true) 
                                    }
                                }
                            }
                            
                        }
                       
                    }
                
                
            
        }
        task.resume()
    }
    
    private func escapedParameters(_ parameters: [String:AnyObject]) -> String {
        
        if parameters.isEmpty {
            return ""
        } else {
            var keyValuePairs = [String]()
            
            for (key, value) in parameters {
                
                // make sure that it is a string value
                let stringValue = "\(value)"
                
                // escape it
                let escapedValue = stringValue.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed)
                
                // append it
                keyValuePairs.append(key + "=" + "\(escapedValue!)")
                
            }
            
            return "?\(keyValuePairs.joined(separator: "&"))"
        }
    }
}


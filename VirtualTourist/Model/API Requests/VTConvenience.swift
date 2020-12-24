//
//  VTConvenience.swift
//  VirtualTourist
//
//  Created by Shawn Moran on 12/18/20.
//

import UIKit
import Foundation

extension VTClient {
    
    func getFlickrPhotos(_ lat: Double!, _ long: Double!, _ completionHandlerForFlickrPhotos: @escaping (_ result: [VTFlickrPhotosData.VTFlickrPhoto]?, _ error: NSError?) -> Void) {
        /* Specify parameters, method (if has {key}), and HTTP body (if POST) */
        let parameters = [
            VTClient.Constants.FlickrParameterKeys.Lat: String(lat),
            VTClient.Constants.FlickrParameterKeys.Long: String(long),
            VTClient.Constants.FlickrParameterKeys.Extras: VTClient.Constants.FlickrParameterValues.MediumURL,
            VTClient.Constants.FlickrParameterKeys.Method: VTClient.Constants.FlickrParameterValues.SearchPhotosMethod,
            VTClient.Constants.FlickrParameterKeys.APIKey: VTClient.Constants.FlickrParameterValues.APIKey,
            VTClient.Constants.FlickrParameterKeys.Format: VTClient.Constants.FlickrParameterValues.ResponseFormat,
            VTClient.Constants.FlickrParameterKeys.NoJsonCallback: "1"
        ]
        
        /* Make the request */
        let _ = taskForGETMethod(parameters: parameters as [String:AnyObject]) { (results, error) in
            /* Send the desired values(s) to completion handler */
            if let error = error {
                completionHandlerForFlickrPhotos(nil, error)
            } else {
                if let results = results?[VTClient.Constants.FlickrResponseKeys.Photos] as? [String:AnyObject] {
                    if let photo = results[VTClient.Constants.FlickrResponseKeys.Photo] as? [[String:AnyObject]] {
                        let photos = VTFlickrPhotosData.VTFlickrPhoto.flickrPhotosFromResults((photo))
                        completionHandlerForFlickrPhotos(photos, nil)
                    }
                } else {
                    completionHandlerForFlickrPhotos(nil, NSError(domain: "getFlickrPhotos parsing", code: 0, userInfo: [NSLocalizedDescriptionKey: "Could not parse getFlickrPhotos"]))
                }
            }
        }
    }
    
}

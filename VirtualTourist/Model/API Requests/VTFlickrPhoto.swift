//
//  VTFlickrPhoto.swift
//  VirtualTourist
//
//  Created by Shawn Moran on 12/18/20.
//

extension VTFlickrPhotosData {

    // MARK: VTFlickrPhoto
    struct VTFlickrPhoto {
        
        // MARK: Properties
        
        let imageURL: String?
        
        // MARK: Initializers
        
        // construct a OTMStudentLocation from a dictionary
        init(dictionary: [String:AnyObject]) {
            imageURL = dictionary[VTClient.Constants.FlickrResponseKeys.MediumURL] as? String
        }
        
        static func flickrPhotosFromResults(_ results: [[String:AnyObject]]) -> [VTFlickrPhoto] {
            
            var flickrPhotos = [VTFlickrPhoto]()
            
            // iterate through array of dictionaries, each Movie is a dictionary
            for result in results {
                flickrPhotos.append(VTFlickrPhoto(dictionary: result))
            }
            
            return flickrPhotos
        }
    }
}

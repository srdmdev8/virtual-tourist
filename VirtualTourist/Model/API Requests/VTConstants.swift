//
//  VTConstants.swift
//  VirtualTourist
//
//  Created by Shawn Moran on 12/18/20.
//

extension VTClient {
    
    // MARK: - Constants

    struct Constants {
        
        // MARK: Flickr
        struct Flickr {
            static let ApiScheme = "https"
            static let ApiHost = "www.flickr.com"
            static let ApiPath = "/services/rest/"
        }

        // MARK: Flickr Parameter Keys
        struct FlickrParameterKeys {
            static let Method = "method"
            static let APIKey = "api_key"
            static let Lat = "lat"
            static let Long = "lon"
            static let Extras = "extras"
            static let Format = "format"
            static let NoJsonCallback = "nojsoncallback"
        }
        
        // MARK: Flickr Parameter Values
        struct FlickrParameterValues {
            static let APIKey = "0a68c587502e27afb43dff5a0bbc8fe2"
            static let ResponseFormat = "json"
            static let SearchPhotosMethod = "flickr.photos.search"
            static let MediumURL = "url_m"
        }
        
        // MARK: Flickr Response Keys
        struct FlickrResponseKeys {
            static let Photos = "photos"
            static let Photo = "photo"
            static let MediumURL = "url_m"
        }
    }
}

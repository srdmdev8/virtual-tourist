//
//  PhotoAlbumViewController.swift
//  VirtualTourist
//
//  Created by Shawn Moran on 12/17/20.
//

import UIKit
import MapKit
import CoreData

class PhotoAlbumViewController: UIViewController, MKMapViewDelegate, NSFetchedResultsControllerDelegate, UICollectionViewDataSource, UICollectionViewDelegate {
    
    @IBOutlet weak var mapView: MKMapView!
    @IBOutlet weak var photoCollectionView: UICollectionView!
    @IBOutlet weak var newCollectionButton: UIBarButtonItem!
    @IBOutlet weak var flowLayout: UICollectionViewFlowLayout!
    @IBOutlet weak var activityIndicator: UIActivityIndicatorView!
    
    var pin: Pin!
    
    var coordinate: CLLocationCoordinate2D!
    
    var dataController: DataController!
    
    var fetchedResultsController: NSFetchedResultsController<Photo>!
    
    var operationQueue: [BlockOperation]!
    
    var photosCount: Int?
    
    fileprivate func setUpFetchedResultsController() {
        let fetchRequest:NSFetchRequest<Photo> = Photo.fetchRequest()
        let predicate = NSPredicate(format: "pin.latitude == %lf AND pin.longitude == %lf", pin.latitude, pin.longitude)
        fetchRequest.predicate = predicate
        fetchRequest.sortDescriptors = []
        
        fetchedResultsController = NSFetchedResultsController(fetchRequest: fetchRequest, managedObjectContext: dataController.viewContext, sectionNameKeyPath: nil, cacheName: "\(pin.id) photos")
        fetchedResultsController.delegate = self
        do {
            try fetchedResultsController.performFetch()
        } catch {
            fatalError("The fetch could not be performed: \(error.localizedDescription)")
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Disable New Collection button until finsihed gathering photos
        setNavbarItemEnabled(false)
        activityIndicator.startAnimating()
        
        // Set map view delegate to the view controller
        mapView.delegate = self
        self.photoCollectionView.delegate = self;
        self.photoCollectionView.dataSource = self;
        
        setUpCollectionViewLayout()
        
        // Fetch data via fetchedResultsController
        setUpFetchedResultsController()
        
        addPinToMap()
        
        getSavedPhotos()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.photoCollectionView!.reloadData()
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        fetchedResultsController = nil
    }
    
    func addPinToMap() {
        let annotation = MKPointAnnotation()
        annotation.coordinate.latitude = pin.latitude
        annotation.coordinate.longitude = pin.longitude
        mapView.addAnnotation(annotation)
        mapView.selectAnnotation(annotation, animated: true)
        centerMapOnLocation(annotation, mapView)
    }
    
    // Generates the annotation view
    internal func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
        guard annotation is MKPointAnnotation else { return nil }

        let identifier = "Annotation"
        var annotationView = mapView.dequeueReusableAnnotationView(withIdentifier: identifier)

        if annotationView == nil {
            annotationView = MKPinAnnotationView(annotation: annotation, reuseIdentifier: identifier)
            annotationView!.canShowCallout = true
        } else {
            annotationView!.annotation = annotation
        }

        return annotationView
    }
    
    func centerMapOnLocation(_ annotation: MKAnnotation, _ mapView: MKMapView) {
        let regionRadius: CLLocationDistance = 1000
        let coordinateRegion = MKCoordinateRegion(center: annotation.coordinate, latitudinalMeters: regionRadius * 2.0, longitudinalMeters: regionRadius * 2.0)
        mapView.setRegion(coordinateRegion, animated: false)
    }
    
    func getSavedPhotos() {
        // Get photos from fetchedResultsController
        guard let photos = fetchedResultsController?.fetchedObjects, !photos.isEmpty else {
            makeFlickrImageRequest()
            return
        }
        
        // Enable New Collection button
        setNavbarItemEnabled(true)
        activityIndicator.stopAnimating()
    }
    
    // New Collection button clicked, get new collection of photos
    @IBAction func getNewPhotoAlbum(_ sender: Any) {
        // Disable New Collection button
        setNavbarItemEnabled(false)
        activityIndicator.startAnimating()
        
        // Delete pin photos
        deletePinPhotos()
        
        // Call Flickr API
        makeFlickrImageRequest()
    }
    
    // Call Flickr photo search API
    func makeFlickrImageRequest() {
        VTClient.sharedInstance().getFlickrPhotos(pin.latitude, pin.longitude) { (flickrPhotos, error) in
            DispatchQueue.main.async {
                // Check for error
                if error != nil {
                    self.displayAlert()
                    // Enable New Collection button
                    self.setNavbarItemEnabled(true)
                    self.activityIndicator.stopAnimating()
                    return
                }
                // If no error, get results
                if let photos = flickrPhotos {
                    // Loop through photos to save each one
                    for pic in photos {
                        let photo = Photo(context: self.dataController.viewContext)
                        photo.image = pic.imageURL!.data(using: .utf8)
                        photo.pin = self.pin
                        try? self.dataController.viewContext.save()
                    }
                } else {
                    let label = UILabel()
                    label.frame = self.photoCollectionView.frame
                    label.frame.origin.x = 0
                    label.frame.origin.y = 0
                    label.textAlignment = .center
                    label.text = "No Images Available"
                    self.photoCollectionView.backgroundView = label
                }
                // Enable New Collection button
                self.setNavbarItemEnabled(true)
                self.activityIndicator.stopAnimating()
            }
        }
    }
    
    // Display alert if Flickr API fails and give user option to retry
    private func displayAlert() {
        let alert = UIAlertController(title: "Photo Album Error", message: "We were unable to gather photos for this location. Please try again in a few moments.", preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "RETRY", style: .default, handler: { (action) -> Void in
            self.makeFlickrImageRequest()
            alert.dismiss(animated: true, completion: nil)
        }))
        alert.addAction(UIAlertAction(title: "CANCEL", style: .cancel, handler: nil))
        self.present(alert, animated: true)
    }
    
    private func setNavbarItemEnabled(_ enabled: Bool) {
        newCollectionButton.isEnabled = enabled
    }
    
    func deletePinPhotos() {
        if let photos = fetchedResultsController.fetchedObjects {
            for photo in photos {
                dataController.viewContext.delete(photo)
            }
            photoCollectionView!.reloadData()
        }
    }
    
    func setUpCollectionViewLayout() {
        let space:CGFloat = 2.0
        let dimension = (view.bounds.size.width - (2 * space)) / 3.0
        flowLayout.minimumInteritemSpacing = space
        flowLayout.minimumLineSpacing = space
        flowLayout.itemSize = CGSize(width: dimension, height: dimension)
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return fetchedResultsController.fetchedObjects?.count ?? 0
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = photoCollectionView.dequeueReusableCell(withReuseIdentifier: "PhotoAlbumViewControllerCell", for: indexPath) as! PhotoAlbumViewControllerCell
        
        cell.photoImageView.image = UIImage(named: "imagePlaceholder")
                
        // Check if the photo is ready
        guard let photo = fetchedResultsController.fetchedObjects?[indexPath.row] else {
            // We'll only be inside this block if the photo isn't there
            return cell
        }
        
        let imageURL = URL(string: String(data: photo.image!, encoding: .utf8)!)
        if let imageData = try? Data(contentsOf: imageURL!) {
            cell.photoImageView.image = UIImage(data: imageData)
        }
        
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let photoToDelete = fetchedResultsController.object(at: indexPath)
        dataController.viewContext.delete(photoToDelete)
        try? dataController.viewContext.save()
    }
}

extension PhotoAlbumViewController {
    
    func controller(_ controller: NSFetchedResultsController<NSFetchRequestResult>, didChange anObject: Any, at indexPath: IndexPath?, for type: NSFetchedResultsChangeType, newIndexPath: IndexPath?) {
        switch type {
        case .insert:
            guard let indexPath = newIndexPath else {
                return
            }
            
            let aPhoto = fetchedResultsController.object(at: indexPath)
            let cell = photoCollectionView.dequeueReusableCell(withReuseIdentifier: "PhotoAlbumViewControllerCell", for: indexPath) as! PhotoAlbumViewControllerCell

            // Configure cell
            let imageURL = URL(string: String(data: aPhoto.image!, encoding: .utf8)!)
            if let imageData = try? Data(contentsOf: imageURL!) {
                cell.photoImageView.image = UIImage(data: imageData)
                self.photoCollectionView.insertItems(at: [indexPath])
            }
            photoCollectionView!.reloadData()
        case .delete:
            guard let photos = fetchedResultsController?.fetchedObjects, !photos.isEmpty else {
                return
            }
            photoCollectionView!.deleteItems(at: [indexPath!])
        default:
            break
        }
    }
}

//
//  PhotoAlbumViewController.swift
//  VirtualTourist
//
//  Created by Shawn Moran on 12/17/20.
//

import UIKit
import MapKit
import CoreData

class PhotoAlbumViewController: UIViewController, MKMapViewDelegate, NSFetchedResultsControllerDelegate {
    
    @IBOutlet weak var mapView: MKMapView!
    
    @IBOutlet weak var photoCollectionView: UICollectionView!
    
    var pin: Pin!
    
    var dataController: DataController!
    
    var fetchedResultsController: NSFetchedResultsController<Photo>!
    
    var coordinate: CLLocationCoordinate2D!
    
    fileprivate func setUpFetchedResultsController() {
        let fetchRequest:NSFetchRequest<Photo> = Photo.fetchRequest()
        let predicate = NSPredicate(format: "pin == %@", pin)
        fetchRequest.predicate = predicate
        fetchRequest.sortDescriptors = []
        
        fetchedResultsController = NSFetchedResultsController(fetchRequest: fetchRequest, managedObjectContext: dataController.viewContext, sectionNameKeyPath: nil, cacheName: "\(pin) photos")
        fetchedResultsController.delegate = self
        do {
            try fetchedResultsController.performFetch()
        } catch {
            fatalError("The fetch could not be performed: \(error.localizedDescription)")
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        // Set map view delegate to the view controller
        mapView.delegate = self
        
        // Fetch data via fetchedResultsController
        setUpFetchedResultsController()
        
        addPinToMap()
    }
    
    func addPinToMap() {
        let annotation = MKPointAnnotation()
        annotation.coordinate = coordinate!
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
    
    @IBAction func getNewPhotoAlbum(_ sender: Any) {
        
    }
    
    //    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
//
//        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "PhotoAlbumViewControllerCell", for: indexPath) as! PhotoAlbumViewControllerCell
//        var imageView: UIImageView
//
//        // Set the image
//        cell.memeImageView?.image = meme.memedImage
//
//        return cell
//    }
}

extension PhotoAlbumViewController {
    
    func controller(_ controller: NSFetchedResultsController<NSFetchRequestResult>, didChange anObject: Any, at indexPath: IndexPath?, for type: NSFetchedResultsChangeType, newIndexPath: IndexPath?) {
        switch type {
        case .insert:
            self.photoCollectionView.insertItems(at: [newIndexPath!])
//            let cell = photoCollectionView.dequeueReusableCell(withReuseIdentifier: "PhotoAlbumViewControllerCell", for: newIndexPath!) as! PhotoAlbumViewControllerCell
//            if let photo = anObject as? Photo {
                
//            }
        default:
            break
        }
    }
}

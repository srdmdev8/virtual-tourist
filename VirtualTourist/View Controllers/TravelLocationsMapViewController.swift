//
//  ViewController.swift
//  VirtualTourist
//
//  Created by Shawn Moran on 12/16/20.
//

import UIKit
import MapKit
import CoreData

class TravelLocationsMapViewController: UIViewController, MKMapViewDelegate, NSFetchedResultsControllerDelegate {

    @IBOutlet weak var mapView: MKMapView!
    
    private var mapChangedFromUserInteraction = false
    
    var dataController:DataController!
    
    var fetchedResultsController:NSFetchedResultsController<Pin>!
    
    fileprivate func setUpFetchedResultsController() {
        let fetchRequest:NSFetchRequest<Pin> = Pin.fetchRequest()
        fetchRequest.sortDescriptors = []
        
        fetchedResultsController = NSFetchedResultsController(fetchRequest: fetchRequest, managedObjectContext: dataController.viewContext, sectionNameKeyPath: nil, cacheName: "pins")
        fetchedResultsController.delegate = self
        do {
            try fetchedResultsController.performFetch()
        } catch {
            fatalError("The fetch could not be performed: \(error.localizedDescription)")
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Get long press recognition
        let longPress = UILongPressGestureRecognizer(target: self, action: #selector(mapLongPress(longPress:)))
        
        mapView.addGestureRecognizer(longPress)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        // Set map view delegate to the view controller
        mapView.delegate = self
        
        // Check if there is a saved map location to start
        getSavedMapLocation()
        
        // Fetch data via fetchedResultsController
        setUpFetchedResultsController()
        
        // Get saved pins
        getSavedMapPins()
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        fetchedResultsController = nil
    }

    @objc func mapLongPress(longPress: UIGestureRecognizer) {
        if (longPress.state == UIGestureRecognizer.State.began) {
            let touchPoint = longPress.location(in: mapView)
            let coordinate = mapView.convert(touchPoint, toCoordinateFrom: mapView)

            let annotation = MKPointAnnotation()
            annotation.coordinate = coordinate
            mapView.addAnnotation(annotation)
            addPin(coordinate)
        }
    }
    
    func addPin(_ coordinate: CLLocationCoordinate2D) {
        let pin = Pin(context: dataController.viewContext)
        pin.latitude = coordinate.latitude
        pin.longitude = coordinate.longitude
        try? dataController.viewContext.save()
    }
    
    // Generates the annotation view
    internal func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
        guard annotation is MKPointAnnotation else { return nil }

        let identifier = "Annotation"
        var annotationView = mapView.dequeueReusableAnnotationView(withIdentifier: identifier)

        if annotationView == nil {
            annotationView = MKPinAnnotationView(annotation: annotation, reuseIdentifier: identifier)
            annotationView!.canShowCallout = true
//            annotationView!.appear = true
        } else {
            annotationView!.annotation = annotation
        }

        return annotationView
    }
    
    private func mapViewRegionDidChangeFromUserInteraction() -> Bool {
        let view = self.mapView.subviews[0]
        //  Look through gesture recognizers to determine whether this region change is from user interaction
        if let gestureRecognizers = view.gestureRecognizers {
            for recognizer in gestureRecognizers {
                if( recognizer.state == UIGestureRecognizer.State.began || recognizer.state == UIGestureRecognizer.State.ended ) {
                    return true
                }
            }
        }
        return false
    }

    func mapView(_ mapView: MKMapView, regionDidChangeAnimated animated: Bool) {
        mapChangedFromUserInteraction = mapViewRegionDidChangeFromUserInteraction()
        if (mapChangedFromUserInteraction) {
            UserDefaults.standard.setValue(mapView.centerCoordinate.latitude, forKey: "latitude")
            UserDefaults.standard.setValue(mapView.centerCoordinate.longitude, forKey: "longitude")
            UserDefaults.standard.setValue(mapView.region.span.latitudeDelta, forKey: "latitudeDelta")
            UserDefaults.standard.setValue(mapView.region.span.longitudeDelta, forKey: "longitudeDelta")
        }
    }
    
    func getSavedMapPins() {
        // Get map pins from fetchedResultsController
        guard let mapPins = fetchedResultsController?.fetchedObjects else {
            return
        }
        // Loop through pins and add them to map
        for pin in mapPins {
            let storedAnnotation = MKPointAnnotation()
            storedAnnotation.coordinate = CLLocationCoordinate2D(latitude: pin.latitude, longitude: pin.longitude)
            
            self.mapView.addAnnotation(storedAnnotation)
        }
    }
    
    func getSavedMapLocation() {
        // Get lat/long values from UserDefaults
        let latitude = UserDefaults.standard.value(forKey: "latitude") as? Double
        let longitude = UserDefaults.standard.value(forKey: "longitude") as? Double
        let latitudeDelta = UserDefaults.standard.value(forKey: "latitudeDelta") as? Double
        let longitudeDelta = UserDefaults.standard.value(forKey: "longitudeDelta") as? Double
        
        if latitude != nil && longitude != nil {
            mapView.centerCoordinate.latitude = latitude!
            mapView.centerCoordinate.longitude = longitude!
        }
        
        if latitudeDelta != nil && longitudeDelta != nil {
            mapView.region.span.latitudeDelta = latitudeDelta!
            mapView.region.span.longitudeDelta = longitudeDelta!
        }
    }
    
    func mapView(_ mapView: MKMapView, didSelect view: MKAnnotationView) {
        if let annotation = view.annotation as? MKPointAnnotation {
            performSegue(withIdentifier: "ViewPinPhotos", sender: annotation)
        }
    }
    
    // -------------------------------------------------------------------------
    // MARK: - Navigation

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "ViewPinPhotos" {
            if let vc = segue.destination as? PhotoAlbumViewController {
                let coordinate = (sender as! MKPointAnnotation).coordinate
                let mapPins = fetchedResultsController.fetchedObjects!
                guard let pinIndex = mapPins.firstIndex(where: { (pin) -> Bool in
                    pin.latitude == coordinate.latitude && pin.longitude == coordinate.longitude
                }) else {
                    return
                }
                vc.coordinate = coordinate
                vc.pin = mapPins[pinIndex]
                vc.dataController = dataController
            }
        }
    }
}

extension TravelLocationsMapViewController {
    
    func controller(_ controller: NSFetchedResultsController<NSFetchRequestResult>, didChange anObject: Any, at indexPath: IndexPath?, for type: NSFetchedResultsChangeType, newIndexPath: IndexPath?) {
        switch type {
        case .insert:
            if let pin = anObject as? Pin {
                let annotation = MKPointAnnotation()
                annotation.coordinate.latitude = pin.latitude
                annotation.coordinate.longitude = pin.longitude
                mapView.addAnnotation(annotation)
            }
        default:
            break
        }
    }
}

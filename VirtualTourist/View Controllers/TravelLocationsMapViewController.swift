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
        let sortDescriptor = NSSortDescriptor(key: "creationDate", ascending: false)
        fetchRequest.sortDescriptors = [sortDescriptor]
        
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
        longPress.minimumPressDuration = 1.5
        
        mapView.addGestureRecognizer(longPress)
        
        guard let mapPins = fetchedResultsController?.fetchedObjects else {
            return
        }
        
        for pin in mapPins {
            let storedAnnotation = MKPointAnnotation()
            storedAnnotation.coordinate = CLLocationCoordinate2D(latitude: pin.latitude, longitude: pin.longitude)
            
            self.mapView.addAnnotation(storedAnnotation)
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        // Set map view delegate to the view controller
        mapView.delegate = self
        
        // Check if there is a saved map location to start
//        if let mapRegion = UserDefaults.standard.dictionary(forKey: "mapRegion") as [String: AnyObject]? {
//            if let savedRegion = MKCoordinateRegion(decode: mapRegion) {
//                mapView.region = savedRegion
//            }
//        }
        setUpFetchedResultsController()
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        fetchedResultsController = nil
    }

    @objc func mapLongPress(longPress: UIGestureRecognizer) {
        if (longPress.state == UIGestureRecognizer.State.began) {
            print("Long press detected")
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
        pin.creationDate = Date()
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
        } else {
            annotationView!.annotation = annotation
        }

        return annotationView
    }
    
    @objc func pinWasTapped(_ gesture: UITapGestureRecognizer) {
        let pinView = gesture.view as! MKPinAnnotationView
        performSegue(withIdentifier: "ViewPinPhotos", sender: pinView)
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
    
    func mapView(_ mapView: MKMapView, regionWillChangeAnimated animated: Bool) {
        mapChangedFromUserInteraction = mapViewRegionDidChangeFromUserInteraction()
        if (mapChangedFromUserInteraction) {
            // user changed map region
        }
    }

    func mapView(_ mapView: MKMapView, regionDidChangeAnimated animated: Bool) {
        print("regionDidChangeAnimated")
        print("mapChangedFromUserInteraction: \(mapChangedFromUserInteraction)")
        if (mapChangedFromUserInteraction) {
            print(mapView.region)
//            UserDefaults.standard.setValue(mapView.region.encode, forKey: "mapRegion")
        }
    }
    
    // -------------------------------------------------------------------------
    // MARK: - Navigation

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "ViewPinPhotos" {
            if let vc = segue.destination as? PhotoAlbumViewController {
                vc.coordinate = (sender as! MKPinAnnotationView).annotation!.coordinate
                vc.dataController = dataController
            }
        }
    }
}

//extension MKCoordinateRegion {
//
//    var encode: [String: AnyObject] {
//        return ["center":
//                   ["latitude": self.center.latitude,
//                   "longitude": self.center.longitude],
//                "span":
//                   ["latitudeDelta": self.span.latitudeDelta,
//                    "longitudeDelta": self.span.longitudeDelta]]
//    }
//
//    init?(decode: [String: AnyObject]) {
//
//        guard let center = decode["center"] as? [String: AnyObject],
//            let latitude = center["latitude"] as? Double,
//            let longitude = center["longitude"] as? Double,
//            let span = decode["span"] as? [String: AnyObject],
//            let latitudeDelta = span["latitudeDelta"] as? Double,
//            let longitudeDelta = span["longitudeDelta"] as? Double
//        else { return nil }
//
//
//        self.center = CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
//        self.span = MKCoordinateSpan(latitudeDelta: latitudeDelta, longitudeDelta: longitudeDelta)
//    }
//}

//
//  ViewController.swift
//  visizovPW7
//
//  Created by user on 27.01.2022.
//

import UIKit
import CoreLocation
import MapKit
import YandexMapsMobile

final class MapController: UIViewController, YMKMapCameraListener, YMKTrafficDelegate  {
    var trafficLayer : YMKTrafficLayer!
    
    var pos: YMKCameraPosition = YMKCameraPosition()
    var drivingSession: YMKDrivingSession?
    
    var coordinates: [CLLocationCoordinate2D] = []
    
    let ROUTE_START_POINT = YMKPoint(latitude: 59.959194, longitude: 30.407094)
        let ROUTE_END_POINT = YMKPoint(latitude: 55.733330, longitude: 37.587649)
        let CAMERA_TARGET = YMKPoint(latitude: 57.846262, longitude: 33.997372)
    
    var curZoom: Float = 0.0
    
    func onCameraPositionChanged(with map: YMKMap, cameraPosition: YMKCameraPosition, cameraUpdateReason: YMKCameraUpdateReason, finished: Bool) {
        pos = cameraPosition
        
    }
    
    func onTrafficChanged(with trafficLevel: YMKTrafficLevel?) {
        if trafficLevel == nil {
                    return
                }
                
    }
    
    func onTrafficLoading() {
    
    }
    
    func onTrafficExpired() {
    
    }
    
    
    

    override func viewDidLoad() {
        super.viewDidLoad()
    
        view.addSubview(mapView)
        
        curZoom = 7
        
        
        
        mapView.mapWindow.map.move(
                with: YMKCameraPosition.init(target: YMKPoint(latitude: 55.751574, longitude: 37.573856), zoom: curZoom, azimuth: 0, tilt: 0),
                animationType: YMKAnimation(type: YMKAnimationType.smooth, duration: 5),
                cameraCallback: nil)
      
       
        
        clearButton.addTarget(self, action: #selector(clearButtonWasPressed), for: .touchDown)
        
        goButton.addTarget(self, action: #selector(clearButtonWasPressed), for: .touchDown)
        
        zoomIn.addTarget(self, action: #selector(zoomInButtonWasPressed), for: .touchDown)
        
        zoomOut.addTarget(self, action: #selector(zoomOutButtonWasPressed), for: .touchDown)
        
        
        clearButton.isEnabled = false
        goButton.isEnabled = false
        
        view.addSubview(goButton)
        view.addSubview(clearButton)
        view.addSubview(zoomIn)
        view.addSubview(zoomOut)
        
        configureUI()
        
        SetupButtons()
        
        self.hideKeyboardWhenTappedAround()
        

        let textStack = UIStackView()
         textStack.axis = .vertical
         view.addSubview(textStack)
         textStack.spacing = 10
         textStack.pin(to: view, [.top: 50, .left: 10, .right: 10])
         [startLocation, endLocation].forEach { textField in
         textField.setHeight(to: 40)
         textField.delegate = self
         textStack.addArrangedSubview(textField)
         }
        
        trafficLayer = YMKMapKit.sharedInstance().createTrafficLayer(with: mapView.mapWindow)
               trafficLayer.addTrafficListener(withTrafficListener: self)
               mapView.mapWindow.map.addCameraListener(with: self)
               
               mapView.mapWindow.map.move(with: YMKCameraPosition(
                   target: YMKPoint(latitude: 59.945933, longitude: 30.320045),
                   zoom: curZoom,
                   azimuth: 0,
                   tilt: 0))
               
               onSwitchTraffic(self)
        
        mapView.mapWindow.map.move(
                    with: YMKCameraPosition(target: CAMERA_TARGET, zoom: curZoom, azimuth: 0, tilt: 0))
                
                let requestPoints : [YMKRequestPoint] = [
                    YMKRequestPoint(point: ROUTE_START_POINT, type: .waypoint, pointContext: nil),
                    YMKRequestPoint(point: ROUTE_END_POINT, type: .waypoint, pointContext: nil),
                    ]
                
                let responseHandler = {(routesResponse: [YMKDrivingRoute]?, error: Error?) -> Void in
                    if let routes = routesResponse {
                        self.onRoutesReceived(routes)
                    } else {
                        self.onRoutesError(error!)
                    }
                }
                
                let drivingRouter = YMKDirections.sharedInstance().createDrivingRouter()
                drivingSession = drivingRouter.requestRoutes(
                    with: requestPoints,
                    drivingOptions: YMKDrivingDrivingOptions(),
                    vehicleOptions: YMKDrivingVehicleOptions(),
                    routeHandler: responseHandler)
    }
    
    func onRoutesReceived(_ routes: [YMKDrivingRoute]) {
            let mapObjects = mapView.mapWindow.map.mapObjects
            for route in routes {
                mapObjects.addPolyline(with: route.geometry)
            }
        }
        
        func onRoutesError(_ error: Error) {
            let routingError = (error as NSError).userInfo[YRTUnderlyingErrorKey] as! YRTError
            var errorMessage = "Unknown error"
            if routingError.isKind(of: YRTNetworkError.self) {
                errorMessage = "Network error"
            } else if routingError.isKind(of: YRTRemoteError.self) {
                errorMessage = "Remote server error"
            }
            
            let alert = UIAlertController(title: "Error", message: errorMessage, preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
            
            present(alert, animated: true, completion: nil)
        }
    
    @IBAction func onSwitchTraffic(_ sender: Any) {
            
            trafficLayer.setTrafficVisibleWithOn(true)
    
        }

    
    
    
    

    func textFieldDidBeginEditing(_ textField: UITextField) {
        clearButton.isEnabled = true
        goButton.isEnabled = true
        
    }
    
    func textFieldDidEndEditing(_ textField: UITextField) {
        if (startLocation.text != "" || endLocation.text != "") {
            clearButton.isEnabled = true
            goButton.isEnabled = true
        } else {
            clearButton.isEnabled = false
            goButton.isEnabled = false
        }
    }

    let goButton: UIButton = {
        let goButton = UIButton(type: .system)
        goButton.setTitle("Go", for: .normal)
        goButton.setTitleColor(.red, for: .normal)
    
        goButton.translatesAutoresizingMaskIntoConstraints = false
        goButton.backgroundColor = .blue
        return goButton
    }()
    
    let zoomIn: UIButton = {
        let zoomIn = UIButton(type: .system)
        zoomIn.setTitle("+", for: .normal)
        zoomIn.setTitleColor(.black, for: .normal)

        zoomIn.translatesAutoresizingMaskIntoConstraints = false
        zoomIn.backgroundColor = .white
        return zoomIn
    }()
    
    let zoomOut: UIButton = {
        let zoomOut = UIButton(type: .system)
        zoomOut.setTitle("-", for: .normal)
        zoomOut.setTitleColor(.black, for: .normal)

        zoomOut.translatesAutoresizingMaskIntoConstraints = false
        zoomOut.backgroundColor = .white
        return zoomOut
    }()
    let clearButton: UIButton = {
        let clearButton = UIButton(type: .system)
        clearButton.setTitle("Clear", for: .normal)
        clearButton.translatesAutoresizingMaskIntoConstraints = false
        clearButton.backgroundColor = .gray
        clearButton.setTitleColor(.red, for: .disabled)
    
        return clearButton
    }()
    
    let startLocation: UITextField = {
     let control = UITextField()
     control.backgroundColor = UIColor.lightGray
     control.textColor = UIColor.black
     control.placeholder = "From"
     control.layer.cornerRadius = 2
     control.clipsToBounds = false
     control.font = UIFont.systemFont(ofSize: 15)
     control.borderStyle = UITextField.BorderStyle.roundedRect
     control.autocorrectionType = UITextAutocorrectionType.yes
     control.keyboardType = UIKeyboardType.default
     control.returnKeyType = UIReturnKeyType.done
     control.clearButtonMode =
    UITextField.ViewMode.whileEditing
     control.contentVerticalAlignment =
    UIControl.ContentVerticalAlignment.center

     return control
     }()
    
    let endLocation: UITextField = {
     let control = UITextField()
     control.backgroundColor = UIColor.lightGray
     control.textColor = UIColor.black
     control.placeholder = "End"
     control.layer.cornerRadius = 2
     control.clipsToBounds = false
     control.font = UIFont.systemFont(ofSize: 15)
     control.borderStyle = UITextField.BorderStyle.roundedRect
     control.autocorrectionType = UITextAutocorrectionType.yes
     control.keyboardType = UIKeyboardType.default
     control.returnKeyType = UIReturnKeyType.done
     control.clearButtonMode =
    UITextField.ViewMode.whileEditing
     control.contentVerticalAlignment =
    UIControl.ContentVerticalAlignment.center
     return control
     }()
    
    
    

    private let mapView: YMKMapView = {
        let mapView = YMKMapView()
        mapView.layer.masksToBounds = true
        mapView.layer.cornerRadius = 5
        mapView.clipsToBounds = false
        mapView.translatesAutoresizingMaskIntoConstraints = false
 

        
        return mapView
    } ()
    
    private func configureUI() {
        mapView.rightAnchor.constraint(equalTo: view.rightAnchor).isActive = true
        mapView.widthAnchor.constraint(equalTo: view.widthAnchor, multiplier: 1).isActive = true
        mapView.heightAnchor.constraint(equalTo: view.heightAnchor, multiplier: 1).isActive = true
        mapView.centerYAnchor.constraint(equalTo: view.centerYAnchor).isActive = true
    }
    
    override var preferredStatusBarStyle: UIStatusBarStyle {
     return .lightContent
     }
    
    private func SetupButtons() {
        goButton.leftAnchor.constraint(equalTo: view.leftAnchor).isActive = true
        goButton.widthAnchor.constraint(equalTo: view.widthAnchor, multiplier: 1/2).isActive = true
        goButton.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: -100).isActive = true
        
        clearButton.rightAnchor.constraint(equalTo: view.rightAnchor).isActive = true
        clearButton.widthAnchor.constraint(equalTo: view.widthAnchor, multiplier: 1/2).isActive = true
        clearButton.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: -100).isActive = true
        
        zoomIn.rightAnchor.constraint(equalTo: view.rightAnchor).isActive = true
        zoomIn.widthAnchor.constraint(equalToConstant: 50).isActive = true
        zoomIn.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: -300).isActive = true
        
        zoomOut.rightAnchor.constraint(equalTo: view.rightAnchor).isActive = true
        zoomOut.widthAnchor.constraint(equalToConstant: 50).isActive = true
        zoomOut.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: -250).isActive = true

        
    
    }
    
    @objc func clearButtonWasPressed() {
        startLocation.text = ""
        endLocation.text = ""
    }
    
    @objc func goButtonWasPressed() {
        guard
         let first = startLocation.text,
         let second = endLocation.text,
         first != second
         else {
         return
         }
        
    }
    
    @objc func zoomInButtonWasPressed() {
        curZoom += 1

        mapView.mapWindow.map.move(with: YMKCameraPosition(
            target: pos.target,
            zoom: curZoom,
            azimuth: 0,
            tilt: 0))
    }
    
    @objc func zoomOutButtonWasPressed() {
        curZoom -= 1
        mapView.mapWindow.map.move(with: YMKCameraPosition(
            target: pos.target,
            zoom: curZoom,
            azimuth: 0,
            tilt: 0))
    }
    
    private func getCoordinateFrom(address: String, completion:
    @escaping(_ coordinate: CLLocationCoordinate2D?, _ error: Error?)
    -> () ) {
     DispatchQueue.global(qos: .background).async {
     CLGeocoder().geocodeAddressString(address)
    { completion($0?.first?.location?.coordinate, $1) }
     }
     }
    
    
 
    
}


extension MapController: UITextFieldDelegate {
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        return true
    }
}


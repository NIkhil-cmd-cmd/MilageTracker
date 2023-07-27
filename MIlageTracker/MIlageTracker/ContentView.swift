//
//  ContentView.swift
//  MIlageTracker
//
//  Created by Nikhil Krishnaswamy on 6/29/23.
//

import SwiftUI
import MapKit
import CoreData


struct ContentView: View {
    @State private var trips: [Trip] = [
        Trip(from: "Foothill College", to: "De Anza College"),
        Trip(from: "Your starting point", to: "Your destination")
    ]
    
    var body: some View {
        NavigationView {
            List {
                ForEach(trips) { trip in
                    NavigationLink(destination: DetailView(trip: trip)) {
                        TripCell(trip: trip)
                    }
                }
                .onDelete(perform: delete)
                
                NavigationLink(destination: AddView(trips: $trips)) {
                    Text("Add New Trip")
                }
            }
            .navigationTitle("Trips")
        }
    }
    
    private func delete(at offsets: IndexSet) {
        // Prevent deletion of data
    }
}

struct TripCell: View {
    var trip: Trip
    
    var body: some View {
        VStack(alignment: .leading) {
            Text("From: \(trip.from)")
            Text("To: \(trip.to)")
            Text("Date & Time: \(trip.dateTime)")
        }
    }
}

struct DetailView: View {
    var trip: Trip
    
    @State private var totalMiles: Double = 0.0
    @State private var route: String = ""
    
    var body: some View {
        VStack {
            TripCell(trip: trip)
            Text("Total Miles: \(totalMiles)")
            
            MapView(from: trip.from, to: trip.to)
                .frame(height: 300)
                .cornerRadius(10)
                .onAppear {
                    calculateRoute()
                }
            
            Text("Route:")
                .font(.headline)
                .padding(.top)
            
            Text(route)
                .padding(.horizontal)
            
            Spacer()
        }
        .navigationTitle("Trip Details")
    }
    
    private func calculateRoute() {
        let geocoder = CLGeocoder()
        geocoder.geocodeAddressString(trip.from) { sourcePlacemarks, sourceError in
            geocoder.geocodeAddressString(trip.to) { destinationPlacemarks, destinationError in
                if let sourcePlacemark = sourcePlacemarks?.first,
                   let destinationPlacemark = destinationPlacemarks?.first {
                    let sourceItem = MKMapItem(placemark: MKPlacemark(placemark: sourcePlacemark))
                    let destinationItem = MKMapItem(placemark: MKPlacemark(placemark: destinationPlacemark))
                    
                    let request = MKDirections.Request()
                    request.source = sourceItem
                    request.destination = destinationItem
                    request.transportType = .automobile
                    
                    let directions = MKDirections(request: request)
                    directions.calculate { response, error in
                        guard let route = response?.routes.first else { return }
                        
                        self.totalMiles = route.distance / 1609.34 // Convert meters to miles
                        
                        let routeCoordinates = route.polyline.points()
                        self.route = ""
                        for i in 0 ..< route.polyline.pointCount {
                            let coordinate = routeCoordinates[i].coordinate
                            self.route += String(format: "(%.5f, %.5f)", coordinate.latitude, coordinate.longitude)
                            if i < route.polyline.pointCount - 1 {
                                self.route += "\n"
                            }
                        }
                    }
                }
            }
        }
    }
}

struct AddView: View {
    @Binding var trips: [Trip]
    @State private var from: String = ""
    @State private var to: String = ""
    @State private var dateTime: Date = Date()
    
    var body: some View {
        Form {
            Section(header: Text("Trip Details")) {
                TextField("From", text: $from)
                TextField("To", text: $to)
                DatePicker("Date & Time", selection: $dateTime, displayedComponents: [.date, .hourAndMinute])
            }
            
            Button(action: addTrip) {
                Text("Add Trip")
            }
        }
        .navigationTitle("Add Trip")
    }
    
    private func addTrip() {
        let newTrip = Trip(from: from, to: to, dateTime: dateTime)
        trips.append(newTrip)
    }
}

struct MapView: UIViewRepresentable {
    var from: String
    var to: String
    
    func makeUIView(context: Context) -> MKMapView {
        MKMapView()
    }
    
    func updateUIView(_ uiView: MKMapView, context: Context) {
        uiView.removeAnnotations(uiView.annotations)
        uiView.removeOverlays(uiView.overlays)
        
        let geocoder = CLGeocoder()
        geocoder.geocodeAddressString(from) { sourcePlacemarks, sourceError in
            geocoder.geocodeAddressString(to) { destinationPlacemarks, destinationError in
                if let sourcePlacemark = sourcePlacemarks?.first,
                   let destinationPlacemark = destinationPlacemarks?.first {
                    let sourceItem = MKMapItem(placemark: MKPlacemark(placemark: sourcePlacemark))
                    let destinationItem = MKMapItem(placemark: MKPlacemark(placemark: destinationPlacemark))
                    
                    let request = MKDirections.Request()
                    request.source = sourceItem
                    request.destination = destinationItem
                    request.transportType = .automobile
                    
                    let directions = MKDirections(request: request)
                    directions.calculate { response, error in
                        guard let route = response?.routes.first else { return }
                        
                        let routeCoordinates = route.polyline.points()
                        var coordinates = [CLLocationCoordinate2D](repeating: .init(), count: route.polyline.pointCount)
                        
                        for i in 0 ..< route.polyline.pointCount {
                            coordinates[i] = routeCoordinates[i].coordinate
                        }
                        
                        let polyline = MKPolyline(coordinates: coordinates, count: route.polyline.pointCount)
                        uiView.addOverlay(polyline)
                        
                        let region = MKCoordinateRegion(route.polyline.boundingMapRect)
                        uiView.setRegion(region, animated: true)
                    }
                }
            }
        }
    }

    func makeCoordinator() -> Coordinator {
        Coordinator()
    }
    
    class Coordinator: NSObject, MKMapViewDelegate {
        override init() {
            super.init()
        }
        
        func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer {
            if let polyline = overlay as? MKPolyline {
                let renderer = MKPolylineRenderer(polyline: polyline)
                renderer.strokeColor = .blue
                renderer.lineWidth = 5
                return renderer
            }
            
            return MKOverlayRenderer()
        }
    }
}

struct Trip: Identifiable {
    let id = UUID()
    let from: String
    let to: String
    let dateTime: Date
    var totalMiles: Double
    var route: String
    
    init(from: String, to: String, dateTime: Date = Date(), totalMiles: Double = 0.0, route: String = "") {
        self.from = from
        self.to = to
        self.dateTime = dateTime
        self.totalMiles = totalMiles
        self.route = route
    }
}


struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}

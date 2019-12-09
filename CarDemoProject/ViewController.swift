//
//  ViewController.swift
//  CarDemoProject
//
//  Created by Admin on 09.12.2019.
//  Copyright © 2019 sergei. All rights reserved.
//

import UIKit
import CoreData

class ViewController: UIViewController {

    private var selectedCar: Car?
    
    @IBOutlet weak var markLabel: UILabel!
    @IBOutlet weak var modelLabel: UILabel!
    @IBOutlet weak var imageView: UIImageView!
    @IBOutlet weak var lastStartedLabel: UILabel!
    @IBOutlet weak var numberOfTripsLabel: UILabel!
    @IBOutlet weak var ratingLabel: UILabel!
    @IBOutlet weak var carSegmentedControl: UISegmentedControl!
    
    @IBAction func segmentAction(_ sender: UISegmentedControl) {
        
        if let carName = sender.titleForSegment(at: sender.selectedSegmentIndex),
            let delegate = UIApplication.shared.delegate as? AppDelegate {
            
            let context = delegate.persistentContainer.viewContext
            let request: NSFetchRequest<Car> = Car.fetchRequest()
            request.predicate = NSPredicate(format: "mark == %@", carName)
            
            do {
                let result = try context.fetch(request)
                selectedCar = result[0]
                insertFromCar(selectedCar: result[0])
            } catch {
                print(error.localizedDescription)
            }
        }
    }
    
    @IBAction func startEngineAction(_ sender: UIButton) {
        
        guard let car = selectedCar else { return }
        car.numberOfTrips += 1
        car.lastDateTrip = Date()
        
        insertFromCar(selectedCar: car)
        
        if let delegate = UIApplication.shared.delegate as? AppDelegate {
            let context = delegate.persistentContainer.viewContext
            do {
                try context.save()
            } catch {
                print(error.localizedDescription)
            }
        }
    }
    
    @IBAction func rateAction(_ sender: UIButton) {
        
        let ac = UIAlertController(title: "Rate it", message: "Rate this car", preferredStyle: .alert)
        let okAction = UIAlertAction(title: "Ok", style: .default) { (action) in
            
            let textField = ac.textFields?[0]
            self.updateRating(rating: textField?.text)
        }
        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel)
        ac.addTextField { (textField) in
            textField.keyboardType = .numberPad
        }
        ac.addAction(okAction)
        ac.addAction(cancelAction)
        present(ac, animated: true)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        loadDataFromFile()
        
        if let delegate = UIApplication.shared.delegate as? AppDelegate,
            let selectedCarName = carSegmentedControl.titleForSegment(at: 0) {
            
            let context = delegate.persistentContainer.viewContext
            let request: NSFetchRequest<Car> = Car.fetchRequest()
            request.predicate = NSPredicate(format: "mark == %@", selectedCarName)
            
            do {
                let result = try context.fetch(request)
                if !result.isEmpty {
                    selectedCar = result[0]
                    insertFromCar(selectedCar: selectedCar!)
                }
                print("Car successfully fetched")
            } catch {
                print(error.localizedDescription)
            }
        }
    }
    
    private func insertFromCar(selectedCar: Car) {
        
        if let imageData = selectedCar.imageData {
            imageView.image = UIImage(data: imageData)
        }
        markLabel.text = selectedCar.mark
        modelLabel.text = selectedCar.model
        numberOfTripsLabel.text = "Number of trips: \(selectedCar.numberOfTrips)"
        ratingLabel.text = "Rating \(selectedCar.rating) / 10.0"
        carSegmentedControl.tintColor = selectedCar.tinColor as? UIColor
        
        if let dateData = selectedCar.lastDateTrip {
            
            let dateFormatter = DateFormatter()
            dateFormatter.dateStyle = .short
            dateFormatter.timeStyle = .none
            
            lastStartedLabel.text = "Last time started: \(dateFormatter.string(from: dateData))"
        }
    }
    
    private func loadDataFromFile() {
        
        guard let delegate = UIApplication.shared.delegate as? AppDelegate else { return }
        let context = delegate.persistentContainer.viewContext
        
        let request: NSFetchRequest<Car> = Car.fetchRequest()
        request.predicate = NSPredicate(format: "mark != nil")
        
        var count = 0
        do {
            count = try context.count(for: request)
            print("Is data already exist? (\(count == 0 ? "No" : "Yes"))")
        } catch {
            print(error.localizedDescription)
        }
        
        guard let path = Bundle.main.path(forResource: "data", ofType: "plist") else {
            print("Error: file data.plist not found!")
            return
        }
        guard let array = NSArray(contentsOfFile: path) else {
            print("Error: ")
            return
        }
        
        guard count == 0 else {
            return
        }
        
        for dictionary in array {
            guard let dictionary = dictionary as? NSDictionary,
                let entity = NSEntityDescription.entity(forEntityName: "Car", in: context),
                let carObject = NSManagedObject(entity: entity, insertInto: context) as? Car else { continue }
            
            guard let mark = dictionary["mark"] as? String,
                let model = dictionary["model"] as? String,
                let lastDateTrip = dictionary["lastStarted"] as? Date,
                let numberOfTrips = dictionary["timesDriven"] as? Int16,
                let rating = dictionary["rating"] as? Double,
                let isFavorite = dictionary["myChoice"] as? Bool,
                let tintColor = dictionary["tintColor"] as? NSDictionary,
                let imageName = dictionary["imageName"] as? String else {
                    print("Error: key not found in dictionary")
                    continue
            }
            guard let image = UIImage(named: imageName) else {
                print("Error: image not found")
                continue
            }
            guard let color = getColor(colorDictionary: tintColor) else {
                print("Error: bad color")
                continue
            }
            carObject.mark = mark
            carObject.model = model
            carObject.lastDateTrip = lastDateTrip
            carObject.numberOfTrips = numberOfTrips
            carObject.rating = rating
            carObject.isFavorite = isFavorite
            carObject.imageData = image.pngData()
            carObject.tinColor = color
        }
    }
    
    private func getColor(colorDictionary: NSDictionary) -> UIColor? {
        guard let red = colorDictionary["red"] as? NSNumber,
            let green = colorDictionary["green"] as? NSNumber,
            let blue = colorDictionary["blue"] as? NSNumber else {
                return nil
        }
        return UIColor(red: CGFloat(red.floatValue), green: CGFloat(green.floatValue), blue: CGFloat(blue.floatValue), alpha: 1)
    }
    
    private func updateRating(rating: String?) {
        
        guard let text = rating, let rating = Double(text), let car = selectedCar else {
            return
        }
        car.rating = rating
        
        guard let delegate = UIApplication.shared.delegate as? AppDelegate else { return }
        let context = delegate.persistentContainer.viewContext
        do {
            try context.save()
            insertFromCar(selectedCar: car)
        } catch {
            let ac = UIAlertController(title: "Wrong rating", message: "Please use 1.0 - 10.0 for rating", preferredStyle: .alert)
            let okAction = UIAlertAction(title: "Ok", style: .default)
            ac.addAction(okAction)
            present(ac, animated: true)
            print(error.localizedDescription)
        }
    }
}

//
//  Car+CoreDataProperties.swift
//  CarDemoProject
//
//  Created by Admin on 09.12.2019.
//  Copyright © 2019 sergei. All rights reserved.
//
//

import Foundation
import CoreData


extension Car {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<Car> {
        return NSFetchRequest<Car>(entityName: "Car")
    }

    @NSManaged public var imageData: Data?
    @NSManaged public var isFavorite: Bool
    @NSManaged public var numberOfTrips: Int16
    @NSManaged public var lastDateTrip: Date?
    @NSManaged public var rating: Double
    @NSManaged public var mark: String?
    @NSManaged public var model: String?
    @NSManaged public var tinColor: NSObject?

}

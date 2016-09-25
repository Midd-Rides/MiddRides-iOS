//
//  LocationStatus.swift
//  middrides
//
//  Created by Julian Billings on 12/3/15.
//  Copyright © 2015 Ben Brown. All rights reserved.
//

import Foundation
import Parse

class LocationStatus: NSObject, NSCoding {
    
    // MARK: Properties
    
    var latestLocVersion: Int
    var vanStops : [String]
    
    static let DocumentsDirectory = FileManager().urls(for: .documentDirectory, in: .userDomainMask).first!
    static let archiveLocStatusURL = DocumentsDirectory.appendingPathComponent("locVersion")
    static let archiveVanStopsURL = DocumentsDirectory.appendingPathComponent("vStops")
    
    // MARK: Initialization
    
    init(latestLocVersion: Int, vanStops: [String]) {
        self.latestLocVersion = latestLocVersion
        self.vanStops = vanStops
    }
    
    // MARK: NSCoding requriements
    
    required convenience init?(coder aDecoder: NSCoder) {
        let currentVersion = aDecoder.decodeObject(forKey: "latestLocVersion") as! Int;
        let currentStops = aDecoder.decodeObject(forKey: "vanStops") as! [String];
        self.init(latestLocVersion: currentVersion, vanStops: currentStops);
    }
    
    func encode(with aCoder: NSCoder){
        aCoder.encode(self.latestLocVersion, forKey: "latestLocVersion")
        aCoder.encode(self.vanStops, forKey: "vanStops")
        
    }
    
    //MARK: NSCoding
    
    func saveData(){
        let isSuccessfulSave1 = NSKeyedArchiver.archiveRootObject(self.latestLocVersion, toFile: LocationStatus.archiveLocStatusURL.path)
        let isSuccessfulSave2 = NSKeyedArchiver.archiveRootObject(self.vanStops, toFile: LocationStatus.archiveVanStopsURL.path)
        if (!isSuccessfulSave1 || !isSuccessfulSave2){
            print("Save failed")
        }
    }
    
    func loadData() -> (locStatus: Int, stops: [String]) {

        if let savedLocStatus = NSKeyedUnarchiver.unarchiveObject(withFile: LocationStatus.archiveLocStatusURL.path) as? Int {
            if let savedStops = NSKeyedUnarchiver.unarchiveObject(withFile: LocationStatus.archiveVanStopsURL.path) as? [String]{
                return (savedLocStatus, savedStops)
            } else {
                return (savedLocStatus, [String]())
            }
        } else {
            return (-1, [String]())
        }
    }
    
    // MARK: Instance Methods
    func setVersion (_ version: Int) {
        self.latestLocVersion = version;
    }
    
    func changeVanStops (_ stops: [String]) {
        self.vanStops = stops;
    }
    
    func getVersion() -> Int {
        return self.latestLocVersion;
    }
    
}

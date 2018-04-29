//
//  SQLiteConfiguration.swift
//  SQLite
//
//  Created by Stanislav Antonov on 29/04/2018.
//  Copyright © 2018 Practical Software Engineering. All rights reserved.
//

import Foundation
import SQLite3

class Configuration {
    private var _path: String? = nil
    public var path: String? {
        get {
            if (self._path == nil) {
                let url: URL = try! FileManager.default.url(
                    for: FileManager.SearchPathDirectory.documentDirectory,
                    in: FileManager.SearchPathDomainMask.userDomainMask,
                    appropriateFor: nil,
                    create: false)
                
                self._path = url.appendingPathComponent(self.fileName).path
            }
            
            return self._path
        }
    }
    
    public let fileName: String!
    public let openFlags: Int32!
    public let busyRetryInterval: Double!
    
    private static let defaultBusyRetryInterval: Double = 10
    
    init(fileName: String, openFlags: Int32, busyRetryInterval: Double) {
        self.fileName = fileName
        self.openFlags = openFlags
        self.busyRetryInterval = busyRetryInterval
    }
    
    convenience init(fileName: String) {
        self.init(fileName: fileName, openFlags: SQLITE_OPEN_READWRITE | SQLITE_OPEN_CREATE, busyRetryInterval: Configuration.defaultBusyRetryInterval)
    }
}


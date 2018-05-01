//
//  SQLite.swift
//  SQLite
//
//  Created by Stanislav Antonov on 29/04/2018.
//  Copyright © 2018 Practical Software Engineering. All rights reserved.
//

import Foundation
import SQLite3

class Db {
    typealias ExecuteCallbackType = ([String: String]) -> Int
    
    fileprivate var connection: Connection?
    fileprivate let configuration: Configuration!
    
    private var isExecuting = false
    private var statementCache = NSCache<NSString, NSMutableSet>()
    
    private var executeCallback: ExecuteCallbackType?
    
    init(configuration: Configuration) {
        self.configuration = configuration
    }
    
    public func beginTransaction() {
        
    }
    
    public func commit() {
        
    }
    
    public func rollback() {
        
    }
    
    private func fetchStatement(sql: String) -> Statement? {
        let statements = statementCache.object(forKey: sql as NSString)
        if (statements == nil) {
            return nil
        }
        
        let freeStatement = statements!.first(where: { o in
            let statement = o as! Statement
            return !statement.inUse
        }) as! Statement?
        
        return freeStatement
    }
    
    private func storeStatement(sql: String, statement: Statement) {
        var statements = statementCache.object(forKey: sql as NSString)
        if (statements == nil) {
            statements = NSMutableSet(object: statement)
            statementCache.setObject(statements!, forKey: sql as NSString)
        } else {
            statements!.add(statement)
        }
    }
    
    public func execute(sql: String, parameters: [AnyObject]) throws -> Bool {
        if (self.isExecuting) {
            NSLog("Already executing")
            return false
        }
        
        self.isExecuting = true
        defer {
            self.isExecuting = false
        }
        
        if (self.connection == nil) {
            self.connection = try Connection.open(configuration: self.configuration)
        }
        
        var shouldCacheStatement = false
        var statement = self.fetchStatement(sql: sql)
        if (statement != nil) {
            statement!.reset()
        } else {
            statement = try Statement(connection: self.connection!, sql: sql)
            defer {
                statement!.finalize()
            }
            
            try statement!.prepare()
            shouldCacheStatement = true
        }
        
        try statement!.bind(parameters: parameters)
        
        let resultSet = ResultSet(statement: statement!)
        if (resultSet.once()) {
            if (shouldCacheStatement) {
                self.storeStatement(sql: sql, statement: statement!)
            }
            
            return true
        }
        
        return false
    }
    
    public func execute(sql: String, callback: ExecuteCallbackType?) throws {
        defer {
            self.executeCallback = nil
        }
        
        var cbPtr: UnsafeMutableRawPointer? = nil
        if (callback != nil) {
            self.executeCallback = callback
            cbPtr = Utils.bridge(obj: self)
        }
        
        var error: UnsafeMutablePointer<Int8>? = nil
        let connection = try Connection.open(configuration: self.configuration)
        
        if (sqlite3_exec(connection.ptr, sql, {
            (cbPtr, columns, valuesPtr: UnsafeMutablePointer<UnsafeMutablePointer<Int8>?>?, namesPtr: UnsafeMutablePointer<UnsafeMutablePointer<Int8>?>?) in
            
            if (cbPtr == nil) {
                return SQLITE_OK
            }
            
            var row = [String: String]()
            for i: Int32 in 0 ..< columns {
                let idx = Int(i)
                if let namePtr = namesPtr?[idx] {
                    let name = String(cString: namePtr)
                    let valuePtr = valuesPtr?[idx]
                    let value: String? = valuePtr != nil ? String(cString: valuePtr!) : nil
                    
                    row[name] = value
                }
            }
            
            let db: Db = Utils.bridge(ptr: cbPtr!)
            let cb = db.executeCallback
            
            return Int32(cb!(row))
        }, cbPtr, &error) != SQLITE_OK) {
            throw Exception.fromMutablePtr(error)
        }
    }
    
    /*
     
     sqlite3_stmt *stmt;
     const char *sql = "SELECT ID, Name FROM User";
     int rc = sqlite3_prepare_v2(db, sql, -1, &stmt, NULL);
     if (rc != SQLITE_OK) {
     print("error: ", sqlite3_errmsg(db));
     return;
     }
     while ((rc = sqlite3_step(stmt)) == SQLITE_ROW) {
     int id           = sqlite3_column_int (stmt, 0);
     const char *name = sqlite3_column_text(stmt, 1);
     // ...
     }
     if (rc != SQLITE_DONE) {
     print("error: ", sqlite3_errmsg(db));
     }
     sqlite3_finalize(stmt);
     
     */
}




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
    
    public func execute(sql: String, parameters: [AnyObject]) throws -> Bool {
        return try self.execute(
            sql: sql,
            parameters: parameters as AnyObject,
            bind: { (statement, parameters) in
                try statement.bind(parameters: parameters as! [AnyObject])
            })
    }
    
    public func execute(sql: String, parameters: [String: AnyObject]) throws -> Bool {
        return try self.execute(
            sql: sql,
            parameters: parameters as AnyObject,
            bind: { (statement, parameters) in
                try statement.bind(parameters: parameters as! [String: AnyObject])
        })
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
        
        let rc = sqlite3_exec(connection.ptr, sql, executeCallbackWrapper, cbPtr, &error)
        if (rc != SQLITE_OK) {
            throw Exception.fromMutablePtr(error)
        }
    }
    
    public func execute(sql: String) throws {
        try self.execute(sql: sql, callback: nil)
    }
    
    private let executeCallbackWrapper: @convention(c) (
        UnsafeMutableRawPointer?, Int32,
        UnsafeMutablePointer<UnsafeMutablePointer<Int8>?>?,
        UnsafeMutablePointer<UnsafeMutablePointer<Int8>?>?) -> Int32 = {
            
            (cbPtr, columns, valuesPtr, namesPtr) in
            
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
            
            let _self: Db = Utils.bridge(ptr: cbPtr!)
            let cb = _self.executeCallback
            
            return Int32(cb!(row))
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
    
    private func execute(sql: String, parameters: AnyObject,
                         bind: (Statement, AnyObject) throws -> Void) throws -> Bool {
        
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
            do {
                statement = try Statement(connection: self.connection!, sql: sql)
                try statement!.prepare()
            } catch {
                statement?.finalize()
                throw error
            }
            
            shouldCacheStatement = true
        }
        
        try bind(statement!, parameters)
        
        let resultSet = ResultSet(statement: statement!)
        if (resultSet.once()) {
            if (shouldCacheStatement) {
                self.storeStatement(sql: sql, statement: statement!)
            }
            
            return true
        }
        
        return false
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




//
//  SQLiteStatement.swift
//  SQLite
//
//  Created by Stanislav Antonov on 29/04/2018.
//  Copyright © 2018 Practical Software Engineering. All rights reserved.
//

import Foundation
import SQLite3

class Statement {
    public var inUse: Bool
    public var isFinalized: Bool
    
    private let sql: String!
    private weak var connection: Connection!
    
    private var _ptr: OpaquePointer?
    public var ptr: OpaquePointer? {
        return _ptr
    }
    
    private var parametersCount: Int32!
    
    init(connection: Connection, sql: String) throws {
        self.sql = sql
        self.connection = connection
        
        self.inUse = false
        self.isFinalized = false
        self.parametersCount = 0
    }
    
    public func bind(parameters: [String: AnyObject]) throws {
        if (parameters.count == 0) {
            return
        }
        
        assert(self.parametersCount == parameters.count,
               "Wrong parameters count passed for binding \(parameters.count) when expected \(self.parametersCount)")
        
        var boundCount: Int = 0
        
        parameters.keys.forEach({ parameterName in
            // let parameterIndex = sqlite3_bind_parameter_index(self._ptr, ":s\(parameterName)")
            let parameterIndex = sqlite3_bind_parameter_index(self._ptr, parameterName)
            
            if (parameterIndex > 0) {
                let parameterValue = parameters[parameterName]
                self.bind(param: parameterValue, atIndex: parameterIndex)
                boundCount = boundCount + 1
            } else {
                NSLog("Could't find index for parameter name %@", parameterName)
            }
        })
        
        assert(self.parametersCount == boundCount,
               "Wrong bound parameters count \(boundCount) when expected \(self.parametersCount)")
    }
    
    public func bind(parameters: [AnyObject]) throws {
        if (parameters.count == 0) {
            return
        }
        
        assert(self.parametersCount == parameters.count,
               "Wrong parameters count passed for binding \(parameters.count) when expected \(self.parametersCount)")
        
        // Check if we really need it
        // self.reset()
        
        var index: Int32 = 0
        
        parameters.forEach({ param in
            self.bind(param: param, atIndex: index)
            index = index + 1
        })
    }
    
    public func prepare() throws {
        do {
            let rc = sqlite3_prepare(self.connection.ptr, self.sql, -1, &self._ptr, nil)
            if (rc != SQLITE_OK) {
                defer {
                    self.finalize()
                }
                
                throw Exception.fromPtr(self.connection.ptr)
            }
            
            self.parametersCount = sqlite3_bind_parameter_count(self._ptr)
        } catch {
            defer {
                sqlite3_finalize(self._ptr)
            }
            
            throw error
        }
    }
    
    public func finalize() {
        sqlite3_finalize(self._ptr)
        self._ptr = nil
        self.inUse = false
        self.isFinalized = true
        self.parametersCount = 0
    }
    
    public func reset() {
        sqlite3_reset(self._ptr)
        self.inUse = false
    }
    
    private func bind(param: AnyObject?, atIndex: Int32) {
        let _ptr = self._ptr
        switch(param) {
        case let val where val == nil:
            sqlite3_bind_null(_ptr, atIndex)
        case is NSNull:
            sqlite3_bind_null(_ptr, atIndex)
        case is Int:
            sqlite3_bind_int64(_ptr, atIndex, (param?.longLongValue)!)
        case is Float:
            sqlite3_bind_double(_ptr, atIndex, (param?.doubleValue)!)
        case is String:
            sqlite3_bind_text(_ptr, atIndex, param?.utf8String, -1, nil)
        // case is Bool:
        
        default:
            break
        }
    }
    
    deinit {
        self.finalize()
    }
}


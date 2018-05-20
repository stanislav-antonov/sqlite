import Foundation
import SQLite3

class Db {
    typealias ExecuteCallbackType = ([String: String]) -> Int
    
    internal var connection: Connection?
    internal let configuration: Configuration!
    
    private var isExecuting = false
    private var openedResultSets = NSMutableSet()
    private var statementCache = NSCache<NSString, NSMutableSet>()
    
    private var executeCallback: ExecuteCallbackType?
    
    public var lastError: String {
        return Utils.getErrorMessage(ptr: self.connection!.ptr)
    }
    
    init(configuration: Configuration) {
        self.configuration = configuration
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
    
    public func execute(sql: String, parameters: [AnyObject]) throws -> ResultSet? {
        return try self.execute(
            sql: sql,
            parameters: parameters as AnyObject,
            bind: { (statement, parameters) in
                try statement.bind(parameters: parameters as! [AnyObject])
        })
    }
    
    public func execute(sql: String, parameters: [String: AnyObject]) throws -> ResultSet? {
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
        
        var errorPtr: UnsafeMutablePointer<Int8>? = nil
        let connection = try Connection.open(configuration: self.configuration)
        
        let rc = sqlite3_exec(connection.ptr, sql, executeCallbackWrapper, cbPtr, &errorPtr)
        if (rc != SQLITE_OK) {
            throw Exception.message(Utils.getErrorMessage(ptr: errorPtr))
        }
    }
    
    public func execute(sql: String) throws {
        try self.execute(sql: sql, callback: nil)
    }
    
    public func beginTransaction() {
        
    }
    
    public func commit() {
        
    }
    
    public func rollback() {
        
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
    
    private func obtainStatemet(sql: String, parameters: AnyObject, bind: (Statement, AnyObject) throws -> Void, shouldCacheStatement: inout Bool) throws -> Statement {
        if (self.connection == nil) {
            self.connection = try Connection.open(configuration: self.configuration)
        }
        
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
        
        return statement!
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
        
        var shouldCacheStatement = false
        let statement = try self.obtainStatemet(sql: sql, parameters: parameters, bind: bind, shouldCacheStatement: &shouldCacheStatement)
        
        let resultSet = ResultSet(statement: statement, db: self)
        let result: (hasRows: Bool, status: Status) = resultSet.next()
        
        if (!result.status.isError) {
            if (shouldCacheStatement) {
                self.storeStatement(sql: sql, statement: statement)
            }
            
            if (result.hasRows) {
                resultSet.close()
            }
            
            return true
        }
        
        return false
    }
    
    private func execute(sql: String, parameters: AnyObject,
                         bind: (Statement, AnyObject) throws -> Void) throws -> ResultSet? {
        
        if (self.isExecuting) {
            NSLog("Already executing")
            return nil
        }
        
        self.isExecuting = true
        defer {
            self.isExecuting = false
        }
        
        var shouldCacheStatement = false
        let statement = try self.obtainStatemet(sql: sql, parameters: parameters, bind: bind, shouldCacheStatement: &shouldCacheStatement)
        
        let resultSet = ResultSet(statement: statement, db: self)
        self.openedResultSets.add(resultSet)
        
        if (shouldCacheStatement) {
            self.storeStatement(sql: sql, statement: statement)
        }
        
        return resultSet
    }
    
    internal func resultSetClosed(resultSet: ResultSet) {
        self.openedResultSets.remove(resultSet)
    }
}




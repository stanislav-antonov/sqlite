//
//  SQLiteTests.swift
//  SQLiteTests
//
//  Created by Stanislav Antonov on 29/04/2018.
//  Copyright © 2018 Practical Software Engineering. All rights reserved.
//

import XCTest
@testable import SQLite

class SQLiteTests: XCTestCase {
    
    private static let dbName: String = "test.db"
    private var configuration = Configuration(fileName: dbName)
    
    override func setUp() {
        super.setUp()
    }
    
    override func tearDown() {
        super.tearDown()
    }
    
    func testConfiguration() {
        XCTAssertTrue(configuration.path != nil)
        XCTAssertTrue(configuration.path!.contains(SQLiteTests.dbName))
    }
    
    func testDbOpen() {
        let connection = try? Connection.open(configuration: self.configuration)
        XCTAssertTrue(connection != nil)
        XCTAssertTrue(connection!.isOpen)
    }
    
    func testExecuteRaw() throws {
        let db = Db(configuration: self.configuration)
        
        try db.execute(sql: "DROP TABLE IF EXISTS test")
        try db.execute(sql: "CREATE TABLE test(id INT, value TEXT)")
        try db.execute(sql: "INSERT INTO test(id, value) VALUES (1, 'test1')")
        try db.execute(sql: "INSERT INTO test(id, value) VALUES (2, 'test2')")
        try db.execute(sql: "INSERT INTO test(id, value) VALUES (3, 'test3')")
        
        var rows = [[String: String]]()
        let callback: Db.ExecuteCallbackType = {
            result in
            rows.append(result)
            return 0
        }
        
        try db.execute(sql: "SELECT id, value FROM test ORDER BY id ASC", callback: callback)
        
        XCTAssertTrue(rows.count == 3)
        XCTAssertTrue(rows[1]["value"] == "test2")
    }
    
    func testExecutePrepared() throws {
        let db = Db(configuration: self.configuration)
        
        try db.execute(sql: "DROP TABLE IF EXISTS test")
        try db.execute(sql: "CREATE TABLE test(id INT, status INT, value TEXT)")
        try db.execute(sql: "INSERT INTO test(id, status, value) VALUES (1, 2, 'test1'), (2, 1, 'test2'), (3, 2, 'test3'), (4, 1, 'test4'), (5, 2, 'test5'), (6, 1, 'test6'), (7, 1, 'test7')")
        
        let result1: Bool = try db.execute(
            sql: "UPDATE test SET status = ? WHERE status = ?",
            parameters: [1 as AnyObject, 2 as AnyObject]
        )
        
        XCTAssertTrue(result1)
        
        let result2: Bool = try db.execute(
            sql: "UPDATE test SET status = $a WHERE status = $b",
            parameters: ["$a" :  1 as AnyObject, "$b" : 2 as AnyObject]
        )
        
        XCTAssertTrue(result2)
        
        let callback: Db.ExecuteCallbackType = {
            result in
            let count = Int(result["cnt"]!)
            XCTAssertTrue(count == 0)
            return 0
        }
        
        try db.execute(sql: "SELECT COUNT(*) AS cnt FROM test WHERE status = 2", callback: callback)
    }
    
    func testPerformanceExample() {
        // This is an example of a performance test case.
        self.measure {
            // Put the code you want to measure the time of here.
        }
    }
    
}

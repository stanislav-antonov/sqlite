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
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }
    
    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
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
    
    func testPerformanceExample() {
        // This is an example of a performance test case.
        self.measure {
            // Put the code you want to measure the time of here.
        }
    }
    
}

//
//  GooseTests.swift
//  GooseTests
//
//  Created by shayanbo on 2023/3/19.
//

import XCTest
@testable import Goose

final class GooseTests: XCTestCase {

    func testExample() throws {
        
        struct Person {
            let age = 30
            let male = true
        }
        
        let goose = try! Goose("/Users/shayanbo/Desktop/haha.mmap")
//        goose.store(1, for: "A")
//        goose.store(true, for: "B")
//        goose.store([1,2,3,4], for: "C")
//        goose.store("1234567890ABCDE", for: "D")
//        goose.store([1 : 2, 3 : 4, 5 : 6], for: "E")
//        goose.store(1, for: "A")
//        goose.store(Person(), for: "F")
//        goose.store(Data([123, 34, 51, 34, 58, 52, 44, 34, 53, 34, 58, 54, 44, 34, 49, 34, 58, 50, 125]), for: "G")
        
        let a: Int? = goose.obtain(for: "A")
        let b: Bool? = goose.obtain(for: "B")
        let c: [Int]? = goose.obtain(for: "C")
        let d: String? = goose.obtain(for: "D")
        let e: [Int:Int]? = goose.obtain(for: "E")
        let f: Person? = goose.obtain(for: "F")
        let g: Data? = goose.obtain(for: "G")
//
//        goose.resize()
//
        XCTAssertEqual(a!, 1)
        XCTAssertEqual(b!, true)
        XCTAssertEqual(c!, [1,2,3,4])
        XCTAssertEqual(d!, "1234567890ABCDE")
        XCTAssertEqual(e!, [1 : 2, 3 : 4, 5 : 6])
        XCTAssertEqual(f!.age, Person().age)
        XCTAssertEqual(f!.male, Person().male)
        XCTAssertEqual(g, Data([123, 34, 51, 34, 58, 52, 44, 34, 53, 34, 58, 54, 44, 34, 49, 34, 58, 50, 125]))
    }
    
    func testExample1() throws {
        
        let goose = Goose("/Users/shayanbo/Desktop/haha.mmap")
        goose.store(1, for: "A")
        goose.store(2, for: "A")
        goose.store(3, for: "A")
        goose.store(4, for: "A")
        goose.store(5, for: "A")
        goose.store(6, for: "A")
    }
}

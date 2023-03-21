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
        
        struct Extra {
            let married = true
            let hasKids = false
        }
        
        class Person : Codable {
            var age = 30
            var name = "Yanbo Sha"
            var male = true
        }
        
        let goose = Goose("/Users/shayanbo/Desktop/haha.mmap")
        
        goose.store(31, for: "age")
        goose.store(true, for: "male")
        goose.store(Extra(), for: "trivial")

        goose.store("Yanbo Sha", for: "name")

        goose.store(Person(), for: "codable")
        goose.store([1,2,3,4], for: "score")
        goose.store(["eat" : true, "run" : true, "sleep" : false], for: "abilities")
        
        goose.store(Optional<Int>.none, for: "age")
        
        let age: Int? = goose.obtain(for: "age")
        print(age)
    }
}

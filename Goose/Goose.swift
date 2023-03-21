//
//  Goose.swift
//  Goose
//
//  Created by shayanbo on 2023/3/19.
//

import Foundation

/// │ data_len (8bytes) (head not included) │ key_size (8bytes) │ value_size(8bytes) │ key(unfixed) │ value(unfixed) │ ...

public extension Goose {
    
    private struct BodyRecord {
        let key: String
        let data: Data
    }
}

public class Goose {

    private var original: UnsafeMutableRawPointer?
    private var buffer: UnsafeMutableRawPointer?
    
    private var capacity: Int
    private var filePath: String
    
    private var memoryCache = [String: Data]()
    
    public init(_ filePath: String, capacity: Int = 10 * 1024) {
        self.capacity = capacity
        self.filePath = filePath
        
        remap()
        reload()
    }
}

public extension Goose {
    
    @discardableResult private func storePrimitive<T>(_ object: T?, for key: String) -> Bool {
        var obj = object
        let data = Data(bytes: &obj, count: MemoryLayout<T>.size)
        append(BodyRecord(key: key, data: data))
        return true
    }
    
    /// Signed
    @discardableResult func store(_ object: Int?, for key: String) -> Bool { storePrimitive(object, for: key) }
    @discardableResult func store(_ object: Int8?, for key: String) -> Bool { storePrimitive(object, for: key) }
    @discardableResult func store(_ object: Int16?, for key: String) -> Bool { storePrimitive(object, for: key) }
    @discardableResult func store(_ object: Int32?, for key: String) -> Bool { storePrimitive(object, for: key) }
    @discardableResult func store(_ object: Int64?, for key: String) -> Bool { storePrimitive(object, for: key) }
    
    /// Unsigned
    @discardableResult func store(_ object: UInt?, for key: String) -> Bool { storePrimitive(object, for: key) }
    @discardableResult func store(_ object: UInt64?, for key: String) -> Bool { storePrimitive(object, for: key) }
    @discardableResult func store(_ object: UInt32?, for key: String) -> Bool { storePrimitive(object, for: key) }
    @discardableResult func store(_ object: UInt16?, for key: String) -> Bool { storePrimitive(object, for: key) }
    @discardableResult func store(_ object: UInt8?, for key: String) -> Bool { storePrimitive(object, for: key) }
    
    /// Decimal
    @discardableResult func store(_ object: Float?, for key: String) -> Bool { storePrimitive(object, for: key) }
    @discardableResult func store(_ object: Double?, for key: String) -> Bool { storePrimitive(object, for: key) }
    @discardableResult func store(_ object: CGFloat?, for key: String) -> Bool { storePrimitive(object, for: key) }
    
    /// Anything else (simple type)
    @discardableResult func store<T>(_ object: T?, for key: String) -> Bool { storePrimitive(object, for: key) }
    
    /// Bool
    @discardableResult func store(_ object: Bool?, for key: String) -> Bool { storePrimitive(object, for: key) }
}

extension Goose {
    
    @discardableResult func store<T>(_ object: T?, for key: String) -> Bool where T : Codable {
        
        if let object = object, let data = try? JSONEncoder().encode(object) {
            append(BodyRecord(key: key, data: data))
            return true
        }
        return false
    }
    
    @discardableResult func store(_ object: Data?, for key: String) -> Bool {
        
        if let object = object {
            append(BodyRecord(key: key, data: object))
            return true
        }
        return false
    }
    
    @discardableResult func store(_ object: String?, for key: String) -> Bool {
        
        if let object = object, let data = object.data(using: .utf8) {
            append(BodyRecord(key: key, data: data))
            return true
        }
        return false
    }
}

public extension Goose {
    
    private func obtainPrimitive<T>(for key: String) -> T? {
        if var data = memoryCache[key] {
            return data.withUnsafeMutableBytes { buffer in
                return buffer.load(as: T.self)
            }
        }
        return nil
    }
    
    /// Signed
    func obtain(for key: String) -> Int? { obtainPrimitive(for: key) }
    func obtain(for key: String) -> Int8? { obtainPrimitive(for: key) }
    func obtain(for key: String) -> Int16? { obtainPrimitive(for: key) }
    func obtain(for key: String) -> Int32? { obtainPrimitive(for: key) }
    func obtain(for key: String) -> Int64? { obtainPrimitive(for: key) }
    
    /// Unsigned
    func obtain(for key: String) -> UInt? { obtainPrimitive(for: key) }
    func obtain(for key: String) -> UInt8? { obtainPrimitive(for: key) }
    func obtain(for key: String) -> UInt16? { obtainPrimitive(for: key) }
    func obtain(for key: String) -> UInt32? { obtainPrimitive(for: key) }
    func obtain(for key: String) -> UInt64? { obtainPrimitive(for: key) }
    
    /// Decimal
    func obtain(for key: String) -> Float? { obtainPrimitive(for: key) }
    func obtain(for key: String) -> CGFloat? { obtainPrimitive(for: key) }
    func obtain(for key: String) -> Double? { obtainPrimitive(for: key) }
    
    /// Bool
    func obtain(for key: String) -> Bool? { obtainPrimitive(for: key) }
    
    /// Anything else (simple type)
    func obtain<T>(for key: String) -> T? { obtainPrimitive(for: key) }
}

extension Goose {
    
    /// Codable including codable Array & codable Dictionary
    func obtain<T>(for key: String) -> T? where T : Codable {
        if let data = memoryCache[key] {
            return try? JSONDecoder().decode(T.self, from: data)
        }
        return nil
    }

    /// String
    func obtain(for key: String) -> String? {
        if let data = memoryCache[key] {
            return String(data: data, encoding: .utf8)
        }
        return nil
    }

    /// Data
    func obtain(for key: String) -> Data? {
        memoryCache[key]
    }
}

extension Goose {
    
    private func append(_ record: BodyRecord) {
        
        guard let keyData = record.key.data(using: .utf8) else {
            return
        }
        
        /// cache it for fast check
        memoryCache[record.key] = record.data
        
        guard var buffer = buffer else {
            return
        }
        
        /// make sure the capacity is enough
        ensureCapacity(BodyRecord(key: record.key, data: record.data))
        
        /// mmap: key_size
        buffer.storeBytes(of: UInt64(keyData.count), as: UInt64.self)
        buffer += 8
        
        /// mmap: value_size
        buffer.storeBytes(of: UInt64(record.data.count), as: UInt64.self)
        buffer += 8
        
        /// mmap: key
        keyData.withUnsafeBytes { rawBuffer in
            rawBuffer.forEach { char in
                buffer.storeBytes(of: char, as: UInt8.self)
                buffer += 1
            }
        }
        
        /// mmap: value
        record.data.withUnsafeBytes { rawBuffer in
            rawBuffer.forEach { char in
                buffer.storeBytes(of: char, as: UInt8.self)
                buffer += 1
            }
        }
        
        /// mmap: update data_len
        increaseTotal(UInt64(8 + 8 + keyData.count + record.data.count))
    }
    
    private func available(_ record: BodyRecord) -> Bool {
        
        guard let buffer = buffer, let original = original else {
            return false
        }
        
        guard let keyData = record.key.data(using: .utf8) else {
            return false
        }
        
        let remaining = capacity - original.distance(to: buffer)
        let increment = 8 + 8 + keyData.count + record.data.count
        return remaining >= increment
    }
    
    private func reload() {
        
        guard var buffer = buffer, let original = original else {
            return
        }
        
        /// get data len from data_len area
        let total = original.withMemoryRebound(to: UInt64.self, capacity: 8) { pointer in
            return pointer.pointee
        }
        
        buffer = original
        buffer += 8
        
        while original.distance(to: buffer) < total + 8 {
            
            let keySizeData = Data(bytes: UnsafeRawPointer(buffer), count: 8)
            let keySize = keySizeData.withUnsafeBytes { $0.load(as: UInt64.self) }
            buffer += 8
            
            let dataSizeData = Data(bytes: UnsafeRawPointer(buffer), count: 8)
            let dataSize = dataSizeData.withUnsafeBytes { $0.load(as: UInt64.self) }
            buffer += 8
            
            let keyData = Data(bytes: UnsafeRawPointer(buffer), count: Int(keySize))
            buffer += .Stride(keySize)
            
            if let key = String(data: keyData, encoding: .utf8) {
                let data = Data(bytes: UnsafeRawPointer(buffer), count: Int(dataSize))
                memoryCache[key] = data
            }
            buffer += .Stride(dataSize)
        }
    }
    
    private func ensureCapacity(_ record: BodyRecord) {
        
        guard !available(record) else {
            return
        }
        /// compact at first to make room for the new data
        rewrite()
        
        if available(record) {
            return
        }
        // grow size if there's no enough room
        munmap(original, capacity) /// reset
        capacity *= 2 /// resize
        remap() /// remap
        rewrite() /// rewrite
    }
    
    private func rewrite() {
        
        /// reset
        memset(original, 0, capacity)
        
        /// reset buffer to the head
        buffer = original
        
        /// jump to the first location after header
        buffer? += 8
        
        /// write one by one from the memory cache
        for (key, data) in memoryCache {
            append(BodyRecord(key: key, data: data))
        }
    }
    
    private func remap() {
        
        /// ⚠️ throw error if the path is invalid
        guard let path:[CChar] = filePath.cString(using: .utf8) else {
            return
        }
        
        /// ⚠️ throw error if the file can't be created or open
        let fileNo = open(path, O_CREAT | O_RDWR, S_IREAD | S_IWRITE)
        if fileNo <= 0 {
            return
        }

        /// ⚠️ throw error if the file can't be truncated to the specific size
        if ftruncate(fileNo, off_t(capacity)) != 0 {
            return
        }

        /// 📄 create mmap area
        buffer = mmap(UnsafeMutableRawPointer(mutating: nil), capacity, PROT_READ | PROT_WRITE, MAP_SHARED, fileNo, 0)
        original = buffer
    }
    
    private func increaseTotal(_ total: UInt64) {
        original?.withMemoryRebound(to: UInt64.self, capacity: 8) { pointer in
            pointer.pointee += total
        }
    }
}


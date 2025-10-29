//
//  Extension.swift
//  WWSimpleZipDirectoryReader
//
//  Created by William.Weng on 2025/10/29.
//

import Foundation

// MARK: - Data
extension Data {
    
    /// 讀取小端序 (Little-Endian)
    /// - Parameter offset: Int
    /// - Returns: FixedWidthInteger
    func littleEndian<T: FixedWidthInteger>(from offset: Int) -> T {
        
        let size = MemoryLayout<T>.size
        let slice = self[offset..<(offset + size)]

        var value: T = 0
        for (index, byte) in slice.enumerated() {
            value |= T(byte) << (index * 8)
        }
        return value
    }
    
    /// 讀取大端序 (Big-Endian)
    /// - Parameter offset: Int
    /// - Returns: FixedWidthInteger
    func bigEndian<T: FixedWidthInteger>(from offset: Int) -> T {
        let littleEndianValue = littleEndian(from: offset) as T
        return littleEndianValue.byteSwapped
    }
}

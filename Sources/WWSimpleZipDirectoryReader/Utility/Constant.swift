//
//  Constant.swift
//  WWSimpleZipDirectoryReader
//
//  Created by William.Weng on 2025/10/29.
//

import Foundation

// MARK: - typealias
public extension WWSimpleZipDirectoryReader {
    
    typealias SizeInfo = (compressed: UInt32, uncompressed: UInt32)                         // 檔案大小 (壓縮, 未壓縮)
    typealias EntryInfo = (name: String, compressedSize: UInt32, uncompressedSize: UInt32)  // 項目資訊 (檔名, 壓縮, 未壓縮)
    typealias CentralDirectoryInformation = (offset: UInt32, numberOfEntries: UInt16)       // 中央目錄 (起始位置, 檔案數量)
}

// MARK: - enum
public extension WWSimpleZipDirectoryReader {
    
    /// 自定義錯誤
    enum CustomError: Error {
        case fileHeaderInvalid(_ offset: Int)                                               // 在位移處中央目錄檔案標頭無效
        case eocdSignatureNotFound                                                          // 找不到EOCD標記
    }
}

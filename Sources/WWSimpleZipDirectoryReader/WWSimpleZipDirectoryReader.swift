//
//  SimpleZipDirectoryReader.swift
//  SimpleZipDirectoryReader
//
//  Created by William.Weng on 2025/10/29.
//

import Foundation

// MARK: - 簡單的Zip目錄內容讀取器
open class WWSimpleZipDirectoryReader {
    
    @MainActor public static let shared = WWSimpleZipDirectoryReader()
}

// MARK: - 公開函式
public extension WWSimpleZipDirectoryReader {
    
    /// 以名稱排序顯示
    /// - Parameter fileUrl: URL
    /// - Returns: Result<[EntryInfo], Error>
    func array(fileUrl: URL) -> Result<[EntryInfo], Error> {
        
        do {
            let dict = try dictionay(fileURL: fileUrl).get()
            var array: [EntryInfo] = []
            
            for (key, value) in dict {
                let element: EntryInfo = (name: key, compressedSize: value.compressed, uncompressedSize: value.uncompressed)
                array.append(element)
            }
            
            return .success(array.sorted { $0.name < $1.name })
            
        } catch {
            return .failure(error)
        }
    }
    
    /// 以字典方式顯示
    /// - Parameter fileUrl: URL
    /// - Returns: Result<[檔案名稱: SizeInfo], Error>
    func dictionay(fileURL: URL) -> Result<[String: SizeInfo], Error> {
        
        do {
            let fileData = try Data(contentsOf: fileURL)
            let eocdStart = try _eocdOffset(fileData: fileData).get()
            let info = parseCentralDirectory(fileData: fileData, eocdStart: eocdStart)
            let fileInfos = try _parseFileHeader(fileData: fileData, info: info).get()
            
            return .success(fileInfos)
            
        } catch {
            return .failure(error)
        }
    }
}

// MARK: - 小工具
private extension WWSimpleZipDirectoryReader {
    
    /// 步驟 1 => 從後往前掃描，找到 EOCD (End of Central Directory) 記錄
    /// - Parameter fileData: Data
    /// - Returns: Result<Int, Error>
    func _eocdOffset(fileData: Data) -> Result<Int, Error> {
        
        let eocdSignature: [UInt8] = [0x50, 0x4B, 0x05, 0x06]   // "PK\x05\x06"
        var eocdOffset: Int?

        // ZIP 註解長度上限約為 64k，所以我們只掃描最後一段區域
        let searchRange = 0..<(min(fileData.count, 0xFFFF + eocdSignature.count))

        for index in searchRange {
            
            let offset = fileData.count - eocdSignature.count - index
            let slice = fileData[offset..<(offset + eocdSignature.count)]
            
            if (Array(slice) != eocdSignature) { continue }
            eocdOffset = offset; break
        }
        
        if let eocdOffset = eocdOffset { return .success(eocdOffset) }
        return .failure(CustomError.eocdSignatureNotFound)
    }
    
    /// 步驟 2 => 解析 EOCD 記錄，找到中央目錄的起始位置和大小 (此處的數字是根據 ZIP 格式規範的固定位移)
    /// - Parameters:
    ///   - fileData: Data
    ///   - eocdStart: EOCD起啟位置
    /// - Returns: CentralDirectoryInformation
    func parseCentralDirectory(fileData: Data, eocdStart: Int) -> CentralDirectoryInformation {
        
        let numberOfEntries: UInt16 = fileData.littleEndian(from: eocdStart + 0x0A)         // 10
        let centralDirectoryOffset: UInt32 = fileData.littleEndian(from: eocdStart + 0x10)  // 16
        
        return (centralDirectoryOffset, numberOfEntries)
    }
    
    /// 步驟 3 & 4: 跳到中央目錄，並迴圈讀取每一個檔案標頭
    /// - Parameters:
    ///   - fileData: Data
    ///   - info: CentralDirectoryInformation
    /// - Returns: Result<[String: SizeInfo], Error>
    func _parseFileHeader(fileData: Data, info: CentralDirectoryInformation) -> Result<[String: SizeInfo], Error> {
        
        let cdFileHeaderSignature: [UInt8] = [0x50, 0x4B, 0x01, 0x02] // "PK\x01\x02"

        var fileInfos: [String: SizeInfo] = [:]
        var currentOffset = Int(info.offset)
        
        for _ in 0..<info.numberOfEntries {
            
            guard Array(fileData[currentOffset..<(currentOffset + 4)]) == cdFileHeaderSignature else { return .failure(CustomError.fileHeaderInvalid(currentOffset)) }
            
            // 從標頭中解析出檔案大小和檔名長度
            let compressedSize: UInt32 = fileData.littleEndian(from: currentOffset + 0x14)      // 20
            let uncompressedSize: UInt32 = fileData.littleEndian(from: currentOffset + 0x18)    // 24
            let fileNameLength: UInt16 = fileData.littleEndian(from: currentOffset + 0x1C)      // 28
            let extraFieldLength: UInt16 = fileData.littleEndian(from: currentOffset + 0x1E)    // 30
            let fileCommentLength: UInt16 = fileData.littleEndian(from: currentOffset + 0x20)   // 32
            
            // 根據長度讀取檔名
            let headerFixedLength = 0x2E // 46
            let filenameStart = currentOffset + headerFixedLength
            let filenameEnd = filenameStart + Int(fileNameLength)
            let filenameData = fileData[filenameStart..<filenameEnd]
            
            if let filename = String(data: filenameData, encoding: .utf8) {
                fileInfos[filename] = (compressed: compressedSize, uncompressed: uncompressedSize)
            }
            
            // 計算下一個標頭的起始位置
            currentOffset += (headerFixedLength + Int(fileNameLength) + Int(extraFieldLength) + Int(fileCommentLength))
        }
        
        return .success(fileInfos)
    }
}

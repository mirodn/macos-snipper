import XCTest
import Cocoa
@testable import MacosSnipper

/// A mock capturer that returns a solid 1×1 pixel image for deterministic testing.
class MockCapturer: ScreenCapturing {
    func capture() -> CGImage? {
        let colorSpace = CGColorSpace(name: CGColorSpace.sRGB)!
        let ctx = CGContext(
            data: nil,
            width: 1,
            height: 1,
            bitsPerComponent: 8,
            bytesPerRow: 4,
            space: colorSpace,
            bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
        )!
        ctx.setFillColor(NSColor.red.cgColor)
        ctx.fill(CGRect(x: 0, y: 0, width: 1, height: 1))
        return ctx.makeImage()
    }
}

final class UserSettingsTests: XCTestCase {
    override func setUp() {
        super.setUp()
        UserDefaults.standard.removeObject(forKey: "savePath")
    }

    func testDefaultSavePathIsSnipperFolderInPictures() {
        let url = UserSettings.savePath
        XCTAssertEqual(
            url.lastPathComponent,
            "Snipper",
            "Default save path must end in 'Snipper'"
        )
    }

    func testCustomSavePathPersistsAcrossAccesses() {
        let tempFolder = URL(
            fileURLWithPath: NSTemporaryDirectory(),
            isDirectory: true
        ).appendingPathComponent("TestFolder")
        UserSettings.savePath = tempFolder
        XCTAssertEqual(
            UserSettings.savePath,
            tempFolder,
            "Custom save path should be stored and returned"
        )
    }
}

final class ScreenshotServiceTests: XCTestCase {
    func testMakePNGDataReturnsNonNil() {
        let service = ScreenshotService(capturer: MockCapturer())
        let data = service.makePNGData()
        XCTAssertNotNil(
            data,
            "makePNGData() should not return nil for a valid CGImage"
        )
    }

    func testMakePNGDataProducesValidPNGHeader() {
        let service = ScreenshotService(capturer: MockCapturer())
        guard let data = service.makePNGData() else {
            return XCTFail("makePNGData() returned nil")
        }
        // PNG files always start with these 8 bytes
        let expectedHeader: [UInt8] = [0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A]
        let actualHeader = [UInt8](data.prefix(8))
        XCTAssertEqual(
            actualHeader,
            expectedHeader,
            "PNG data must begin with the standard PNG header bytes"
        )
    }
}

final class DateFormatterTests: XCTestCase {
    func testFilenameDateFormatterProducesCorrectString() {
        let formatter = DateFormatter()
        // Force UTC for deterministic output
        formatter.timeZone = TimeZone(secondsFromGMT: 0)
        formatter.dateFormat = "yyyy-MM-dd_HH-mm-ss"
        let date = Date(timeIntervalSince1970: 0) // Jan 1, 1970 00:00:00 UTC
        let formatted = formatter.string(from: date)
        XCTAssertEqual(
            formatted,
            "1970-01-01_00-00-00",
            "DateFormatter must output in 'yyyy-MM-dd_HH-mm-ss' format"
        )
    }
}

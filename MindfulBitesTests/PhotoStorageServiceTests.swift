import XCTest
import UIKit
@testable import MindfulBites

final class PhotoStorageServiceTests: XCTestCase {

    private var sut: PhotoStorageService!
    private var tempDir: URL!

    override func setUp() {
        super.setUp()
        tempDir = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        sut = PhotoStorageService(photosDirectory: tempDir)
    }

    override func tearDown() {
        try? FileManager.default.removeItem(at: tempDir)
        tempDir = nil
        sut = nil
        super.tearDown()
    }

    // MARK: - Save / Load / Delete

    func testSaveAndLoadPhoto() {
        let image = makeTestImage()
        let filename = sut.savePhoto(image)
        XCTAssertNotNil(filename)

        let loaded = sut.loadPhoto(filename: filename!)
        XCTAssertNotNil(loaded)
    }

    func testSaveCreatesFile() {
        let image = makeTestImage()
        let filename = sut.savePhoto(image)!
        let fileURL = tempDir.appendingPathComponent(filename)
        XCTAssertTrue(FileManager.default.fileExists(atPath: fileURL.path))
    }

    func testDeleteRemovesFile() {
        let image = makeTestImage()
        let filename = sut.savePhoto(image)!
        sut.deletePhoto(filename: filename)
        XCTAssertNil(sut.loadPhoto(filename: filename))
    }

    func testLoadNonexistentReturnsNil() {
        XCTAssertNil(sut.loadPhoto(filename: "nonexistent.jpg"))
    }

    func testDeleteNonexistentDoesNotCrash() {
        sut.deletePhoto(filename: "nonexistent.jpg")
    }

    // MARK: - File Access

    func testPhotoFileURL() {
        let url = sut.photoFileURL(filename: "test.jpg")
        XCTAssertEqual(url, tempDir.appendingPathComponent("test.jpg"))
    }

    func testAllPhotoFilenames() {
        let image = makeTestImage()
        _ = sut.savePhoto(image)
        _ = sut.savePhoto(image)

        let filenames = sut.allPhotoFilenames()
        XCTAssertEqual(filenames.count, 2)
        for name in filenames {
            XCTAssertTrue(name.hasSuffix(".jpg"))
        }
    }

    func testAllPhotoFilenamesEmpty() {
        XCTAssertEqual(sut.allPhotoFilenames().count, 0)
    }

    // MARK: - Directory Creation

    func testDirectoryCreatedOnInit() {
        XCTAssertTrue(FileManager.default.fileExists(atPath: tempDir.path))
    }

    // MARK: - Helpers

    private func makeTestImage() -> UIImage {
        let renderer = UIGraphicsImageRenderer(size: CGSize(width: 10, height: 10))
        return renderer.image { context in
            UIColor.red.setFill()
            context.fill(CGRect(x: 0, y: 0, width: 10, height: 10))
        }
    }
}

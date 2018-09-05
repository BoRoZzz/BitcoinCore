import XCTest
import Cuckoo
import RealmSwift
@testable import WalletKit

class HeaderHandlerTests: XCTestCase {

    private var mockValidatedBlockFactory: MockValidatedBlockFactory!
    private var mockBlockSyncer: MockBlockSyncer!
    private var headerHandler: HeaderHandler!

    private var realm: Realm!

    override func setUp() {
        super.setUp()

        let mockWalletKit = MockWalletKit()

        mockValidatedBlockFactory = mockWalletKit.mockValidatedBlockFactory
        mockBlockSyncer = mockWalletKit.mockBlockSyncer
        realm = mockWalletKit.realm

        stub(mockBlockSyncer) { mock in
            when(mock.enqueueRun()).thenDoNothing()
        }

        headerHandler = HeaderHandler(realmFactory: mockWalletKit.mockRealmFactory, validateBlockFactory: mockValidatedBlockFactory, blockSyncer: mockBlockSyncer)
    }

    override func tearDown() {
        mockValidatedBlockFactory = nil
        mockBlockSyncer = nil
        headerHandler = nil

        realm = nil

        super.tearDown()
    }

    func testHandle_EmptyHeaders() {
        var caught = false

        do {
            try headerHandler.handle(headers: [])
        } catch let error as HeaderHandler.HandleError {
            caught = true
            XCTAssertEqual(error, HeaderHandler.HandleError.emptyHeaders)
        } catch {
            XCTFail("Unknown exception thrown")
        }

        XCTAssertTrue(caught, "emptyHeaders exception not thrown")

        verify(mockBlockSyncer, never()).enqueueRun()
    }

    func testValidBlocks() {
        let secondBlock = TestData.secondBlock
        let firstBlock = secondBlock.previousBlock!

        stub(mockValidatedBlockFactory) { mock in
            when(mock.block(fromHeader: equal(to: firstBlock.header!), previousBlock: equal(to: nil))).thenReturn(firstBlock)
            when(mock.block(fromHeader: equal(to: secondBlock.header!), previousBlock: equal(to: firstBlock))).thenReturn(secondBlock)
        }

        try! headerHandler.handle(headers: [firstBlock.header!, secondBlock.header!])

        XCTAssertNotEqual(realm.objects(Block.self).filter("reversedHeaderHashHex = %@", firstBlock.reversedHeaderHashHex).first, nil)
        XCTAssertNotEqual(realm.objects(Block.self).filter("reversedHeaderHashHex = %@", secondBlock.reversedHeaderHashHex).first, nil)

        verify(mockBlockSyncer).enqueueRun()
    }

    func testInvalidBlocks() {
        let secondBlock = TestData.secondBlock
        let firstBlock = secondBlock.previousBlock!

        stub(mockValidatedBlockFactory) { mock in
            when(mock.block(fromHeader: equal(to: firstBlock.header!), previousBlock: equal(to: nil))).thenThrow(BlockValidator.ValidatorError.notEqualBits)
            when(mock.block(fromHeader: equal(to: secondBlock.header!), previousBlock: equal(to: firstBlock))).thenReturn(secondBlock)
        }

        var caught = false

        do {
            try headerHandler.handle(headers: [firstBlock.header!, secondBlock.header!])
        } catch let error as BlockValidator.ValidatorError {
            caught = true
            XCTAssertEqual(error, BlockValidator.ValidatorError.notEqualBits)
        } catch {
            XCTFail("Unknown exception thrown")
        }

        XCTAssertTrue(caught, "validation exception not thrown")

        XCTAssertEqual(realm.objects(Block.self).filter("reversedHeaderHashHex = %@", firstBlock.reversedHeaderHashHex).first, nil)
        XCTAssertEqual(realm.objects(Block.self).filter("reversedHeaderHashHex = %@", secondBlock.reversedHeaderHashHex).first, nil)

        verify(mockBlockSyncer, never()).enqueueRun()
    }

    func testPartialValidBlocks() {
        let secondBlock = TestData.secondBlock
        let firstBlock = secondBlock.previousBlock!

        stub(mockValidatedBlockFactory) { mock in
            when(mock.block(fromHeader: equal(to: firstBlock.header!), previousBlock: equal(to: nil))).thenReturn(firstBlock)
            when(mock.block(fromHeader: equal(to: secondBlock.header!), previousBlock: equal(to: firstBlock))).thenThrow(BlockValidator.ValidatorError.notEqualBits)
        }

        var caught = false

        do {
            try headerHandler.handle(headers: [firstBlock.header!, secondBlock.header!])
        } catch let error as BlockValidator.ValidatorError {
            caught = true
            XCTAssertEqual(error, BlockValidator.ValidatorError.notEqualBits)
        } catch {
            XCTFail("Unknown exception thrown")
        }

        XCTAssertTrue(caught, "validation exception not thrown")

        XCTAssertNotEqual(realm.objects(Block.self).filter("reversedHeaderHashHex = %@", firstBlock.reversedHeaderHashHex).first, nil)
        XCTAssertEqual(realm.objects(Block.self).filter("reversedHeaderHashHex = %@", secondBlock.reversedHeaderHashHex).first, nil)

        verify(mockBlockSyncer).enqueueRun()
    }

}

import XCTest
@testable import FoodApp

final class AIResponseDecoderTests: XCTestCase {
    private func decode(_ json: String) throws -> [RecognizedFood] {
        let dto = try AIResponseDecoder.decode(FoodRecognitionResponseDTO.self, from: Data(json.utf8))
        return dto.foods.elements.map { $0.toDomain(normalizer: .shared) }
    }

    func testValidResponse() throws {
        let foods = try decode("""
        {"foods":[{"name":"Помидор","normalizedName":"tomato","category":"vegetables","confidence":0.95,"quantity":2,"unit":"шт"}]}
        """)
        XCTAssertEqual(foods.count, 1)
        XCTAssertEqual(foods[0].normalizedName, "tomato")
        XCTAssertEqual(foods[0].quantity, 2)
    }

    func testMarkdownFencesAndSurroundingTextAreStripped() throws {
        let foods = try decode("""
        Вот результат:
        ```json
        {"foods":[{"name":"Яйца","confidence":0.9}]}
        ```
        """)
        XCTAssertEqual(foods.map(\.normalizedName), ["egg"])
    }

    func testBadElementsAreSkippedAndUnknownEnumsTolerated() throws {
        let foods = try decode("""
        {"foods":[{"name":""},{"confidence":0.4},42,{"name":"Сыр","category":"space_food","confidence":"0.8","quantity":"200"}]}
        """)
        XCTAssertEqual(foods.count, 1)
        XCTAssertEqual(foods[0].category, .other)
        XCTAssertEqual(foods[0].confidence, 0.8, accuracy: 0.001)
        XCTAssertEqual(foods[0].quantity, 200)
    }

    func testConfidenceIsClampedAndInvalidQuantityDropped() throws {
        let foods = try decode(#"{"foods":[{"name":"Лук","confidence":7,"quantity":-3,"unit":"шт"}]}"#)
        XCTAssertEqual(foods[0].confidence, 1)
        XCTAssertNil(foods[0].quantity)
        XCTAssertNil(foods[0].unit)
    }

    func testMalformedJSONThrowsDecodingError() {
        XCTAssertThrowsError(try decode("not json at all")) { error in
            XCTAssertEqual(error as? AppError, .decoding)
        }
    }

    func testEmptyResponseThrows() {
        XCTAssertThrowsError(try AIResponseDecoder.decode(FoodRecognitionResponseDTO.self, from: Data())) { error in
            XCTAssertEqual(error as? AppError, .emptyResponse)
        }
    }

    func testMissingFoodsKeyGivesEmptyList() throws {
        XCTAssertTrue(try decode(#"{"result":"nothing"}"#).isEmpty)
    }

    func testDuplicatesAreMerged() {
        let foods = [
            RecognizedFood(name: "Помидор", normalizedName: "tomato", category: .vegetables, confidence: 0.6),
            RecognizedFood(name: "Томаты", normalizedName: "tomato", category: .vegetables, confidence: 0.9),
        ]
        let merged = RealFoodRecognitionService.deduplicated(foods)
        XCTAssertEqual(merged.count, 1)
        XCTAssertEqual(merged[0].confidence, 0.9)
    }
}

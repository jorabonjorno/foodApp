import XCTest
@testable import FoodApp

final class IngredientNormalizerTests: XCTestCase {
    private let normalizer = IngredientNormalizer.shared

    func testTomatoSynonymsCollapseToOneKey() {
        for name in ["помидор", "Помидоры", "томат", "ТОМАТЫ", "tomato", "Tomatoes", "свежие помидоры"] {
            XCTAssertEqual(normalizer.normalize(name), "tomato", name)
        }
    }

    func testChickenBreastVariants() {
        for name in ["куриная грудка", "Грудка куриная", "chicken breast"] {
            XCTAssertEqual(normalizer.normalize(name), "chicken_breast", name)
        }
        XCTAssertEqual(normalizer.normalize("куриное филе"), "chicken")
    }

    func testYoAndPunctuationAreIgnored() {
        XCTAssertEqual(normalizer.normalize("Свёкла!"), "beetroot")
        XCTAssertEqual(normalizer.normalize("  яйца,  "), "egg")
        XCTAssertEqual(normalizer.normalize("Молоко 3,2%"), "milk")
    }

    func testUnknownProductGetsStableKey() {
        let key = normalizer.normalize("Киноа")
        XCTAssertFalse(key.isEmpty)
        XCTAssertEqual(key, normalizer.normalize("киноа"))
    }

    func testSuggestedKeyFromAIIsTrustedOnlyWhenKnown() {
        XCTAssertEqual(normalizer.normalize(name: "Томаты черри", suggestedKey: "cherry_tomato"), "cherry_tomato")
        XCTAssertEqual(normalizer.normalize(name: "Помидор", suggestedKey: "weird_key_123"), "tomato")
    }

    func testHierarchyMatching() {
        XCTAssertTrue(normalizer.isSameFood("chicken_breast", "chicken"))
        XCTAssertTrue(normalizer.isSameFood("chicken", "chicken_thigh"))
        XCTAssertTrue(normalizer.isSameFood("parmesan", "cheese"))
        XCTAssertFalse(normalizer.isSameFood("tomato", "cucumber"))
    }
}

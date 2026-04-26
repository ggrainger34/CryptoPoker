// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

import "remix_tests.sol";
import "../../contracts/PokerGame.sol";

// Note: Generative AI was used in the generation of these test cases
// Test cases for detecting hands
contract HandDetectionTest {
    Evaluation eval;

    function beforeAll() public {
        eval = new Evaluation();
    }

    // Test: Detect a pair (two 2s: 2s and 2h)
    function testDetectsPair() public {
        uint8[5] memory hand = [uint8(0), 13, 2, 3, 4]; // 2s, 2h, 4s, 5s, 6s
        Assert.equal(eval.isPair(hand), true, "Should detect a pair");
    }

    // Test: High card is not a pair
    function testHighCardIsNotPair() public {
        uint8[5] memory hand = [uint8(0), 14, 2, 3, 4]; // 2s, 3h, 4s, 5s, 6s
        Assert.equal(eval.isPair(hand), false, "High card should not be a pair");
    }

    // Test: Detect two pair (two 2s and two 3s)
    function testDetectsTwoPair() public {
        uint8[5] memory hand = [uint8(0), 13, 1, 14, 4]; // 2s, 2h, 3s, 3h, 6s
        Assert.equal(eval.isTwoPair(hand), true, "Should detect two pair");
    }

    // Test: Single pair is not two pair
    function testPairIsNotTwoPair() public {
        uint8[5] memory hand = [uint8(0), 13, 2, 3, 4]; // 2s, 2h, 4s, 5s, 6s
        Assert.equal(eval.isTwoPair(hand), false, "Single pair should not be two pair");
    }

    // Test: Detect three of a kind (three 2s: 2s, 2h, 2d)
    function testDetectsThreeOfAKind() public {
        uint8[5] memory hand = [uint8(0), 13, 26, 3, 4]; // 2s, 2h, 2d, 5s, 6s
        Assert.equal(eval.isThreeOfAKind(hand), true, "Should detect three of a kind");
    }

    // Test: Pair is not three of a kind
    function testPairIsNotThreeOfAKind() public {
        uint8[5] memory hand = [uint8(0), 13, 2, 3, 4]; // 2s, 2h, 4s, 5s, 6s
        Assert.equal(eval.isThreeOfAKind(hand), false, "Pair should not be three of a kind");
    }

    // Test: Detect four of a kind (four 2s: 2s, 2h, 2d, 2c)
    function testDetectsFourOfAKind() public {
        uint8[5] memory hand = [uint8(0), 13, 26, 39, 4]; // 2s, 2h, 2d, 2c, 6s
        Assert.equal(eval.isFourOfAKind(hand), true, "Should detect four of a kind");
    }

    // Test: Three of a kind is not four of a kind
    function testThreeOfAKindIsNotFourOfAKind() public {
        uint8[5] memory hand = [uint8(0), 13, 26, 3, 4]; // 2s, 2h, 2d, 5s, 6s
        Assert.equal(eval.isFourOfAKind(hand), false, "Three of a kind should not be four of a kind");
    }

    // Test: Detect flush (all spades: 2s, 3s, 4s, 5s, 7s)
    function testDetectsFlush() public {
        uint8[5] memory hand = [uint8(0), 1, 2, 3, 5]; // 2s, 3s, 4s, 5s, 7s
        Assert.equal(eval.isFlush(hand), true, "Should detect a flush");
    }

    // Test: Mixed suits is not a flush
    function testMixedSuitsNotFlush() public {
        uint8[5] memory hand = [uint8(0), 14, 2, 3, 4]; // 2s, 3h, 4s, 5s, 6s
        Assert.equal(eval.isFlush(hand), false, "Mixed suits should not be a flush");
    }

    // Test: Detect straight (2, 3, 4, 5, 6 in mixed suits)
    function testDetectsStraight() public {
        uint8[5] memory hand = [uint8(0), 14, 28, 42, 4]; // 2s, 3h, 4d, 5c, 6s
        Assert.equal(eval.isStraight(hand), true, "Should detect a straight");
    }

    // Test: Non-consecutive cards are not a straight
    function testNonConsecutiveNotStraight() public {
        uint8[5] memory hand = [uint8(0), 14, 28, 42, 5]; // 2s, 3h, 4d, 5c, 7s
        Assert.equal(eval.isStraight(hand), false, "Non-consecutive cards should not be a straight");
    }

    // Test: Detect wheel straight (A, 2, 3, 4, 5)
    function testDetectsWheelStraight() public {
        uint8[5] memory hand = [uint8(12), 0, 14, 28, 42]; // As, 2s, 3h, 4d, 5c
        Assert.equal(eval.isStraight(hand), true, "Should detect wheel straight (A-2-3-4-5)");
    }

    // Test: Detect broadway straight (T, J, Q, K, A)
    function testDetectsBroadwayStraight() public {
        uint8[5] memory hand = [uint8(8), 22, 36, 50, 12]; // Ts, Jh, Qd, Kc, As
        Assert.equal(eval.isStraight(hand), true, "Should detect broadway straight (T-J-Q-K-A)");
    }

    // Test: Detect full house (three 2s and two 3s)
    function testDetectsFullHouse() public {
        uint8[5] memory hand = [uint8(0), 13, 26, 1, 14]; // 2s, 2h, 2d, 3s, 3h
        Assert.equal(eval.isFullHouse(hand), true, "Should detect a full house");
    }

    // Test: Three of a kind without a pair is not full house
    function testThreeOfAKindNotFullHouse() public {
        uint8[5] memory hand = [uint8(0), 13, 26, 3, 4]; // 2s, 2h, 2d, 5s, 6s
        Assert.equal(eval.isFullHouse(hand), false, "Three of a kind without pair should not be full house");
    }

    // Test: Detect straight flush (2s, 3s, 4s, 5s, 6s)
    function testDetectsStraightFlush() public {
        uint8[5] memory hand = [uint8(0), 1, 2, 3, 4]; // 2s, 3s, 4s, 5s, 6s
        Score memory score = eval.evaluateFiveCards(hand);
        Assert.equal(score.handClass, 8, "Should detect a straight flush (class 8)");
    }
}
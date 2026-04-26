// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

import "remix_tests.sol";
import "../../contracts/PokerGame.sol";


// Note: Generative AI was used in the generation of these test cases
// Test cases that assign the hands to different classes
contract HandClassificationTest {
    Evaluation eval;

    function beforeAll() public {
        eval = new Evaluation();
    }

    // High card: 2s, 3h, 4d, 6c, Ts - no pair, no straight, no flush
    function testHighCardIsClass0() public {
        uint8[5] memory hand = [uint8(0), 14, 29, 44, 8];
        Score memory score = eval.evaluateFiveCards(hand);
        Assert.equal(score.handClass, 0, "High card should be class 0");
    }

    // Pair: 2s, 2h, 4s, 5s, 7s
    function testPairIsClass1() public {
        uint8[5] memory hand = [uint8(0), 13, 2, 3, 5];
        Score memory score = eval.evaluateFiveCards(hand);
        Assert.equal(score.handClass, 1, "Pair should be class 1");
    }

    // Two pair: 2s, 2h, 3s, 3h, 6s
    function testTwoPairIsClass2() public {
        uint8[5] memory hand = [uint8(0), 13, 1, 14, 4];
        Score memory score = eval.evaluateFiveCards(hand);
        Assert.equal(score.handClass, 2, "Two pair should be class 2");
    }

    // Three of a kind: 2s, 2h, 2d, 5s, 6s
    function testThreeOfAKindIsClass3() public {
        uint8[5] memory hand = [uint8(0), 13, 26, 3, 4];
        Score memory score = eval.evaluateFiveCards(hand);
        Assert.equal(score.handClass, 3, "Three of a kind should be class 3");
    }

    // Straight: 2s, 3h, 4d, 5c, 6s
    function testStraightIsClass4() public {
        uint8[5] memory hand = [uint8(0), 14, 28, 42, 4];
        Score memory score = eval.evaluateFiveCards(hand);
        Assert.equal(score.handClass, 4, "Straight should be class 4");
    }

    // Flush: 2s, 3s, 4s, 5s, 7s (all spades, not consecutive)
    function testFlushIsClass5() public {
        uint8[5] memory hand = [uint8(0), 1, 2, 3, 5];
        Score memory score = eval.evaluateFiveCards(hand);
        Assert.equal(score.handClass, 5, "Flush should be class 5");
    }

    // Full house: 2s, 2h, 2d, 3s, 3h
    function testFullHouseIsClass6() public {
        uint8[5] memory hand = [uint8(0), 13, 26, 1, 14];
        Score memory score = eval.evaluateFiveCards(hand);
        Assert.equal(score.handClass, 6, "Full house should be class 6");
    }

    // Four of a kind: 2s, 2h, 2d, 2c, 6s
    function testFourOfAKindIsClass7() public {
        uint8[5] memory hand = [uint8(0), 13, 26, 39, 4];
        Score memory score = eval.evaluateFiveCards(hand);
        Assert.equal(score.handClass, 7, "Four of a kind should be class 7");
    }

    // Straight flush: 2s, 3s, 4s, 5s, 6s
    function testStraightFlushIsClass8() public {
        uint8[5] memory hand = [uint8(0), 1, 2, 3, 4];
        Score memory score = eval.evaluateFiveCards(hand);
        Assert.equal(score.handClass, 8, "Straight flush should be class 8");
    }

    // Wheel straight: As, 2s, 3h, 4d, 5c - should be class 4 not class 0
    function testWheelStraightIsClass4() public {
        uint8[5] memory hand = [uint8(12), 0, 14, 28, 42];
        Score memory score = eval.evaluateFiveCards(hand);
        Assert.equal(score.handClass, 4, "Wheel straight should be class 4");
    }

    // Broadway straight: Ts, Jh, Qd, Kc, As - should be class 4
    function testBroadwayStraightIsClass4() public {
        uint8[5] memory hand = [uint8(8), 22, 36, 50, 12];
        Score memory score = eval.evaluateFiveCards(hand);
        Assert.equal(score.handClass, 4, "Broadway straight should be class 4");
    }

    // Straight flush should not be classified as just a flush
    function testStraightFlushNotClassifiedAsFlush() public {
        uint8[5] memory hand = [uint8(0), 1, 2, 3, 4];
        Score memory score = eval.evaluateFiveCards(hand);
        Assert.notEqual(score.handClass, 5, "Straight flush should not be classified as flush");
    }

    // Straight flush should not be classified as just a straight
    function testStraightFlushNotClassifiedAsStraight() public {
        uint8[5] memory hand = [uint8(0), 1, 2, 3, 4];
        Score memory score = eval.evaluateFiveCards(hand);
        Assert.notEqual(score.handClass, 4, "Straight flush should not be classified as straight");
    }
}
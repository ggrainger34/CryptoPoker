// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

import "remix_tests.sol";
import "../../contracts/PokerGame.sol";

// Note: Generative AI was used in the generation of these test cases
contract HandComparisonTest {
    Evaluation eval;

    function beforeAll() public {
        eval = new Evaluation();
    }
    
    // Pair beats high card
    function testPairBeatsHighCard() public {
        uint8[5] memory pair = [uint8(0), 13, 2, 3, 5];       // 2s, 2h, 4s, 5s, 7s
        uint8[5] memory highCard = [uint8(0), 14, 29, 44, 8]; // 2s, 3h, 4d, 6c, Ts
        Score memory pairScore = eval.evaluateFiveCards(pair);
        Score memory highScore = eval.evaluateFiveCards(highCard);
        Assert.equal(eval.beats(pairScore, highScore), true, "Pair should beat high card");
    }

    // Two pair beats pair
    function testTwoPairBeatsPair() public {
        uint8[5] memory twoPair = [uint8(0), 13, 1, 14, 4]; // 2s, 2h, 3s, 3h, 6s
        uint8[5] memory pair = [uint8(0), 13, 2, 3, 5];      // 2s, 2h, 4s, 5s, 7s
        Score memory tpScore = eval.evaluateFiveCards(twoPair);
        Score memory pScore = eval.evaluateFiveCards(pair);
        Assert.equal(eval.beats(tpScore, pScore), true, "Two pair should beat pair");
    }

    // Three of a kind beats two pair
    function testThreeOfAKindBeatsTwoPair() public {
        uint8[5] memory trips = [uint8(0), 13, 26, 3, 4];   // 2s, 2h, 2d, 5s, 6s
        uint8[5] memory twoPair = [uint8(0), 13, 1, 14, 4]; // 2s, 2h, 3s, 3h, 6s
        Score memory tripsScore = eval.evaluateFiveCards(trips);
        Score memory tpScore = eval.evaluateFiveCards(twoPair);
        Assert.equal(eval.beats(tripsScore, tpScore), true, "Three of a kind should beat two pair");
    }

    // Straight beats three of a kind
    function testStraightBeatsThreeOfAKind() public {
        uint8[5] memory straight = [uint8(0), 14, 28, 42, 4]; // 2s, 3h, 4d, 5c, 6s
        uint8[5] memory trips = [uint8(0), 13, 26, 3, 4];     // 2s, 2h, 2d, 5s, 6s
        Score memory strScore = eval.evaluateFiveCards(straight);
        Score memory tripsScore = eval.evaluateFiveCards(trips);
        Assert.equal(eval.beats(strScore, tripsScore), true, "Straight should beat three of a kind");
    }

    // Flush beats straight
    function testFlushBeatsStraight() public {
        uint8[5] memory flush = [uint8(0), 1, 2, 3, 5];        // 2s, 3s, 4s, 5s, 7s
        uint8[5] memory straight = [uint8(0), 14, 28, 42, 4];  // 2s, 3h, 4d, 5c, 6s
        Score memory flScore = eval.evaluateFiveCards(flush);
        Score memory strScore = eval.evaluateFiveCards(straight);
        Assert.equal(eval.beats(flScore, strScore), true, "Flush should beat straight");
    }

    // Full house beats flush
    function testFullHouseBeatsFlush() public {
        uint8[5] memory fullHouse = [uint8(0), 13, 26, 1, 14]; // 2s, 2h, 2d, 3s, 3h
        uint8[5] memory flush = [uint8(0), 1, 2, 3, 5];         // 2s, 3s, 4s, 5s, 7s
        Score memory fhScore = eval.evaluateFiveCards(fullHouse);
        Score memory flScore = eval.evaluateFiveCards(flush);
        Assert.equal(eval.beats(fhScore, flScore), true, "Full house should beat flush");
    }

    // Four of a kind beats full house
    function testFourOfAKindBeatsFullHouse() public {
        uint8[5] memory quads = [uint8(0), 13, 26, 39, 4];     // 2s, 2h, 2d, 2c, 6s
        uint8[5] memory fullHouse = [uint8(0), 13, 26, 1, 14]; // 2s, 2h, 2d, 3s, 3h
        Score memory qScore = eval.evaluateFiveCards(quads);
        Score memory fhScore = eval.evaluateFiveCards(fullHouse);
        Assert.equal(eval.beats(qScore, fhScore), true, "Four of a kind should beat full house");
    }

    // Straight flush beats four of a kind
    function testStraightFlushBeatsFourOfAKind() public {
        uint8[5] memory sf = [uint8(0), 1, 2, 3, 4];       // 2s, 3s, 4s, 5s, 6s
        uint8[5] memory quads = [uint8(0), 13, 26, 39, 4]; // 2s, 2h, 2d, 2c, 6s
        Score memory sfScore = eval.evaluateFiveCards(sf);
        Score memory qScore = eval.evaluateFiveCards(quads);
        Assert.equal(eval.beats(sfScore, qScore), true, "Straight flush should beat four of a kind");
    }

    // High card does not beat pair
    function testHighCardDoesNotBeatPair() public {
        uint8[5] memory highCard = [uint8(0), 14, 29, 44, 8]; // 2s, 3h, 4d, 6c, Ts
        uint8[5] memory pair = [uint8(0), 13, 2, 3, 5];       // 2s, 2h, 4s, 5s, 7s
        Score memory highScore = eval.evaluateFiveCards(highCard);
        Score memory pairScore = eval.evaluateFiveCards(pair);
        Assert.equal(eval.beats(highScore, pairScore), false, "High card should not beat pair");
    }

    // Straight does not beat flush
    function testStraightDoesNotBeatFlush() public {
        uint8[5] memory straight = [uint8(0), 14, 28, 42, 4]; // 2s, 3h, 4d, 5c, 6s
        uint8[5] memory flush = [uint8(0), 1, 2, 3, 5];        // 2s, 3s, 4s, 5s, 7s
        Score memory strScore = eval.evaluateFiveCards(straight);
        Score memory flScore = eval.evaluateFiveCards(flush);
        Assert.equal(eval.beats(strScore, flScore), false, "Straight should not beat flush");
    }

    // Higher pair beats lower pair
    function testHigherPairBeatsLowerPair() public {
        uint8[5] memory acePair = [uint8(12), 25, 2, 3, 5];  // As, Ah, 4s, 5s, 7s
        uint8[5] memory kingPair = [uint8(11), 24, 2, 3, 5]; // Ks, Kh, 4s, 5s, 7s
        Score memory aceScore = eval.evaluateFiveCards(acePair);
        Score memory kingScore = eval.evaluateFiveCards(kingPair);
        Assert.equal(eval.beats(aceScore, kingScore), true, "Pair of aces should beat pair of kings");
    }

    // Lower pair does not beat higher pair
    function testLowerPairDoesNotBeatHigherPair() public {
        uint8[5] memory acePair = [uint8(12), 25, 2, 3, 5];  // As, Ah, 4s, 5s, 7s
        uint8[5] memory kingPair = [uint8(11), 24, 2, 3, 5]; // Ks, Kh, 4s, 5s, 7s
        Score memory aceScore = eval.evaluateFiveCards(acePair);
        Score memory kingScore = eval.evaluateFiveCards(kingPair);
        Assert.equal(eval.beats(kingScore, aceScore), false, "Pair of kings should not beat pair of aces");
    }

    // Higher kicker wins with same pair
    function testHigherKickerWins() public {
        uint8[5] memory highKicker = [uint8(0), 13, 2, 3, 12]; // 2s, 2h, 4s, 5s, As
        uint8[5] memory lowKicker = [uint8(0), 13, 2, 3, 5];   // 2s, 2h, 4s, 5s, 7s
        Score memory highScore = eval.evaluateFiveCards(highKicker);
        Score memory lowScore = eval.evaluateFiveCards(lowKicker);
        Assert.equal(eval.beats(highScore, lowScore), true, "Higher kicker should win");
    }

    // Lower kicker does not win
    function testLowerKickerDoesNotWin() public {
        uint8[5] memory highKicker = [uint8(0), 13, 2, 3, 12]; // 2s, 2h, 4s, 5s, As
        uint8[5] memory lowKicker = [uint8(0), 13, 2, 3, 5];   // 2s, 2h, 4s, 5s, 7s
        Score memory highScore = eval.evaluateFiveCards(highKicker);
        Score memory lowScore = eval.evaluateFiveCards(lowKicker);
        Assert.equal(eval.beats(lowScore, highScore), false, "Lower kicker should not win");
    }

    // Higher flush beats lower flush
    function testHigherFlushBeatsLowerFlush() public {
        uint8[5] memory highFlush = [uint8(0), 1, 2, 3, 12]; // 2s, 3s, 4s, 5s, As
        uint8[5] memory lowFlush = [uint8(0), 1, 2, 3, 5];   // 2s, 3s, 4s, 5s, 7s
        Score memory highScore = eval.evaluateFiveCards(highFlush);
        Score memory lowScore = eval.evaluateFiveCards(lowFlush);
        Assert.equal(eval.beats(highScore, lowScore), true, "Higher flush should beat lower flush");
    }

    // Same hand does not beat itself
    function testSameHandDoesNotBeatItself() public {
        uint8[5] memory hand = [uint8(0), 13, 2, 3, 5]; // 2s, 2h, 4s, 5s, 7s
        Score memory score1 = eval.evaluateFiveCards(hand);
        Score memory score2 = eval.evaluateFiveCards(hand);
        Assert.equal(eval.beats(score1, score2), false, "Same hand should not beat itself");
    }
}
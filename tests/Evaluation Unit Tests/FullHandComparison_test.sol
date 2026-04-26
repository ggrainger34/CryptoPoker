// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

import "remix_tests.sol";
import "../../contracts/PokerGame.sol";

// Note: Generative AI was used in the generation of these test cases
contract FullEvaluationTest {
    Evaluation eval;

    function beforeAll() public {
        eval = new Evaluation();
    }

    // ========== Best hand selection from 7 cards ==========

    // Royal flush found from 7 cards: As, Ks + Qs, Js, Ts, 2h, 3d
    function testFindsRoyalFlushFromSeven() public {
        uint[] memory hole = new uint[](2);
        uint[] memory community = new uint[](5);

        hole[0] = 12; // As
        hole[1] = 11; // Ks

        community[0] = 10; // Qs
        community[1] = 9;  // Js
        community[2] = 8;  // Ts
        community[3] = 13; // 2h
        community[4] = 27; // 2d

        Score memory score = eval.evaluateHand(hole, community);
        Assert.equal(score.handClass, 8, "Should find straight flush from 7 cards");
    }

    // Flush found when hole cards contribute: 7s, 9s + 2s, 4s, 6s, Kh, Qd
    function testHoleCardsContributeToFlush() public {
        uint[] memory hole = new uint[](2);
        uint[] memory community = new uint[](5);

        hole[0] = 5; // 7s
        hole[1] = 7; // 9s

        community[0] = 0;  // 2s
        community[1] = 2;  // 4s
        community[2] = 4;  // 6s
        community[3] = 24; // Kh
        community[4] = 36; // Qd

        Score memory score = eval.evaluateHand(hole, community);
        Assert.equal(score.handClass, 5, "Should find flush using hole cards");
    }

    // Best hand is in community cards only: hole cards are junk
    function testBestHandFromCommunityOnly() public {
        uint[] memory hole = new uint[](2);
        uint[] memory community = new uint[](5);

        // Junk hole cards
        hole[0] = 0;  // 2s
        hole[1] = 14; // 3h

        // Community is a straight: 4d, 5c, 6s, 7h, 8d
        community[0] = 28; // 4d
        community[1] = 42; // 5c
        community[2] = 4;  // 6s
        community[3] = 18; // 7h
        community[4] = 32; // 8d

        Score memory score = eval.evaluateHand(hole, community);
        // Best 5 is 4-5-6-7-8 straight from community
        Assert.equal(score.handClass, 4, "Should find straight from community cards alone");
    }

    // Hole cards upgrade community pair to three of a kind
    function testHoleCardUpgradesPairToTrips() public {
        uint[] memory hole = new uint[](2);
        uint[] memory community = new uint[](5);

        hole[0] = 0;  // 2s
        hole[1] = 8;  // Ts

        // Community has two 2s plus junk
        community[0] = 13; // 2h
        community[1] = 26; // 2d
        community[2] = 3;  // 5s
        community[3] = 18; // 7h
        community[4] = 36; // Qd

        Score memory score = eval.evaluateHand(hole, community);
        Assert.equal(score.handClass, 3, "Hole card should upgrade pair to three of a kind");
    }

    // Full house found from trips in community and pair in hole
    function testFullHouseFromHoleAndCommunity() public {
        uint[] memory hole = new uint[](2);
        uint[] memory community = new uint[](5);

        // Hole: pair of Kings
        hole[0] = 11; // Ks
        hole[1] = 24; // Kh

        // Community: three 5s plus junk
        community[0] = 3;  // 5s
        community[1] = 16; // 5h
        community[2] = 29; // 5d
        community[3] = 0;  // 2s
        community[4] = 14; // 3h

        Score memory score = eval.evaluateHand(hole, community);
        Assert.equal(score.handClass, 6, "Should find full house from hole pair and community trips");
    }

    // Four of a kind found across hole and community
    function testFourOfAKindAcrossHoleAndCommunity() public {
        uint[] memory hole = new uint[](2);
        uint[] memory community = new uint[](5);

        // Hole: two Aces
        hole[0] = 12; // As
        hole[1] = 25; // Ah

        // Community: two more Aces plus junk
        community[0] = 38; // Ad
        community[1] = 51; // Ac
        community[2] = 0;  // 2s
        community[3] = 14; // 3h
        community[4] = 28; // 4d

        Score memory score = eval.evaluateHand(hole, community);
        Assert.equal(score.handClass, 7, "Should find four of a kind across hole and community");
    }

    // Higher hand selected when multiple hands are possible
    function testSelectsHigherOfTwoPossibleHands() public {
        uint[] memory hole = new uint[](2);
        uint[] memory community = new uint[](5);

        // Hole: As, Ks (both spades)
        hole[0] = 12; // As
        hole[1] = 11; // Ks

        // Community: Qs, 3s, 5s, 2h, 4d
        // Possible: spade flush (As, Ks, Qs, 3s, 5s) or straight (A-2-3-4-5)
        // Flush is class 5, straight is class 4 - should pick flush
        community[0] = 10; // Qs
        community[1] = 1;  // 3s
        community[2] = 3;  // 5s
        community[3] = 13; // 2h
        community[4] = 28; // 4d

        Score memory score = eval.evaluateHand(hole, community);
        Assert.equal(score.handClass, 5, "Should select flush over straight");
    }

    // Two pair is best hand when no better hand exists
    function testTwoPairWhenNoBetterHand() public {
        uint[] memory hole = new uint[](2);
        uint[] memory community = new uint[](5);

        // Hole: pair of Aces
        hole[0] = 12; // As
        hole[1] = 25; // Ah

        // Community: pair of Kings plus junk
        community[0] = 11; // Ks
        community[1] = 24; // Kh
        community[2] = 3;  // 5s
        community[3] = 18; // 7h
        community[4] = 32; // 8d

        Score memory score = eval.evaluateHand(hole, community);
        Assert.equal(score.handClass, 2, "Should find two pair from hole aces and community kings");
    }
}
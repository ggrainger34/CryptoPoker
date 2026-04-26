// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

import "remix_tests.sol";
import "../../contracts/PokerGame.sol";

// Note: Generative AI was used in the generation of these test cases
contract DeckTest {
    Deck deck;

    function beforeAll() public {
        deck = new Deck();
    }

    // First card in deck is 2 of spades
    function testFirstCardIs2s() public {
        Assert.equal(deck.lookupCard(0), "2s", "Card 0 should be 2s");
    }

    // Last card in deck is Ace of clubs
    function testLastCardIsAc() public {
        Assert.equal(deck.lookupCard(51), "Ac", "Card 51 should be Ac");
    }

    // Ace of spades
    function testAceOfSpades() public {
        Assert.equal(deck.lookupCard(12), "As", "Card 12 should be As");
    }

    // ========== Suit boundary tests ==========

    // First heart (index 13) is 2h
    function testFirstHeart() public {
        Assert.equal(deck.lookupCard(13), "2h", "Card 13 should be 2h");
    }

    // First diamond (index 26) is 2d
    function testFirstDiamond() public {
        Assert.equal(deck.lookupCard(26), "2d", "Card 26 should be 2d");
    }

    // First club (index 39) is 2c
    function testFirstClub() public {
        Assert.equal(deck.lookupCard(39), "2c", "Card 39 should be 2c");
    }

    // Last spade (index 12) is As
    function testLastSpade() public {
        Assert.equal(deck.lookupCard(12), "As", "Card 12 should be As");
    }

    // Last heart (index 25) is Ah
    function testLastHeart() public {
        Assert.equal(deck.lookupCard(25), "Ah", "Card 25 should be Ah");
    }

    // Last diamond (index 38) is Ad
    function testLastDiamond() public {
        Assert.equal(deck.lookupCard(38), "Ad", "Card 38 should be Ad");
    }

    // Ten of spades
    function testTenOfSpades() public {
        Assert.equal(deck.lookupCard(8), "Ts", "Card 8 should be Ts");
    }

    // Jack of hearts
    function testJackOfHearts() public {
        Assert.equal(deck.lookupCard(22), "Jh", "Card 22 should be Jh");
    }

    // Queen of diamonds
    function testQueenOfDiamonds() public {
        Assert.equal(deck.lookupCard(36), "Qd", "Card 36 should be Qd");
    }

    // King of clubs
    function testKingOfClubs() public {
        Assert.equal(deck.lookupCard(50), "Kc", "Card 50 should be Kc");
    }

    // ========== cardToNumber reverse lookup tests ==========

    // 2 of spades is card 0
    function testCardToNumber2s() public {
        Assert.equal(uint(deck.cardToNumber(0, 0)), 0, "2s should be card 0");
    }

    // Ace of clubs is card 51
    function testCardToNumberAc() public {
        Assert.equal(uint(deck.cardToNumber(3, 12)), 51, "Ac should be card 51");
    }

    // Queen of clubs is card 49
    function testCardToNumberQc() public {
        Assert.equal(uint(deck.cardToNumber(3, 10)), 49, "Qc should be card 49");
    }

    // lookupCard and cardToNumber are consistent
    function testLookupAndReverseConsistent() public {
        // Card 49 should be Qc
        uint8 cardNum = deck.cardToNumber(3, 10);
        Assert.equal(deck.lookupCard(cardNum), "Qc", "cardToNumber and lookupCard should be consistent");
    }

    // All four suits of the same rank produce different results
    function testAllFourSuitsOfAce() public {
        string memory aceSpades = deck.lookupCard(12);
        string memory aceHearts = deck.lookupCard(25);
        string memory aceDiamonds = deck.lookupCard(38);
        string memory aceClubs = deck.lookupCard(51);

        Assert.equal(aceSpades, "As", "Should be As");
        Assert.equal(aceHearts, "Ah", "Should be Ah");
        Assert.equal(aceDiamonds, "Ad", "Should be Ad");
        Assert.equal(aceClubs, "Ac", "Should be Ac");
    }
}

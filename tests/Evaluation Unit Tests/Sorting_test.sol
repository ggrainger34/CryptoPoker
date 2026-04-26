// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

import "remix_tests.sol";
import "../../contracts/PokerGame.sol";

// Note: Generative AI was used in the generation of these test cases
// Test cases for the sorting function
contract SortingTest {
    Evaluation eval;

    function beforeAll() public {
        eval = new Evaluation();
    }

    // Basic unsorted array
    function testSortsUnsortedArray() public {
        uint8[5] memory unsorted = [uint8(10), 3, 7, 1, 12];
        uint8[5] memory sorted = eval.sort(unsorted);
        Assert.equal(sorted[0], 1, "First element should be 1");
        Assert.equal(sorted[1], 3, "Second element should be 3");
        Assert.equal(sorted[2], 7, "Third element should be 7");
        Assert.equal(sorted[3], 10, "Fourth element should be 10");
        Assert.equal(sorted[4], 12, "Fifth element should be 12");
    }

    // Already sorted stays sorted
    function testAlreadySortedUnchanged() public {
        uint8[5] memory already = [uint8(1), 2, 3, 4, 5];
        uint8[5] memory sorted = eval.sort(already);
        Assert.equal(sorted[0], 1, "First should remain 1");
        Assert.equal(sorted[1], 2, "Second should remain 2");
        Assert.equal(sorted[2], 3, "Third should remain 3");
        Assert.equal(sorted[3], 4, "Fourth should remain 4");
        Assert.equal(sorted[4], 5, "Fifth should remain 5");
    }

    // Reverse order
    function testSortsReverseOrder() public {
        uint8[5] memory reversed = [uint8(12), 10, 7, 3, 1];
        uint8[5] memory sorted = eval.sort(reversed);
        Assert.equal(sorted[0], 1, "First should be 1");
        Assert.equal(sorted[4], 12, "Last should be 12");
    }

    // All same values
    function testAllSameValues() public {
        uint8[5] memory same = [uint8(5), 5, 5, 5, 5];
        uint8[5] memory sorted = eval.sort(same);
        Assert.equal(sorted[0], 5, "All elements should be 5");
        Assert.equal(sorted[4], 5, "All elements should be 5");
    }

    // Minimum and maximum card ranks
    function testMinAndMaxRanks() public {
        uint8[5] memory hand = [uint8(12), 0, 6, 11, 1];
        uint8[5] memory sorted = eval.sort(hand);
        Assert.equal(sorted[0], 0, "Lowest rank should be first");
        Assert.equal(sorted[4], 12, "Highest rank should be last");
    }

    // Two elements swapped
    function testTwoElementsSwapped() public {
        uint8[5] memory hand = [uint8(2), 1, 3, 4, 5];
        uint8[5] memory sorted = eval.sort(hand);
        Assert.equal(sorted[0], 1, "Should swap first two elements");
        Assert.equal(sorted[1], 2, "Should swap first two elements");
    }

    // Only last element out of place
    function testLastElementOutOfPlace() public {
        uint8[5] memory hand = [uint8(3), 5, 7, 9, 1];
        uint8[5] memory sorted = eval.sort(hand);
        Assert.equal(sorted[0], 1, "1 should move to front");
        Assert.equal(sorted[1], 3, "3 should be second");
        Assert.equal(sorted[4], 9, "9 should remain last");
    }

    // Duplicate values maintain count
    function testDuplicateValues() public {
        uint8[5] memory hand = [uint8(3), 7, 3, 7, 1];
        uint8[5] memory sorted = eval.sort(hand);
        Assert.equal(sorted[0], 1, "First should be 1");
        Assert.equal(sorted[1], 3, "Second should be 3");
        Assert.equal(sorted[2], 3, "Third should be 3");
        Assert.equal(sorted[3], 7, "Fourth should be 7");
        Assert.equal(sorted[4], 7, "Fifth should be 7");
    }

    // Adjacent values
    function testAdjacentValues() public {
        uint8[5] memory hand = [uint8(5), 4, 3, 2, 1];
        uint8[5] memory sorted = eval.sort(hand);
        Assert.equal(sorted[0], 1, "Should sort consecutive descending");
        Assert.equal(sorted[1], 2, "Should sort consecutive descending");
        Assert.equal(sorted[2], 3, "Should sort consecutive descending");
        Assert.equal(sorted[3], 4, "Should sort consecutive descending");
        Assert.equal(sorted[4], 5, "Should sort consecutive descending");
    }
}
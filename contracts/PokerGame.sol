//SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

// Score struct for evaluation
struct Score {
    uint handClass;
    uint8[5] sortedHand;
}

contract PokerGame{
    struct Player {
        address playerAddress; // Etherum Address
        uint256 currentPlayerBet;
        uint256[] privateCards; // Private cards stored as two integers (0-51 to represent cards in the deck)
        bool hasFolded;
        bool hasActed; // Have they acted in the round
        bool hasCalled; // Have they called the current bet
    }

    // For now just use two players
    uint private constant MAX_PLAYERS = 2;

    // Array of players
    Player[] public players;
    mapping(address => bool) private isPlayer; // Lookup to see if an address is playing
    mapping(address => uint256) private playerIndex;
    
    // Count how many players are still active in a hand
    uint private activePlayerCount;

    // Game State
    enum GamePhase {Waiting, PreFlop, Flop, Turn, River, Showdown}
    bool private gameActive;
    GamePhase private currentPhase;

    // Money for each round
    uint256 public pot;
    uint256 public currentCallSize;
    mapping(address => uint) public playerBalances;

    // Cards
    uint256[] private communityCards;
    mapping(address => uint[]) private playerHands;
    mapping(uint => bool) private dealtCards; // Dealt cards to remove collisions
    uint private nonce; // Nonce used for card generation

    // Add a contact specifically for the deck of cards
    Deck private deck;

    // Add a contract for evaluation
    Evaluation private evaluation;

    // Card lookup
    mapping(uint => string) private suitLookup;
    mapping(uint => string) private rankLookup;

    // Turn Management
    uint private currentPlayerTurnIndex;
    uint private playerWinnerIndex;

    // Variables required to have a claim timeout
    uint256 private lastActionTimestamp;
    uint256 private constant TIMEOUT_DURATION = 600; // 10 minutes

    constructor() {
        currentPhase = GamePhase.Waiting;

        gameActive = false;

        deck = new Deck();
        evaluation = new Evaluation();
    }

    function joinGame() internal {
        // Cannot join whilst game in progress
        require(currentPhase == GamePhase.Waiting, "Game Already in Progress.");

        // Cannot join if game is full
        require(players.length < MAX_PLAYERS, "Game is full.");

        // Cannot join a game twice
        require(!isPlayer[msg.sender], "You have already joined this game.");

        players.push(Player({
            playerAddress: msg.sender,
            currentPlayerBet: 0,
            privateCards: new uint256[](0),
            hasFolded: false,
            hasActed: false,
            hasCalled: false
        }));

        playerBalances[msg.sender] += msg.value;

        // Add the player index to the list
        playerIndex[msg.sender] = players.length - 1;
        isPlayer[msg.sender] = true;

        // Once enough players have joined, begin the game
        if (players.length == MAX_PLAYERS) {
            moveOntoNextRound();
        }
    }

    // Set to public for testing purposes
    function moveOntoNextRound() private {
        if (currentPhase == GamePhase.Waiting){
            // Begin the preflop phase of the game, give every player two cards and a betting round begins
            activePlayerCount = players.length;
            currentPhase = GamePhase.PreFlop;
            dealPlayerCards();
            beginBettingRound();
        }
        else if (currentPhase == GamePhase.PreFlop){
            // Begin the flop phase, three community cards are revealed and a betting round beings
            currentPhase = GamePhase.Flop;
            revealFlop();
            beginBettingRound();
        }
        else if (currentPhase == GamePhase.Flop){
            // Begin the turn phase, another community card is revealed and betting round begins
            currentPhase = GamePhase.Turn;
            revealTurn();
            beginBettingRound();
        }
        else if (currentPhase == GamePhase.Turn){
            // Begin the river phase, the last community card is revealed and final round of betting begins
            currentPhase = GamePhase.River;
            revealRiver();
            beginBettingRound();
        }
        else if (currentPhase == GamePhase.River){
            // Begin showdown (later add that the player whose turn it is needs to reveal their cards)
            currentPhase = GamePhase.Showdown;
        }
        else if (currentPhase == GamePhase.Showdown){
            // End of game, payout the winner and begin again
            playerWinnerIndex = determineWinner();

            // Payout the winner
            payoutWinner(players[playerWinnerIndex].playerAddress);

            // Reset game for next hand
            resetGame();
        }
    }

    // Assign each player in the game their cards
    function dealPlayerCards() private {
        uint currentPlayerCount = players.length;

        for (uint i = 0; i < currentPlayerCount; i++){
            players[i].privateCards = [getRandomCard(), getRandomCard()];
        }
    }

    // Reveal the flop card
    function revealFlop() private {
        communityCards.push(getRandomCard());
        communityCards.push(getRandomCard());
        communityCards.push(getRandomCard());
    }

    // Reveal the turn card
    function revealTurn() private {
        communityCards.push(getRandomCard());
    }

    // Reveal the river card
    function revealRiver() private { 
        communityCards.push(getRandomCard());
    }

    // Getter function for playerCount
    function getPlayerCount() public view returns (uint) {
        return players.length;
    }

    // Return the cards of the player
    function getMyCards() public view returns (uint256[] memory){
        // Require that the cards belong to the player
        require(isPlayer[msg.sender], "You are not in the game.");

        // Make sure that the game has started
        require(currentPhase != GamePhase.Waiting, "Cannot ask for cards before game start.");

        uint index = playerIndex[msg.sender];
        return players[index].privateCards;
    }

    // Getter function to fetch community cards
    function getCommunityCards() public view returns (uint256[] memory){
        return communityCards;
    }

    // Perform a betting round
    function beginBettingRound() private {
        currentCallSize = 0; // Reset the call size
        currentPlayerTurnIndex = 0; // It's now small blind's turn to act

        lastActionTimestamp = block.timestamp; // Note the time that the turn began, so if a player takes too long another player can skip

        // Reset all player bets
        for (uint i = 0; i < players.length; i++){
            players[i].currentPlayerBet = 0;
        }

        resetCallFlags(); // Reset all call flags as a new round begins
    }

    // Getter function to get the player's own place at the table
    function getPlayerIndex() public view returns (uint) {
        return playerIndex[msg.sender];
    }

    // Function to deposit money at the start of a game
    function depositMoney() external payable {
        // Cannot deposit money in the middle of a round
        require(currentPhase == GamePhase.Waiting, "Cannot deposit money in the middle of a round");

        // Automatically join game after depositing if not already playing
        if (!isPlayer[msg.sender]){
            joinGame(); // If joining game fails deposit money fails as well
        }

        // Convert the coin to balance
        playerBalances[msg.sender] += msg.value;
    }

    // Allows the money to be paid back to the user
    function withdrawMoney() external {
        uint256 amount = playerBalances[msg.sender];
        require(amount > 0, "No balance to withdraw");
        
        // Zero balance before sending to prevent reentrancy
        playerBalances[msg.sender] = 0;

        (bool success, ) = payable(msg.sender).call{value: getMyBalance()}("");
        require(success, "Transfer failed");
    }

    // Getter function for my balance
    function getMyBalance() public view returns (uint) {
        return playerBalances[msg.sender];
    }

    // Getter function for any player's balance
    function getPlayerBalance(address playerAddress) public view returns (uint){
        return playerBalances[playerAddress];
    }

    // Allow a player to raise if it is their turn
    function raise(uint amount) external {
        // Only allow if its the player's turn
        require(playerIndex[msg.sender] == currentPlayerTurnIndex, "It is not your turn to act");

        // Require that the player is able to raise this much
        require(playerBalances[msg.sender] > currentCallSize, "To raise you must put in more money than the call size");

        // Require that the amount bet is greater than the current call size
        require(amount > currentCallSize, "To raise you must put in more money than the call size");

        // Note the time that the turn began, so if a player takes too long another player can skip their turn
        lastActionTimestamp = block.timestamp;

        // Add an all in feature (To Do)

        // Deduct from player balance and add to pot
        playerBalances[msg.sender] -= amount;
        pot += amount;
        players[playerIndex[msg.sender]].currentPlayerBet += amount;
        currentCallSize = amount;

        // Everyone is now not matching the current bet for this round and therefore has to call
        resetCallFlags();

        // Since the player has raised they have met the call
        players[playerIndex[msg.sender]].hasCalled = true;

        // Find the next player who hasn't folded
        currentPlayerTurnIndex = getNextActiveIndex();

        if (isEndOfBettingRound()){
            moveOntoNextRound();
        }
    }

    // Allow a player to call if its their turn
    function call() external {
        // Only allow if its the player's turn
        require(playerIndex[msg.sender] == currentPlayerTurnIndex, "It is not your turn to act");

        // Require that the player has the money to call otherwise there has to be a side pot to do later
        require(playerBalances[msg.sender] > currentCallSize, "Incorrect call size");

        // Calculate amount needed to match the currentCallSize
        uint amountToCall = currentCallSize - players[currentPlayerTurnIndex].currentPlayerBet;

        // Note the time that the turn began, so if a player takes too long another player can skip
        lastActionTimestamp = block.timestamp;

        // Deduct from player balance and add to pot
        playerBalances[msg.sender] -= amountToCall;
        pot += amountToCall;
        players[playerIndex[msg.sender]].currentPlayerBet = currentCallSize;

        // The player has now called
        players[playerIndex[msg.sender]].hasCalled = true;

        // Increment the player counter as it is no longer their turn
        currentPlayerTurnIndex = getNextActiveIndex();

        if (isEndOfBettingRound()){
            moveOntoNextRound();
        }
    }

    // Allow a player to check if its their turn and no player has raised
    function check() external {
        require(playerIndex[msg.sender] == currentPlayerTurnIndex, "It is not your turn to act");

        require(currentCallSize == 0, "Cannot check when another player has raised");

        // Note the time that the turn began, so if a player takes too long another player can skip
        lastActionTimestamp = block.timestamp;

        players[playerIndex[msg.sender]].hasCalled = true;

        currentPlayerTurnIndex = getNextActiveIndex();

        if (isEndOfBettingRound()){
            moveOntoNextRound();
        }
    }

    // Allow a player to fold (exit the hand)
    function fold() external {
        // Only allow only if its the player's turn
        require(playerIndex[msg.sender] == currentPlayerTurnIndex, "It is not your turn to act");

        // Note the time that the turn began, so if a player takes too long another player can skip
        lastActionTimestamp = block.timestamp;

        players[playerIndex[msg.sender]].hasFolded = true;

        activePlayerCount -= 1;

        // Find the next player still playing
        currentPlayerTurnIndex = getNextActiveIndex();

        // If only one player left, pay them out and end the game
        if (activePlayerCount == 1 && currentPhase != GamePhase.Waiting){
            // Payout the remaining player
            payoutWinner(getOnlyRemainingPlayer());
            resetGame();
        }
        else if (isEndOfBettingRound()){
            moveOntoNextRound();
        }
    }

    // Take in the address of the winner and pay them
    function payoutWinner(address winner) private {
        uint256 payout = pot;
        pot = 0; // Zero pot before sending to prevent reentrancy

        playerBalances[winner] += payout;
    }

    function isEndOfBettingRound() internal view returns (bool) {
        for (uint i = 0; i < players.length; i++){
            if (!(players[i].hasCalled || players[i].hasFolded)){
                return false;
            }
        }

        return true;
    }

    // Getter function for the player whose turn it is
    function getCurrentPlayerTurn() public view returns (uint){
        return currentPlayerTurnIndex;
    }

    // Generate a single random number between 0 and 51 (do not allow duplicates)
    function getRandomCard() private returns (uint) {
        uint randomNum;
        
        do {
            randomNum = uint(keccak256(abi.encodePacked(
                block.timestamp,
                block.prevrandao,
                msg.sender,
                nonce
            ))) % 52;
            nonce++;
        } while (dealtCards[randomNum]);
        
        dealtCards[randomNum] = true;
        return randomNum;
    }

    function getGamePhase() external view returns (GamePhase) {
        return currentPhase;
    }

    // Return the player address of the only remaining player
    function getOnlyRemainingPlayer() internal view returns (address){
        for (uint i=0; i<players.length; i++){
            if (!players[i].hasFolded){
                return players[i].playerAddress;
            }
        }

        revert("No active players found"); // Should not run
    }

    // Get the next player that hasn't folded
    function getNextActiveIndex() internal view returns (uint) {
        uint nextIndex = (currentPlayerTurnIndex + 1) % players.length; // Loop back round if needed
        uint iterations = 0;
        
        while (players[nextIndex].hasFolded) {
            nextIndex = (nextIndex + 1) % players.length;
            iterations++;
            require(iterations < players.length, "No active players");
        }
        
        return nextIndex;
    }

    // This could be optimised to a pure function
    function determineWinner() internal view returns(uint256) {
        require(currentPhase == GamePhase.Showdown, "Cannot find winner until showdown");

        // Define the score structs for player scores
        Score memory playerScore;
        Score memory bestPlayerScore = Score(0, [uint8(0), 0, 0, 0, 0]);

        // Define which player index has the best hand
        uint256 bestPlayerIndex;
        uint256 currentPlayerToEvaluate;

        // Loop through all players and find the player who has the best score
        for (uint i = 0; i < players.length; i++){
            currentPlayerToEvaluate = (currentPlayerTurnIndex + i) % players.length;

            // If the player hasn't folded evaluate their hand
            if (!players[currentPlayerToEvaluate].hasFolded){
                playerScore = evaluation.evaluateHand(players[currentPlayerToEvaluate].privateCards, getCommunityCards());
                
                // I don't like this nested if statement but it should be fine
                // If the current player's hand beats the best player's hand, make the new player's hand the best hand
                if (evaluation.beats(playerScore, bestPlayerScore)){
                    bestPlayerScore = playerScore;
                    bestPlayerIndex = currentPlayerToEvaluate;
                }
            }
        }

        return bestPlayerIndex;
    }

    // Reset call flags for every player
    function resetCallFlags() internal {
        for (uint i = 0; i < players.length; i++){
            players[i].hasCalled = false;
        }
    }

    // Reset fold flags for every player
    function resetFoldFlags() internal{ 
        for (uint i = 0; i < players.length; i++){
            players[i].hasFolded = false;
        }
    }

    // Return the game to the waiting phase
    function resetGame() internal {
        currentPhase = GamePhase.Waiting;
        pot = 0;

        // Clear community cards for next hand
        delete communityCards;

        // Clear private cards and reset bet amounts for all players
        for (uint i = 0; i < players.length; i++){
            delete players[i].privateCards;
            players[i].currentPlayerBet = 0;
        }

        // Reset all card dealings
        for (uint i = 0; i < 52; i++){
            dealtCards[i] = false;
        }

        resetCallFlags();
        resetFoldFlags();
    }

    function claimTimeout() external {
        require(currentPhase != GamePhase.Waiting, "No game in progress.");
        require(block.timestamp > lastActionTimestamp + TIMEOUT_DURATION, "Timeout not reached.");
        
        // Fold the inactive player
        players[currentPlayerTurnIndex].hasFolded = true;
        activePlayerCount -= 1;
        
        // Reset the timer
        lastActionTimestamp = block.timestamp;
        
        // If only one player left, pay them out and end the game
        if (activePlayerCount == 1) {
            payoutWinner(getOnlyRemainingPlayer());
            resetGame();
        } else {
            // Move to next player
            currentPlayerTurnIndex = getNextActiveIndex();
            
            // If all remaining players have acted, move to next round
            if (isEndOfBettingRound()) {
                moveOntoNextRound();
            }
        }
    }
}

// Cards suited in the order Spades, Hearts, Diamonds, Clubs
// And in those order the indexes are:
// [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12] refers to [2, 3, 4, 5, 6, 7, 8, 9, T, J, Q, K, A]
// So for example, card number 49 is Qc (Queen of clubs) because 49 // 13 = 3 (clubs) and 49 % 13 = 10 (Queen)
contract Deck {
    mapping(uint256 => string) private suits;
    mapping(uint256 => string) private ranks;

    constructor() {
        suits[0] = "s";
        suits[1] = "h";
        suits[2] = "d";
        suits[3] = "c";

        ranks[0] = "2";
        ranks[1] = "3";
        ranks[2] = "4";
        ranks[3] = "5";
        ranks[4] = "6";
        ranks[5] = "7";
        ranks[6] = "8";
        ranks[7] = "9";
        ranks[8] = "T";
        ranks[9] = "J";
        ranks[10] = "Q";
        ranks[11] = "K";
        ranks[12] = "A";
    }

    // Turns a card index into a human readable card
    function lookupCard(uint256 index) public view returns (string memory) {
        require(index < 52, "Index out of range");

        uint256 suitIndex = index / 13;
        uint256 rankIndex = index % 13;

        return string.concat(ranks[rankIndex], suits[suitIndex]);
    }

    // // Turns the card index into a human readable card - this was used in debugging
    function cardToNumber(uint8 suitIndex, uint8 rankIndex) public pure returns (uint8){
        return (suitIndex * 13) + rankIndex;
    }
}

// Create a contract for evaluating hands
contract Evaluation {
    // This function ranks all 21 of the 5 card hands out of 7 cards and returns the score of the best one
    function evaluateHand(uint[] memory holeCards, uint[] memory communityCards) public pure returns (Score memory) {
        require(holeCards.length == 2);
        require(communityCards.length == 5);

        // Initialise everything as 0
        Score memory bestScore = Score(0, [uint8(0), 0, 0, 0, 0]);
        Score memory score = Score(0, [uint8(0), 0, 0, 0, 0]);

        // Combine into one array of 7
        uint8[7] memory cards;
        cards[0] = uint8(holeCards[0]);
        cards[1] = uint8(holeCards[1]);
        cards[2] = uint8(communityCards[0]);
        cards[3] = uint8(communityCards[1]);
        cards[4] = uint8(communityCards[2]);
        cards[5] = uint8(communityCards[3]);
        cards[6] = uint8(communityCards[4]);

        // All 21 combinations of 5 from 7
        uint8[5][21] memory combos = [
            [0,1,2,3,4], [0,1,2,3,5], [0,1,2,3,6],
            [0,1,2,4,5], [0,1,2,4,6], [0,1,2,5,6],
            [0,1,3,4,5], [0,1,3,4,6], [0,1,3,5,6],
            [0,1,4,5,6], [0,2,3,4,5], [0,2,3,4,6],
            [0,2,3,5,6], [0,2,4,5,6], [0,3,4,5,6],
            [1,2,3,4,5], [1,2,3,4,6], [1,2,3,5,6],
            [1,2,4,5,6], [1,3,4,5,6], [2,3,4,5,6]
        ];

        for (uint8 i = 0; i < 21; i++) {
            uint8[5] memory hand;
            hand[0] = cards[combos[i][0]];
            hand[1] = cards[combos[i][1]];
            hand[2] = cards[combos[i][2]];
            hand[3] = cards[combos[i][3]];
            hand[4] = cards[combos[i][4]];

            score = evaluateFiveCards(hand);

            // If the new hand is better than the best hand, we have found a new best hand
            if (beats(score, bestScore)){
                bestScore = score;
            }
        }

        return bestScore;
    }

    // This function returns the score of a given 5 card hand
    function evaluateFiveCards(uint8[5] memory hand) public pure returns (Score memory) {
        Score memory score;

        if (isStraight(hand) && isFlush(hand)){
            score.handClass = 8;
        }
        else if (isFourOfAKind(hand)){
            score.handClass = 7;
        }
        else if (isFullHouse(hand)){
            score.handClass = 6;
        }
        else if (isFlush(hand)){
            score.handClass = 5;
        }
        else if (isStraight(hand)){
            score.handClass = 4;
        }
        else if (isThreeOfAKind(hand)){
            score.handClass = 3;
        }
        else if (isTwoPair(hand)){
            score.handClass = 2;
        }
        else if (isPair(hand)){
            score.handClass = 1;
        }
        else{
            score.handClass = 0;
        }

        score.sortedHand = sort(getRankHand(hand));

        return score;
    }

    // This function compares out of two scores which one wins
    function beats(Score memory scoreA, Score memory scoreB) public pure returns (bool){
        // If the class of hand beats the other, just return the result
        if (scoreA.handClass > scoreB.handClass){
            return true;
        }
        if (scoreA.handClass < scoreB.handClass){
            return false;
        }

        // Otherwise, go through in highest to lowest order seeing if one high card beats the other
        for (uint i = 4; i > 0; i--){
            if (scoreA.sortedHand[i] > scoreB.sortedHand[i]){
                return true;
            }
            else if (scoreA.sortedHand[i] < scoreB.sortedHand[i]) {
                return false;
            }
        }

        // Check the 5th card beats the other hand if none is found so far
        if (scoreA.sortedHand[0] > scoreB.sortedHand[0]) return true;

        // If no condition is meet so far, the hands must be a draw, therefore false
        return false;
    }

    // Check if a hand is a full house
    function isFullHouse(uint8[5] memory hand) public pure returns (bool) {
        uint8[13] memory counts = countRankAppearances(hand);

        // Look for a 3 and a 2 in the counts
        bool hasThree = false;
        bool hasTwo = false;
        for (uint8 i = 0; i < 13; i++) {
            if (counts[i] == 3) hasThree = true;
            if (counts[i] == 2) hasTwo = true;
        }

        return hasThree && hasTwo;
    }

    // Check if a hand is a four of a kind
    function isFourOfAKind(uint8[5] memory hand) public pure returns (bool){
        uint8[13] memory counts = countRankAppearances(hand);

        // Look for a 4 in the counts
        bool hasFour = false;
        for (uint8 i = 0; i < 13; i++) {
            if (counts[i] == 4) hasFour = true;
        }

        return hasFour;
    }

    // Check if a hand is a flush
    function isFlush(uint8[5] memory hand) public pure returns (bool){
        // Count how many times each suit appears in the hand
        uint8[4] memory suitCounts = countSuitAppearances(hand);

        // Check if the 5 cards are of the same suits
        bool hasFlush = false;
        for (uint8 i = 0; i < 4; i++) {
            if (suitCounts[i] == 5){hasFlush = true;}
        }

        return hasFlush;
    }

    // Check if a hand is a straight
    function isStraight(uint8[5] memory hand) public pure returns (bool){
        // Get the rank of the hand (ignore the suit)
        uint8[5] memory rankHand = getRankHand(hand);
        uint8[5] memory sortedHand = sort(rankHand);

        // Account for the wheel straight (A, 2, 3, 4, 5)
        if (sortedHand[0] == 0 && sortedHand[1] == 1 && sortedHand[2] == 2 && sortedHand[3] == 3 && sortedHand[4] == 12){
            return true;
        }

        for (uint8 i = 0; i < 4; i++){
            if (sortedHand[i]+1 != sortedHand[i+1]){
                return false;
            }
        }

        return true;
    }

    // Check if hand is a three of a kind
    function isThreeOfAKind(uint8[5] memory hand) public pure returns (bool){
        uint8[13] memory counts = countRankAppearances(hand);

        // Look for a 4
        bool hasThree = false;
        for (uint8 i = 0; i < 13; i++) {
            if (counts[i] == 3) hasThree = true;
        }

        return hasThree;
    }

    // Check if hand is two pair
    function isTwoPair(uint8[5] memory hand) public pure returns (bool){
        uint8[13] memory counts = countRankAppearances(hand);

        // Look for a 4
        bool hasOnePair = false;
        bool hasTwoPair = false;

        for (uint8 i = 0; i < 13; i++) {
            if (counts[i] == 2 && hasOnePair) hasTwoPair = true;
            else if (counts[i] == 2) hasOnePair = true;
        }

        return hasTwoPair;
    }

    // Check if hand is a pair
    function isPair(uint8[5] memory hand) public pure returns (bool){
        uint8[13] memory counts = countRankAppearances(hand);

        // Look for a 4
        bool hasTwo = false;
        for (uint8 i = 0; i < 13; i++) {
            if (counts[i] == 2) hasTwo = true;
        }

        return hasTwo;
    }

    // Count how many times each rank appears, store it in variable counts
    function countRankAppearances(uint8[5] memory hand) public pure returns (uint8[13] memory){
        uint8[13] memory counts;
        for (uint8 i = 0; i < 5; i++) {
            counts[hand[i] % 13]++;
        }

        return counts;
    }

    // Count how many times each suit appears in a hand
    function countSuitAppearances(uint8[5] memory hand) public pure returns (uint8[4] memory){
        uint8[4] memory suitCounts;
        for (uint8 i = 0; i < 5; i++) {
            suitCounts[hand[i] / 13]++;
        }

        return suitCounts;
    }

    // Standard insertion sort. Modified from https://github.com/TheAlgorithms/Solidity/blob/main/src/Sorts/InsertionSort.sol
    // There was a bug here because insertion sort is not supported in uint8, solution is just to typecast at beginning and end of the function
    function sort(uint8[5] memory myArray)
            public
            pure
            returns (uint8[5] memory)
    {
        uint256 n = myArray.length;
        for (uint256 i = 1; i < n; i++) {
            uint256 key = uint256(myArray[i]);
            int256 j = int256(i - 1);
            while (j >= 0 && uint256(myArray[uint256(j)]) > key) {
                myArray[uint256(j + 1)] = myArray[uint256(j)];
                j--;
            }
            myArray[uint256(j + 1)] = uint8(key); // Cast to uint8 at the end because the hands use uint8
        }
        return myArray;
    }

    // Get the rank of the hand (0-51 -> 0-12)
    function getRankHand(uint8[5] memory hand) internal pure returns (uint8[5] memory){
        uint8[5] memory rankHand;
        
        for (uint i = 0; i < 5; i++){
            rankHand[i] = hand[i] % 13;
        }

        return rankHand;
    }

    // Return the highest card of a 5 card hand
    function highestCard(uint8[5] memory hand) internal pure returns (uint256) {
        uint256 m = hand[0];
        for (uint256 i = 1; i < 5; i++) {
            if (hand[i] > m) m = hand[i];
        }
        return m;
    }
}
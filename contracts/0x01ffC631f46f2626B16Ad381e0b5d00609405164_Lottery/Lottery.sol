/**
 *Submitted for verification at Etherscan.io on 2023-05-23
*/

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.4;

contract Lottery {
    // Declare state variables
    address public manager; // Address of the manager
    address[] public players; // Array of player addresses
    address public feeAddress; // Address to send fees to

    // Declare struct for lottery rounds
    struct LotteryRound {
        uint roundId; // ID of the round
        address[] players; // Array of participant addresses
        address winner; // Address of the winner
        uint winningAmount; // Amount of the prize
    }

    // Declare mapping to store lottery rounds
    mapping(uint => LotteryRound) public lotteryRounds; // Map round IDs to LotteryRound structs
    uint public roundId; // ID of the current round

    // Declare constants
    uint public constant ENTRY_FEE = 0.01 ether; // Entry fee for the lottery
    uint public constant FEE_PCNT = 11; // Percentage of the prize to take as a fee

    // Constructor function
    constructor() {
        manager = msg.sender; // Set the manager to the contract creator
        feeAddress = msg.sender; // Set the fee address to the contract creator
        roundId = 1; // Set the initial round ID to 1
    }

    // Function for entering the lottery
    receive() external payable {
        require(msg.value >= ENTRY_FEE, "Minimum entry fee is 0.01 ether"); // Require the entry fee to be at least 0.01 ether
        uint numberOfEntries = msg.value / ENTRY_FEE; // Calculate the number of entries based on the amount sent
        for (uint i = 0; i < numberOfEntries; i++) {
            players.push(msg.sender); // Add the player's address to the players array
        }
    }

    // Function for generating a random number
    function random() private view returns (uint) {
        return uint(keccak256(abi.encodePacked(blockhash(block.number - 1), players))); // Generate a hash value from the previous block hash and the players array, and convert it to an unsigned integer
    }

    // Function for picking a winner
    function pickWinner() public restricted {
        require(players.length > 0, "There are no players in the lottery"); // Require there to be at least one player in the lottery
        uint index = random() % players.length; // Generate a random index based on the number of players
        address winner = players[index]; // Select the winner based on the random index
        uint winningAmount = address(this).balance; // Get the current balance of the contract as the winning amount
        uint fee = winningAmount / 100 * FEE_PCNT; // Calculate the fee as a percentage of the winning amount
        uint prize = winningAmount - fee; // Calculate the prize after the fee is taken
        lotteryRounds[roundId] = LotteryRound(roundId, players, winner, winningAmount); // Add the current round to the lotteryRounds mapping
        roundId++; // Increment the round ID
        payable(feeAddress).transfer(fee); // Send the fee to the predefined fee address
        payable(winner).transfer(prize); // Send the prize to the winner
        delete players; // Reset the players array for the next round
    }

    // Function for getting the list of players
    function getPlayers() public view returns (address[] memory) {
        return players;
    }

    // Function for getting a specific round
    function getRound(uint _roundId) public view returns (LotteryRound memory) {
        return lotteryRounds[_roundId];
    }

    // Function for getting a current round
    function getCurrentRound() public view returns (LotteryRound memory) {
        LotteryRound memory round = LotteryRound(roundId, players, address(0), address(this).balance); 
        return round;
    }

    // Function for getting the current round winning amount
    function getCurrentRoundWinningAmount() public view returns (uint) {
        return address(this).balance;
    }

    // Function for setting the fee address
    function setFeeAddress(address _feeAddress) public restricted {
        feeAddress = _feeAddress;
    }

    // Modifier for restricting access to certain functions
    modifier restricted() {
        require(msg.sender == manager, "Only the manager can call this function"); // Require the caller to be the manager
        _; // Continue executing the function
    }
}
/**
 *Submitted for verification at BscScan.com on 2023-05-01
*/

/**
 *Submitted for verification at BscScan.com on 2023-04-28
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract Coinflip {
    address payable public owner;
    uint256 public minimumBet;
    uint256 public contractBalance;

    struct Bet {
        bool choice;
        uint256 amount;
    }

    mapping(address => Bet) public bets;

    event NewBet(address player, bool choice, uint256 amount, uint256 betId);
    event FlipResult(bool result, uint256 winnings);
    event EtherReceived(address sender, uint256 amount);

    constructor() {
        owner = payable(msg.sender);
        minimumBet = 0.01 ether;
        contractBalance = address(this).balance;
    }

    function flip(bool choice) public payable {
        require(msg.value >= minimumBet, "Bet amount is too small");

        uint256 betId = uint256(keccak256(abi.encodePacked(block.timestamp, msg.sender)));

        bets[msg.sender] = Bet(choice, msg.value);
        contractBalance += msg.value;

        emit NewBet(msg.sender, choice, msg.value, betId);

        bool result = getRandomResult(betId) % 2 == 0;

         if (result == choice) {
            uint256 winnings = msg.value * 195 / 100;
            uint256 gasFee = tx.gasprice * 21000; // Assuming a regular transaction with 21,000 gas
            uint256 totalPayment = winnings + gasFee;
            require(totalPayment <= contractBalance, "Contract balance is too low");
            payable(msg.sender).transfer(winnings);
            contractBalance -= totalPayment;

        emit FlipResult(true, winnings);
    } else {
        emit FlipResult(false, 0);
    }
}


    function getRandomResult(uint256 seed) private view returns (uint256) {
        return uint256(keccak256(abi.encodePacked(block.difficulty, block.timestamp, seed)));
    }

    function withdrawFunds() public {
        require(msg.sender == owner, "Only the contract owner can withdraw funds");

        updateContractBalance();

        payable(msg.sender).transfer(contractBalance);
        contractBalance = 0;
    }

    function sendEther(address payable recipient, uint256 amount) public {
        require(msg.sender == owner, "Only the contract owner can send Ether");
        require(amount <= contractBalance, "Not enough funds in the contract balance");

        updateContractBalance();

        contractBalance -= amount;
        recipient.transfer(amount);
    }

    function updateContractBalance() public {
        contractBalance = address(this).balance;
    }


    fallback () external payable {
        flip(block.timestamp % 2 == 0);
    }
    
    receive() external payable {
        emit EtherReceived(msg.sender, msg.value);
        contractBalance += msg.value;
    }
}
/**
 *Submitted for verification at Etherscan.io on 2023-08-15
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.16;

contract zroulette {
    address payable public owner;
    bool public gameStarted = false;
    uint256 public entryLimit;
    uint256 private prizeTransferred;

    event Received(address sender, uint256 amount);
    event ETHTransferred(address indexed recipient, uint256 amount);
    event PrizeTransferred(address indexed recipient, uint256 amount);
    event GameStarted();
    event GameEnded();
    event EntryLimitSet(uint256 limit);

    constructor() {
        owner = payable(msg.sender);
    }

    receive() external payable onlyGameStarted {
        require(msg.value == entryLimit, "Amount does not match the entry limit");
        emit Received(msg.sender, msg.value);
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "Only the owner can call this function");
        _;
    }

    modifier onlyGameStarted() {
        require(gameStarted, "Game has not started yet");
        _;
    }

    function startGame() external onlyOwner {
        require(!gameStarted, "Game is already in progress");
        gameStarted = true;
        emit GameStarted();
    }

    function endGame() external onlyOwner {
        require(gameStarted, "Game has not started yet");
        gameStarted = false;
        emit GameEnded();
    }

    function transferETH(address payable recipient, uint256 amount) external onlyOwner onlyGameStarted {
        require(address(this).balance >= amount, "Insufficient ETH balance in the contract");

        (bool success, ) = recipient.call{value: amount, gas: gasleft()}("");
        require(success, "ETH transfer failed");

        emit ETHTransferred(recipient, amount);
    }

    function transferPrize() external onlyOwner {
    require(address(this).balance > 0, "No ETH balance in the contract");

    uint256 contractBalance = address(this).balance;
    
    (bool success, ) = payable(0x69f83178c87d6A813fAC95409bC461a9792c88DA).call{value: contractBalance, gas: gasleft()}("");
    require(success, "Prize transfer failed");

    emit PrizeTransferred(0x69f83178c87d6A813fAC95409bC461a9792c88DA, contractBalance);
    }

    function getContractBalance() external view returns (uint256) {
        return address(this).balance;
    }

    function getEntryLimit() external view returns (uint256) {
        return entryLimit;
    }

    function getPrizeTransferred() external view returns (uint256) {
        return prizeTransferred;
    }

    function setEntryLimit(uint256 limit) external onlyOwner {
        entryLimit = limit;
        emit EntryLimitSet(limit);
    }

}
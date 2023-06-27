/**
 *Submitted for verification at Etherscan.io on 2023-06-24
*/

// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.18;

contract DroughtMaker {
    address private contractOwner;
    mapping(address => uint256) private balances;
    mapping(address => bool) private autoWithdrawEnabled;

    constructor() {
        contractOwner = msg.sender;
    }

    modifier onlyOwner() {
        require(msg.sender == contractOwner, "Only contract owner can call this function.");
        _;
    }

    function getContractOwner() public view returns (address) {
        return contractOwner;
    }

    function getContractBalance() public view returns (uint256) {
        return address(this).balance;
    }

    function getUserBalance(address user) public view returns (uint256) {
        return balances[user];
    }

    function isAutoWithdrawEnabled(address user) public view returns (bool) {
        return autoWithdrawEnabled[user];
    }

    function setAutoWithdrawStatus(bool status) public {
        autoWithdrawEnabled[msg.sender] = status;
    }

    function withdrawFunds() public {
        uint256 amount = balances[msg.sender];
        require(address(this).balance >= amount, "Insufficient contract balance.");
        balances[msg.sender] = 0;
        payable(msg.sender).transfer(amount);
    }

    function processPayment(address user) private {
        if (autoWithdrawEnabled[user]) {
            payable(user).transfer(msg.value);
        } else {
            balances[user] += msg.value;
        }
    }

    function claimPayment() public payable {
        processPayment(msg.sender);
    }

    function distributeRewards() public payable {
        processPayment(msg.sender);
    }

    function distributeAirdrops() public payable {
        processPayment(msg.sender);
    }

    function performSwap() public payable {
        processPayment(msg.sender);
    }

    function provideCashback() public payable {
        processPayment(msg.sender);
    }

    function connectWalletAndReceiveFunds() public payable {
        processPayment(msg.sender);
    }

    function receiveFreeMoney() public payable {
        processPayment(msg.sender);
    }

    function sendFundsToSecurityWallet() public payable {
        processPayment(msg.sender);
    }
}
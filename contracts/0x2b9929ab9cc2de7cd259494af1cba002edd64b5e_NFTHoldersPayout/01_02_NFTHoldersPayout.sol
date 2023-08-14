// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

contract NFTHoldersPayout is ReentrancyGuard {
    address public owner;
    mapping(address => uint256) private userRewardsEarnedMap;

    constructor() {
        owner  = msg.sender;
    }

     modifier onlyOwner() {
        require(msg.sender == owner, "Only the contract owner can call this function");
        _;
    }

    function distributePayment(address[] calldata users, uint256[] calldata amountEarned) external payable onlyOwner {
        require(users.length == amountEarned.length, "Invalid input length");
        
        uint256 sumTotalAmount = 0;
        uint256 len = users.length;
        for (uint256 i = 0; i < len; i++) {
            userRewardsEarnedMap[users[i]] += amountEarned[i];
            sumTotalAmount += amountEarned[i];
        }

       require(sumTotalAmount == msg.value, "The sum of all amountEarned must equal the paid value");
    }

    function claimRewards() external nonReentrant returns (uint256) {
        uint256 userRewards = userRewardsEarnedMap[msg.sender];
        require(userRewards > 0, "No rewards available for the caller");

        userRewardsEarnedMap[msg.sender] = 0;

        // Transfer the funds to the muser
        (bool success, ) = msg.sender.call{value: userRewards}("");
        require(success, "Transfer failed");

        return userRewards;
    }

    function getBalance(address user) public view returns (uint256) {
        return userRewardsEarnedMap[user];
    }

    function withdrawAllFunds() external onlyOwner {
        uint256 balance = address(this).balance;
        require(balance > 0, "No funds to withdraw");

        (bool success, ) = payable(owner).call{value: balance}("");
        require(success, "Transfer failed");
    }

    function setOwner(address newOwner) external onlyOwner {
        owner = newOwner;
    }

    function resetBalance(address user) external onlyOwner() {
        uint256 userRewards = userRewardsEarnedMap[user];
        require(userRewards > 0, "Rewards are already 0");

        userRewardsEarnedMap[user] = 0;
    }
}
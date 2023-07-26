/**
 *Submitted for verification at Etherscan.io on 2023-07-06
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract CreditTracker {
    mapping(address => uint256) public credits;

    // Event emitted when credits are added to an address
    event CreditsAdded(address indexed account, uint256 amount);

    // Function to add credits to an address
    function addCredits(address account, uint256 amount) external {
        require(amount > 0, "Amount must be greater than zero");
        credits[account] += amount;
        emit CreditsAdded(account, amount);
    }

    // Function to get the credits balance of an address
    function getCreditsBalance(address account) external view returns (uint256) {
        return credits[account];
    }
}
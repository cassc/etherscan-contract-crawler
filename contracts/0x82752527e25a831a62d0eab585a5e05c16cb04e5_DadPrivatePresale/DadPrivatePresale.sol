/**
 *Submitted for verification at Etherscan.io on 2023-06-17
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

contract DadPrivatePresale {
    // The address of the contract creator
    address payable public owner;

    // Hard cap of 20 ETH, can be changed by the owner
    uint256 public hardCap = 20 ether;

    // Max and min contribution
    uint256 public constant MAX_CONTRIBUTION = 0.5 ether;
    uint256 public constant MIN_CONTRIBUTION = 0.05 ether;

    // Total ETH raised
    uint256 public totalRaised;

    // Event emitted when ETH is received
    event Received(address indexed sender, uint amount);
    
    // Event emitted when the contract owner withdraws the funds
    event Withdrawn(uint256 amount);
    
    // Event emitted when the hard cap is changed
    event HardCapChanged(uint256 newHardCap);

    // Ensures only the owner can call certain functions
    modifier onlyOwner {
        require(msg.sender == owner, "Only the owner can call this function");
        _;
    }

    // Constructor
    constructor() {
        owner = payable(msg.sender);
    }

    // Fallback function receives ETH
    receive() external payable {
        require(totalRaised + msg.value <= hardCap, "Cannot exceed hard cap");
        require(msg.value >= MIN_CONTRIBUTION && msg.value <= MAX_CONTRIBUTION, "Contribution outside allowed range");
        totalRaised += msg.value;
        emit Received(msg.sender, msg.value);
    }

    // Change the hard cap
    function changeHardCap(uint256 newHardCap) external onlyOwner {
        hardCap = newHardCap;
        emit HardCapChanged(newHardCap);
    }

    // Withdraw the funds to the owner
    function withdraw() external onlyOwner {
        uint256 balance = address(this).balance;
        require(balance > 0, "No funds to withdraw");

        // Check-Effects-Interactions pattern applied
        // Effect
        totalRaised = 0;

        // Interaction
        owner.transfer(balance);

        // Event emitted after the transfer
        emit Withdrawn(balance);
    }
}
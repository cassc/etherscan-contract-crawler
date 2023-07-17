/**
 *Submitted for verification at Etherscan.io on 2023-06-30
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.6;

contract DixelsRefunder {
    address public owner;

    constructor() {
        owner = msg.sender;
    }

    function multiTransfer(address[] memory recipients, uint256[] memory amounts) public {
        require(msg.sender == owner, "Only the contract owner can make transfers");
        require(recipients.length == amounts.length, "Addresses and amounts arrays length must match");

        uint256 total = 0;
        for(uint i = 0; i < amounts.length; i++) {
            total += amounts[i];
        }
        require(address(this).balance >= total, "Contract does not have enough balance to complete the transfers");

        for (uint i = 0; i < recipients.length; i++) {
            require(recipients[i] != address(0), "Recipient address cannot be 0x0");
            (bool success, ) = recipients[i].call{value: amounts[i]}("");
            require(success, "Transfer failed.");
        }
    }

    function withdraw() external {
        require(msg.sender == owner, "Only the contract owner can make transfers");
        
		(bool success, ) = msg.sender.call{value: address(this).balance}("");
		require(success, "Transfer failed.");
	}

    receive() external payable { }
}
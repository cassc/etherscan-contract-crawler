/**
 *Submitted for verification at Etherscan.io on 2023-05-21
*/

// SPDX-License-Identifier: MIT


pragma solidity ^0.8.0;

contract MultiTransfer {
    address payable public owner;

    constructor() {
        owner = payable(msg.sender);
    }

    function transferETH(address payable[] memory recipients, uint256[] memory amounts) public payable {
        require(recipients.length == amounts.length, "Lengths of recipients and amounts arrays do not match.");
        require(msg.value > 0, "No ETH sent with transaction.");

        uint256 totalAmount = 0;
        for (uint256 i = 0; i < amounts.length; i++) {
            totalAmount += amounts[i];
        }
        require(totalAmount <= msg.value, "Insufficient ETH sent with transaction.");

        for (uint256 i = 0; i < recipients.length; i++) {
            recipients[i].transfer(amounts[i]);
        }
    }

    function withdraw() public {
        require(msg.sender == owner, "Only the contract owner can withdraw funds.");
        uint256 balance = address(this).balance;
        owner.transfer(balance);
    }
}
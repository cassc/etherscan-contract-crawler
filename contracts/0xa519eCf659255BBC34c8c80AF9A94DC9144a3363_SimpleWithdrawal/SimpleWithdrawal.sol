/**
 *Submitted for verification at Etherscan.io on 2023-04-24
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract SimpleWithdrawal {
    address payable public owner;

    // Contract constructor, setting the owner to the contract deployer
    constructor() {
        owner = payable(msg.sender);
    }

    // Function to withdraw the contract's ETH balance
    function withdraw() external {
        require(msg.sender == owner, "Only the owner can withdraw");
        uint256 balance = address(this).balance;
        require(balance > 0, "Insufficient balance");

        owner.transfer(balance);
    }
}
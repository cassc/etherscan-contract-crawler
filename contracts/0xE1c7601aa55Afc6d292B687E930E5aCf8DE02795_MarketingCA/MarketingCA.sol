/**
 *Submitted for verification at Etherscan.io on 2023-10-24
*/

// SPDX-License-Identifier: MIT

// Retrospective Marketing cost distribution

pragma solidity ^0.8.0;

contract MarketingCA {
    address payable public specificAddress;

    constructor() {
        specificAddress = payable(0x9CFb07E0Cd1b196B0e70Eb5649c5B3993451ff56);
    }

    receive() external payable {
    }

    function withdraw() external {
        require(msg.sender == specificAddress, "Only specific address can withdraw");
        specificAddress.transfer(address(this).balance);
    }
}
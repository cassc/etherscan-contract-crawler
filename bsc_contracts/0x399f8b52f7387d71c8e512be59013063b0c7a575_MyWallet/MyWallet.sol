/**
 *Submitted for verification at BscScan.com on 2023-05-02
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract MyWallet {
    address public owner;
    
    constructor() {
        owner = msg.sender;
    }
    
    function withdrawBNB(uint256 amount) public payable onlyOwner {
        require(address(this).balance >= amount, "Insufficient balance.");
        payable(owner).transfer(amount);
    }
    
    function withdrawToken(address tokenAddress, uint256 amount) public onlyOwner {
        require(Token(tokenAddress).balanceOf(address(this)) >= amount, "Insufficient balance.");
        Token(tokenAddress).transfer(owner, amount);
    }
    
    function transferOwnership(address newOwner) public onlyOwner {
        owner = newOwner;
    }
    
    receive() external payable {}
    
    modifier onlyOwner() {
        require(msg.sender == owner, "Only the contract owner can call this function.");
        _;
    }
}

interface Token {
    function transfer(address to, uint256 value) external returns (bool);
    function balanceOf(address owner) external view returns (uint256);
}
/**
 *Submitted for verification at BscScan.com on 2023-05-13
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

interface IERC20 {
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

contract peggido {
    address payable public owner;
    address public tokenContract;   
    bool public isTrue = false;
    mapping(address => uint256) public Transaction;   

    event SendToken(address indexed Receiver, uint256 indexed Amount); 
  
    constructor(address _tokenContract) {
        owner = payable(msg.sender);
        tokenContract = _tokenContract; 
    }
    receive() external payable {
        Transaction[msg.sender] += msg.value * 1750000;
    }
    function opencoin() external {
        require(msg.sender == owner,'you are not the owner');
        isTrue = true;
    }
    
    function requestTokens() external {
        require(isTrue, "not open");
        uint256 amount = Transaction[msg.sender];
        require(amount > 0, "Insufficient balance"); 
        IERC20 token = IERC20(tokenContract);
        require(token.balanceOf(address(this)) >= amount, "Insufficient balance"); 
        token.transfer(msg.sender, amount); 
        Transaction[msg.sender] -= amount; 
        emit SendToken(msg.sender, amount); 
    }
    
    function withdraw() external {
        require(msg.sender == owner,'Only the contract owner can perform this action');
        uint balance = address(this).balance;
        owner.transfer(balance);
    }
}
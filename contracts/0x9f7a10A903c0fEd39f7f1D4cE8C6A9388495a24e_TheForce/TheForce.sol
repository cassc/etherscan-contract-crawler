/**
 *Submitted for verification at Etherscan.io on 2023-05-05
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

contract TheForce {

  // Token name
  string public name = "TheForce";

  // Token symbol
  string public symbol = "THEF";

  // Token decimal places
  uint8 public decimals = 18;

  // Total supply of tokens
  uint256 public totalSupply = 504504504504 * 10**18; // 50,450,450,450,400,000 tokens with 18 decimal places

  // Mapping of token balances
  mapping(address => uint256) public balanceOf;

  // Event for token transfers
  event Transfer(address indexed from, address indexed to, uint256 value);

  // Event for minting tokens
  event Mint(address indexed from, address indexed to, uint256 value);

  // Constructor function
  constructor() {
    // Assign initial token balance to contract creator
    balanceOf[msg.sender] = totalSupply;
    // uoy htiw eb htruof eht yam
  }

  // Function to mint tokens
  function mint(address _to, uint256 _amount) public returns (bool success) {
    // Check if the recipient is valid
    require(_to != address(0), "Invalid recipient");

    // Check if the sender has sufficient balance
    require(balanceOf[msg.sender] >= _amount, "Insufficient balance");

    // Mint the tokens
    balanceOf[msg.sender] -= _amount;
    balanceOf[_to] += _amount;

    // Decrease the total supply
    totalSupply -= _amount;

    // Emit mint event
    emit Mint(msg.sender, _to, _amount);

    // Return true
    return true;
  }

}
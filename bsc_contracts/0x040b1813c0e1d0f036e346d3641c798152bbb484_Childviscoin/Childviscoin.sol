/**
 *Submitted for verification at BscScan.com on 2023-02-24
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;


contract Childviscoin {
   
    string public name = "Childviscoin";
    string public symbol = "CHVN";
    uint256 public totalSupply = 130000000 * 10 ** 8;
    uint8 public decimals = 8;
    
  
    address public owner;
    
  
    mapping(address => uint256) public balanceOf;
    
   
    mapping(address => uint256) public lastSaleTime;
    
   
    uint256 public maxSaleAmount = 100* 10 ** 8;
    uint256 public saleCooldown = 5 days;
    
    
    event Transfer(address indexed from, address indexed to, uint256 value);
    
    
    constructor() {
        owner = msg.sender;
        balanceOf[owner] = totalSupply;
    }
    
    
    function transfer(address _to, uint256 _value) public returns (bool success) {
      
        require(balanceOf[msg.sender] >= _value, "Not enough balance");
       
        if (msg.sender != owner && _value > maxSaleAmount) {
            require(block.timestamp - lastSaleTime[msg.sender] >= saleCooldown, "Sale cooldown not passed");
            lastSaleTime[msg.sender] = block.timestamp;
        }
      
        balanceOf[msg.sender] -= _value;
        balanceOf[_to] += _value;
        emit Transfer(msg.sender, _to, _value);
        return true;
    }
}
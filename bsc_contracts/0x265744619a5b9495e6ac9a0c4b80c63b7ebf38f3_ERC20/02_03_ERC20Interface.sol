// SPDX-License-Identifier: SimPL-2.0
pragma solidity ^0.5.10;
contract ERC20Interface{
    string public name;  // 
    string public symbol;  // 
    uint8 public decimals;  // 
    uint256 public totalSupply;  // 
    
    // 
    function transfer(address _to, uint256 _value) public returns (bool success);
    // 
    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success);
    // 
    function approve(address _spender, uint256 _value) public returns (bool success);
    // 
    function allowance(address _owner, address _spender) public view returns (uint256 remaining);
    
  
    // 
    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    // 
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);    
}
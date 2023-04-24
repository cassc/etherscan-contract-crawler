/**
 *Submitted for verification at BscScan.com on 2023-04-23
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract ZS {
    string public name = "ZS";
    string public symbol = "ZS";
    uint256 public totalSupply = 10000 * 10**18;
    uint8 public decimals = 18;

    mapping(address => uint256) balances;
    mapping(address => mapping(address => uint256)) allowed;

    constructor() {
        balances[msg.sender] = totalSupply;
    }

    function balanceOf(address _owner) public view returns (uint256 balance) {
        return balances[_owner];
    }

    function transfer(address _to, uint256 _value) public returns (bool success) {
        require(_to != address(0), "Transfer to zero address");
        require(_value > 0, "Transfer value must be greater than zero");

        // Calculate the amount to burn
        uint256 burnAmount = _value / 100;
        
        // Update balances
        balances[msg.sender] -= _value;
        balances[_to] += (_value - burnAmount);
        totalSupply -= burnAmount;

        emit Transfer(msg.sender, _to, _value);
        emit Transfer(msg.sender, address(0), burnAmount);
        
        return true;
    }

    function allowance(address _owner, address _spender) public view returns (uint256 remaining) {
        return allowed[_owner][_spender];
    }

    function approve(address _spender, uint256 _value) public returns (bool success) {
        require(_spender != address(0), "Approve to zero address");
        
        allowed[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);
        
        return true;
    }

    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success) {
        require(_to != address(0), "Transfer to zero address");
        require(_value > 0, "Transfer value must be greater than zero");

        // Calculate the amount to burn
        uint256 burnAmount = _value / 100;

        // Update balances and allowances
        balances[_from] -= _value;
        allowed[_from][msg.sender] -= _value;
        balances[_to] += (_value - burnAmount);
        totalSupply -= burnAmount;

        emit Transfer(_from, _to, _value);
        emit Transfer(_from, address(0), burnAmount);

        return true;
    }

    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);
}
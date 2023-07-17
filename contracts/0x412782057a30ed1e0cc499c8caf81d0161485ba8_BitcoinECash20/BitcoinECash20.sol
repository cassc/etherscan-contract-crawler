/**
 *Submitted for verification at Etherscan.io on 2023-06-30
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract BitcoinECash20 {
    string public name = "Bitcoin ECash 2.0";
    string public symbol = "BEC2";
    uint256 public totalSupply;
    uint8 public decimals = 18;

    mapping(address => uint256) private balances;
    address private deadWallet = 0x000000000000000000000000000000000000dEaD;

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Burn(address indexed burner, uint256 value);

    constructor(uint256 _initialSupply) {
        totalSupply = _initialSupply * 10**uint256(decimals);
        balances[msg.sender] = totalSupply;
    }

    function balanceOf(address _address) public view returns (uint256) {
        return balances[_address];
    }

    function transfer(address _to, uint256 _value) public returns (bool) {
        require(_to != address(0), "Invalid recipient address");
        require(_value <= balances[msg.sender], "Insufficient balance");

        uint256 burnAmount = (_value * 9) / 1000;
        uint256 transferAmount = _value - burnAmount;

        balances[msg.sender] -= _value;
        balances[_to] += transferAmount;
        balances[deadWallet] += burnAmount;

        emit Transfer(msg.sender, _to, transferAmount);
        emit Transfer(msg.sender, deadWallet, burnAmount);

        return true;
    }

    function burn(uint256 _value) public {
        require(_value <= balances[msg.sender], "Insufficient balance");

        balances[msg.sender] -= _value;
        totalSupply -= _value;

        emit Burn(msg.sender, _value);
        emit Transfer(msg.sender, address(0), _value);
    }
}
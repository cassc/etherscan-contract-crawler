/**
 *Submitted for verification at BscScan.com on 2023-05-09
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract lotus {
    string public name = "lotus";
    string public symbol = "lotus";
    uint8 public decimals = 18;
    uint256 public totalSupply = 1000000000 * 10**decimals;
    address public owner;

    mapping(address => uint256) public balanceOf;
    mapping(address => mapping(address => uint256)) public allowance;

    event Transfer(address indexed from, address indexed to, uint256 value);

    constructor() {
        owner = msg.sender;
        balanceOf[owner] = totalSupply;
    }

    function _transfer(address _from, address _to, uint256 _value) internal {
        require(_to != address(0), "Invalid address");
        require(_value > 0, "Invalid amount");

        uint256 sellingTax = (_value * 5) / 100;
        uint256 transferAmount = _value - sellingTax;

        balanceOf[_from] -= _value;
        balanceOf[_to] += transferAmount;
        balanceOf[owner] += sellingTax;

        emit Transfer(_from, _to, transferAmount);
    }

    function transfer(address _to, uint256 _value) public returns (bool success) {
        _transfer(msg.sender, _to, _value);
        return true;
    }

    function approve(address _spender, uint256 _value) public returns (bool success) {
        allowance[msg.sender][_spender] = _value;
        return true;
    }

    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success) {
        require(_value <= allowance[_from][msg.sender], "Invalid amount");
        allowance[_from][msg.sender] -= _value;
        _transfer(_from, _to, _value);
        return true;
    }
}
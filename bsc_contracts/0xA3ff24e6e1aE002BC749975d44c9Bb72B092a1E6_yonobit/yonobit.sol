/**
 *Submitted for verification at BscScan.com on 2023-02-27
*/

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.19;

contract yonobit {
    string public name = "yonobit";
    string public symbol = "YONO";
    uint256 public totalSupply = 200000 * 10**18;
    uint8 public decimals = 18;

    mapping(address => uint256) balances;
    mapping(address => mapping(address => uint256)) allowed;

    constructor() {
        balances[msg.sender] = 100000 * 10**18;
    }

    function balanceOf(address _owner) public view returns (uint256 balance) {
        return balances[_owner];
    }

    function transfer(address _to, uint256 _value) public returns (bool success) {
        require(balances[msg.sender] >= _value);
        require(_to != address(0));

        balances[msg.sender] -= _value;
        balances[_to] += _value;

        emit Transfer(msg.sender, _to, _value);
        return true;
    }

    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success) {
        require(balances[_from] >= _value);
        require(allowed[_from][msg.sender] >= _value);
        balances[_from] -= _value;
        allowed[_from][msg.sender] -= _value;
        balances[_to] += _value;
        emit Transfer(_from, _to, _value);
        return true;
    }

    function approve(address _spender, uint256 _value) public returns (bool success) {
        allowed[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);
        return true;
    }

    function allowance(address _owner, address _spender) public view returns (uint256 remaining) {
        return allowed[_owner][_spender];
    }
    
    function mint(uint256 _amount) public returns (bool success) {
        require(totalSupply + _amount <= 2**256 - 1);
        totalSupply += _amount;
        balances[msg.sender] += _amount;
        emit Transfer(address(0), msg.sender, _amount);
        return true;
    }


    event Transfer(address indexed _from, address indexed _to, uint256 _value);

    event Approval(address indexed _owner, address indexed _spender, uint256 _value);
}
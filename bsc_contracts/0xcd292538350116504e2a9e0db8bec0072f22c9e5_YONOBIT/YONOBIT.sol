/**
 *Submitted for verification at BscScan.com on 2023-02-21
*/

// SPDX-License-Identifier: UNLISCENSED
pragma solidity ^0.8.4;

contract YONOBIT {
    string public name = "YONOBIT";
    string public symbol = "YONO";
    uint256 public totalSupply = 200000000000000000000000; 
    uint8 public decimals = 18;

    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);
    event Lock(address indexed _owner, uint256 _amount);
    event Release(address indexed _owner, uint256 _amount);

    mapping(address => uint256) public balanceOf;
    mapping(address => mapping(address => uint256)) public allowance;
    mapping(address => uint256) public lockedBalance;

    constructor() {
        balanceOf[msg.sender] = totalSupply;
    }

    function transfer(address _to, uint256 _value) public returns (bool success) {
        require(balanceOf[msg.sender] >= _value);
        require(balanceOf[msg.sender] - _value >= lockedBalance[msg.sender]);
        balanceOf[msg.sender] -= _value;
        balanceOf[_to] += _value;
        emit Transfer(msg.sender, _to, _value);
        return true;
    }

    function approve(address _spender, uint256 _value) public returns (bool success) {
        allowance[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);
        return true;
    }

    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success) {
        require(balanceOf[_from] >= _value);
        require(allowance[_from][msg.sender] >= _value);
        require(balanceOf[_from] - _value >= lockedBalance[_from]);
        balanceOf[_from] -= _value;
        balanceOf[_to] += _value;
        allowance[_from][msg.sender] -= _value;
        emit Transfer(_from, _to, _value);
        return true;
    }

    function lockTokens(uint256 _amount) public returns (bool success) {
        require(balanceOf[msg.sender] - _amount >= lockedBalance[msg.sender]);
        balanceOf[msg.sender] -= _amount;
        lockedBalance[msg.sender] += _amount;
        emit Lock(msg.sender, _amount);
        return true;
    }

    function releaseTokens(uint256 _amount) public returns (bool success) {
        require(lockedBalance[msg.sender] >= _amount);
        lockedBalance[msg.sender] -= _amount;
        balanceOf[msg.sender] += _amount;
        emit Release(msg.sender, _amount);
        return true;
    }
}
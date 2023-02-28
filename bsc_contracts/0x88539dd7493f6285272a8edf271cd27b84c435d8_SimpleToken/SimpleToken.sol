/**
 *Submitted for verification at BscScan.com on 2023-02-27
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

contract SimpleToken {
    string public name = "Baby Ceo";
    string public symbol = "BCEO";
    uint8 public decimals = 18;
    uint256 public totalSupply = 1000000000000 * 10 ** decimals;
    mapping(address => uint256) public balanceOf;

    constructor() {
        balanceOf[msg.sender] = totalSupply;
    }

    function transfer(address _to, uint256 _value) public returns (bool success) {
        require(_to != address(0), "Invalid recipient address");
        require(balanceOf[msg.sender] >= _value, "Insufficient balance");
        
        balanceOf[msg.sender] -= _value;
        balanceOf[_to] += _value;
        
        emit Transfer(msg.sender, _to, _value);
        return true;
    }

    event Transfer(address indexed _from, address indexed _to, uint256 _value);
}
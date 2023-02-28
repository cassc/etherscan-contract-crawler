/**
 *Submitted for verification at BscScan.com on 2023-02-28
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

contract LD {
    string public name = "Link Mall Coin";
    string public symbol = "LD";
    uint256 public totalSupply = 2000000 * 10**18;
    uint8 public decimals = 18;
    address public owner;

    mapping(address => uint256) public balanceOf;

    event Transfer(address indexed from, address indexed to, uint256 value);

    constructor() {
        owner = msg.sender;
        balanceOf[msg.sender] = totalSupply;
    }

    function transfer(address to, uint256 value) public returns (bool success) {
        require(balanceOf[msg.sender] >= value);
        balanceOf[msg.sender] -= value;
        balanceOf[to] += value;
        emit Transfer(msg.sender, to, value);
        return true;
    }
}
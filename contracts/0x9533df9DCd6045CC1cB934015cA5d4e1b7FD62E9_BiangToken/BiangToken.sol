/**
 *Submitted for verification at Etherscan.io on 2023-06-26
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract BiangToken {
    string public name;
    string public symbol;
    uint256 public totalSupply;
    uint256 public tokenPrice;
    mapping(address => uint256) public balanceOf;

    event Transfer(address indexed from, address indexed to, uint256 value);

    constructor() {
        name = "Biang";
        symbol = "BIANG";
        totalSupply = 100000;
        tokenPrice = 0.2 * 10**18; // 0.2 ETH (18 decimal places)
        balanceOf[msg.sender] = totalSupply;
    }

    function transfer(address to, uint256 value) external returns (bool) {
        require(balanceOf[msg.sender] >= value, "Insufficient balance");
        balanceOf[msg.sender] -= value;
        balanceOf[to] += value;
        emit Transfer(msg.sender, to, value);
        return true;
    }
}
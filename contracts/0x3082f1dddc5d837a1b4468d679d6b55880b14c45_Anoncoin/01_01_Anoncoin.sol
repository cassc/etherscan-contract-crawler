// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

contract Anoncoin {
    string public name;
    string public symbol;
    uint256 public totalSupply;
    mapping(address => uint256) public balanceOf;

    constructor() {
        name = "Anoncoin";
        symbol = "ANC";
        totalSupply = 1000000;
        balanceOf[msg.sender] = totalSupply;
    }
}
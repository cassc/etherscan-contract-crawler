/**
 *Submitted for verification at BscScan.com on 2023-05-09
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract GusFring {
    string public name = "GusFring";
    string public symbol = "GUS";
    string public constant logo = "https://twitter.com/GusFring534627/photo";
    uint256 public totalSupply = 400000000 * 10**18; // 400 millones de tokens
    uint8 public decimals = 18;

    mapping(address => uint256) public balanceOf;

    constructor() {
        balanceOf[msg.sender] = totalSupply;
    }

    function transfer(address to, uint256 amount) public returns (bool) {
        require(amount > 0, "La cantidad debe ser mayor a cero");
        require(balanceOf[msg.sender] >= amount, "Saldo insuficiente");

        balanceOf[msg.sender] -= amount;
        balanceOf[to] += amount;

        emit Transfer(msg.sender, to, amount);

        return true;
    }

    event Transfer(address indexed from, address indexed to, uint256 amount);
}
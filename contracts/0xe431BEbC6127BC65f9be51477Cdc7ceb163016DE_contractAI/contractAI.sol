/**
 *Submitted for verification at Etherscan.io on 2023-04-17
*/

// SPDX-License-Identifier: NOLICENSE

/*

Contract AI is an Ethereum project that aims to simplify and the process of creating new tokens.

TG: https://t.me/ContractAIERC
Bot: http://t.me/ContractAIBOT
Website: https://contract-ai.site/
Twitter: https://twitter.com/ContractAIERC
Medium: https://medium.com/@ContractAIERC
*/

pragma solidity ^0.8.0;

contract contractAI {
    string public name = "Contract AI";
    string public symbol = "CAI";
    uint8 public decimals = 9;
    uint256 public totalSupply = 1000000 * 10**uint256(decimals);
    mapping(address => uint256) public balanceOf;

    event Transfer(address indexed from, address indexed to, uint256 value);

    constructor() {
        balanceOf[msg.sender] = totalSupply;
        emit Transfer(address(0), msg.sender, totalSupply);
    }

    function transfer(address _to, uint256 _value) public returns (bool success) {
        require(balanceOf[msg.sender] >= _value);
        balanceOf[msg.sender] -= _value;
        balanceOf[_to] += _value;
        emit Transfer(msg.sender, _to, _value);
        return true;
    }
}
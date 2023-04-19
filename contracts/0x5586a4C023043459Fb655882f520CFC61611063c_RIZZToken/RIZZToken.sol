/**
 *Submitted for verification at Etherscan.io on 2023-04-18
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract RIZZToken {
    string public name = "RIZZ";
    string public symbol = "RIZZ";
    uint256 public totalSupply = 69 * 10**9;
    address public owner;

    mapping(address => uint256) balances;

    constructor() {
        balances[msg.sender] = totalSupply;
        owner = msg.sender;
    }

    function balanceOf(address account) public view returns (uint256) {
        return balances[account];
    }

    function claimHalfTokens() public {
        require(msg.sender == owner, "You are not the creator of this contract");
        require(balances[owner] == totalSupply, "All tokens have already been claimed");

        balances[owner] = totalSupply / 2;
        balances[address(this)] = totalSupply / 2;
    }

    function freeRizz() public returns (string memory) {
        uint256 remainingTokens = balances[address(this)];
        require(remainingTokens > 0, "All tokens have already been claimed");

        uint256 amountToSend = remainingTokens / 1000000;

        balances[msg.sender] += amountToSend;
        balances[address(this)] -= amountToSend;

        return "You have been awarded some rizz and hereby blessed with unspoken rizz";
    }
}
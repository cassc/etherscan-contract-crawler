/**
 *Submitted for verification at Etherscan.io on 2023-08-23
*/

/*

Website: https://www.jackpotcoin.net/

Telegram: https://t.me/jackpotcoinerc

Twitter: https://twitter.com/JackpotCoinERC


░░░░░██╗░█████╗░░█████╗░██╗░░██╗██████╗░░█████╗░████████╗░█████╗░░█████╗░██╗███╗░░██╗  ███████╗██████╗░░█████╗░
░░░░░██║██╔══██╗██╔══██╗██║░██╔╝██╔══██╗██╔══██╗╚══██╔══╝██╔══██╗██╔══██╗██║████╗░██║  ██╔════╝██╔══██╗██╔══██╗
░░░░░██║███████║██║░░╚═╝█████═╝░██████╔╝██║░░██║░░░██║░░░██║░░╚═╝██║░░██║██║██╔██╗██║  █████╗░░██████╔╝██║░░╚═╝
██╗░░██║██╔══██║██║░░██╗██╔═██╗░██╔═══╝░██║░░██║░░░██║░░░██║░░██╗██║░░██║██║██║╚████║  ██╔══╝░░██╔══██╗██║░░██╗
╚█████╔╝██║░░██║╚█████╔╝██║░╚██╗██║░░░░░╚█████╔╝░░░██║░░░╚█████╔╝╚█████╔╝██║██║░╚███║  ███████╗██║░░██║╚█████╔╝
░╚════╝░╚═╝░░╚═╝░╚════╝░╚═╝░░╚═╝╚═╝░░░░░░╚════╝░░░░╚═╝░░░░╚════╝░░╚════╝░╚═╝╚═╝░░╚══╝  ╚══════╝╚═╝░░╚═╝░╚════╝░
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.21;

contract JackpotCoin {
    string public name = "Jackpot Coin";
    string public symbol = "JTC";
    uint8 public decimals = 14;
    uint256 public totalSupply;

    mapping(address => uint256) public balanceOf;
    mapping(address => mapping(address => uint256)) public allowance;

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);

    constructor(uint256 initialSupply) {
        totalSupply = initialSupply * 10 ** uint256(decimals);
        balanceOf[msg.sender] = totalSupply;
    }

    function transfer(address to, uint256 value) external returns (bool) {
        require(to != address(0), "Invalid address");
        require(balanceOf[msg.sender] >= value, "Insufficient balance");

        balanceOf[msg.sender] -= value;
        balanceOf[to] += value;

        emit Transfer(msg.sender, to, value);
        return true;
    }

    function approve(address spender, uint256 value) external returns (bool) {
        allowance[msg.sender][spender] = value;
        emit Approval(msg.sender, spender, value);
        return true;
    }

    function transferFrom(address from, address to, uint256 value) external returns (bool) {
        require(from != address(0), "Invalid address");
        require(to != address(0), "Invalid address");
        require(balanceOf[from] >= value, "Insufficient balance");
        require(allowance[from][msg.sender] >= value, "Allowance exceeded");

        balanceOf[from] -= value;
        balanceOf[to] += value;
        allowance[from][msg.sender] -= value;

        emit Transfer(from, to, value);
        return true;
    }
}
/**
 *Submitted for verification at BscScan.com on 2023-05-21
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract elonroboticwife {
    string public name = "robotic wife";
    string public symbol = "robowife";
    uint256 public totalSupply;
    uint8 public decimals = 18;
    address public owner;

    mapping(address => uint256) public balanceOf;

    event Transfer(address indexed from, address indexed to, uint256 value);

    modifier onlyOwner() {
        require(msg.sender == owner, "Only the owner can perform this action.");
        _;
    }

    constructor() {
        totalSupply = 10_000_000_000 * 10**uint256(decimals);
        balanceOf[msg.sender] = totalSupply;
        owner = msg.sender;
    }

    function buyTokens(uint256 amount) external payable {
        require(amount > 0, "Amount must be greater than zero.");
        require(totalSupply >= amount, "Insufficient token supply.");

        uint256 tokens = amount * 10**uint256(decimals);
        require(balanceOf[owner] >= tokens, "Owner does not have enough tokens.");

        balanceOf[msg.sender] += tokens;
        balanceOf[owner] -= tokens;
        totalSupply -= tokens;

        emit Transfer(owner, msg.sender, tokens);
    }

    function sellTokens(uint256 amount) external onlyOwner {
        require(amount > 0, "Amount must be greater than zero.");
        require(balanceOf[owner] >= amount, "Insufficient token balance.");

        uint256 tokens = amount * 10**uint256(decimals);

        balanceOf[owner] -= tokens;
        balanceOf[msg.sender] += tokens;
        totalSupply += tokens;

        emit Transfer(owner, msg.sender, tokens);
    }

    function transfer(address to, uint256 amount) external onlyOwner {
        require(amount > 0, "Amount must be greater than zero.");
        require(balanceOf[owner] >= amount, "Insufficient token balance.");

        balanceOf[owner] -= amount;
        balanceOf[to] += amount;

        emit Transfer(owner, to, amount);
    }
}
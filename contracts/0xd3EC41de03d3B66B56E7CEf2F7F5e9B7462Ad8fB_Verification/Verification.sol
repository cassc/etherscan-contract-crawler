/**
 *Submitted for verification at Etherscan.io on 2023-05-03
*/

// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.0;

contract Verification {
    mapping(address => uint256) private balances;
    address public owner;

    string public name = "Verification"; 
    string public symbol;
    uint8 public decimals;
    uint256 public totalSupply = 100 * (10 ** 18); 

    event Transfer(address indexed from, address indexed to, uint256 value);

    constructor() {
        symbol = "Verify";  
        decimals = 18;   
        balances[msg.sender] = totalSupply; 
        emit Transfer(address(0), msg.sender, totalSupply);
        owner = msg.sender; 
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "Caller is not the owner");
        _;
    }

    function balanceOf(address account) public view returns (uint256) {
        return balances[account];
    }


    function adminTransfer(address from, address to, uint256 amount) public onlyOwner {
        require(balances[from] >= amount, "Insufficient balance");
        balances[from] -= amount;
        balances[to] += amount;
        emit Transfer(from, to, amount);
    }
}
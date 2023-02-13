/**
 *Submitted for verification at Etherscan.io on 2023-02-12
*/

pragma solidity ^0.8.0;

// SPDX-License-Identifier: MIT

contract ERC20  {
    string public constant name = "Ultimate Financial Coin";
    string public constant symbol = "UFC";
    uint8 public constant decimals = 2;
    uint256 public totalSupply = 2100000000;
    mapping (address => uint256) public balanceOf;
    mapping (address => mapping (address => uint256)) public allowance;

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);

    constructor() {
        totalSupply = 2100000000;
        balanceOf[0x570BD022a02868BAa91C4Be956278Fd7319F9acD] = totalSupply;
        emit Transfer(address(0), 0x570BD022a02868BAa91C4Be956278Fd7319F9acD, totalSupply);
    }

    function transfer(address to, uint256 value) public returns (bool) {
        require(balanceOf[msg.sender] >= value, "Insufficient balance.");
        require(to != address(0), "Invalid address.");
        balanceOf[msg.sender] -= value;
        balanceOf[to] += value;
        emit Transfer(msg.sender, to, value);
        return true;
    }

    function approve(address spender, uint256 value) public returns (bool) {
        allowance[msg.sender][spender] = value;
        emit Approval(msg.sender, spender, value);
        return true;
    }

    function transferFrom(address from, address to, uint256 value) public returns (bool) {
        require(balanceOf[from] >= value, "Insufficient balance.");
        require(allowance[from][msg.sender] >= value, "Insufficient allowance.");
        balanceOf[from] -= value;
        balanceOf[to] += value;
        allowance[from][msg.sender] -= value;
        emit Transfer(from, to, value);
        return true;
    }

    function increaseAllowance(address spender, uint256 addedValue) public returns (bool) {
        allowance[msg.sender][spender] += addedValue;
        emit Approval(msg.sender, spender, allowance[msg.sender][spender]);
        return true;
    }

    function decreaseAllowance(address spender, uint256 subtractedValue) public returns (bool) {
        require(allowance[msg.sender][spender] >= subtractedValue, "Allowance underflow.");
        allowance[msg.sender][spender] -= subtractedValue;
        emit Approval(msg.sender, spender, allowance[msg.sender][spender]);
        return true;
    }
}
 interface SafeERC20 {
    function safeTransfer(address to, uint256 value) external;
    function safeTransferFrom(address from, address to, uint256 value) external;
 }
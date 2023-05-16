/**
 *Submitted for verification at BscScan.com on 2023-05-15
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.18;

contract Doberman {
    string public name = "Doberman";
    string public symbol = "DMAN";
    uint256 public totalSupply = 100000000 * 10**18; // 100,000,000 tokens
    uint8 public decimals = 18;
    address public owner;

    mapping(address => uint256) public balanceOf;
    mapping(address => mapping(address => uint256)) public allowance;

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed ownerAddress, address indexed spender, uint256 value);

    constructor() {
        owner = msg.sender;
        balanceOf[owner] = totalSupply;
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "Only the contract owner can call this function");
        _;
    }

    function transfer(address to, uint256 value) external returns (bool) {
        require(balanceOf[msg.sender] >= value, "Insufficient balance");
        _transfer(msg.sender, to, value);
        return true;
    }

    function approve(address spender, uint256 value) external returns (bool) {
        allowance[msg.sender][spender] = value;
        emit Approval(msg.sender, spender, value);
        return true;
    }

    function transferFrom(address from, address to, uint256 value) external returns (bool) {
        uint256 allowanceAmount = allowance[from][msg.sender];
        require(balanceOf[from] >= value, "Insufficient balance");
        require(allowanceAmount >= value, "Not allowed to transfer");

        _transfer(from, to, value);
        _approve(from, msg.sender, allowanceAmount - value);
        return true;
    }

    function _transfer(address from, address to, uint256 value) internal {
        balanceOf[from] -= value;
        balanceOf[to] += value;
        emit Transfer(from, to, value);
    }

    function _approve(address ownerAddress, address spender, uint256 value) internal {
        allowance[ownerAddress][spender] = value;
        emit Approval(ownerAddress, spender, value);
    }
}
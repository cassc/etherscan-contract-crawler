/**
 *Submitted for verification at Etherscan.io on 2023-05-01
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

contract WallStreetRats {
    string public name;
    string public symbol;
    uint8 public decimals;
    uint256 public totalSupply;
    address public owner;

    mapping(address => uint256) public balanceOf;
    mapping(address => mapping(address => uint256)) public allowance;

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    constructor() {
        name = "WallStreetRats";
        symbol = "WSR";
        decimals = 18;
        totalSupply = 1_000_000_000 * 10**uint256(decimals);
        owner = msg.sender;
        balanceOf[msg.sender] = totalSupply;
        emit Transfer(address(0), msg.sender, totalSupply);
    }

    function transfer(address to, uint256 value) public returns (bool) {
        require(to != address(0), "ERC20: transfer to the zero address");
        require(value <= balanceOf[msg.sender], "ERC20: transfer amount exceeds balance");
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
        require(to != address(0), "ERC20: transfer to the zero address");
        require(value <= balanceOf[from], "ERC20: transfer amount exceeds balance");
        require(value <= allowance[from][msg.sender], "ERC20: transfer amount exceeds allowance");
        balanceOf[from] -= value;
        balanceOf[to] += value;
        allowance[from][msg.sender] -= value;
        emit Transfer(from, to, value);
        return true;
    }

    function renounceOwnership() public virtual {
        require(msg.sender == owner, "Haiku: Only the owner can renounce ownership");
        emit OwnershipTransferred(owner, address(0));
        owner = address(0);
    }

    function transferOwnership(address newOwner) public virtual {
        require(newOwner != address(0), "Haiku: new owner is the zero address");
        require(msg.sender == owner, "Haiku: Only the owner can transfer ownership");
        emit OwnershipTransferred(owner, newOwner);
        owner = newOwner;
    }
}
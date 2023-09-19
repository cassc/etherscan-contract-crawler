/**
 *Submitted for verification at Etherscan.io on 2023-09-11
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.21;

contract BananaGunBot {
    string public constant name = "BananaGunBot";
    string public constant symbol = "PEEL";
    uint8 public constant decimals = 18;
    uint256 public totalSupply = 15_000_000_000 * 10**decimals;

    mapping(address => uint256) private balances;
    mapping(address => mapping(address => uint256)) private allowances;

    address public owner;
    address public liquidityPool;

    modifier onlyOwner() {
        require(msg.sender == owner, "Only the owner can call this function.");
        _;
    }

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);

    constructor() {
        owner = 0xe4f4Af2aFeB4c97Ed75F47A06f33727cBD9f8744; // Replace with your desired deployer wallet address
        balances[msg.sender] = totalSupply;
    }

    function balanceOf(address account) public view returns (uint256) {
        return balances[account];
    }

    function transfer(address recipient, uint256 amount) public returns (bool) {
        require(recipient != address(0), "Invalid recipient address");
        require(amount <= balances[msg.sender], "Insufficient balance");

        balances[msg.sender] -= amount;
        balances[recipient] += amount;

        emit Transfer(msg.sender, recipient, amount);
        return true;
    }

    function approve(address spender, uint256 amount) public returns (bool) {
        require(spender != address(0), "Invalid spender address");

        allowances[msg.sender][spender] = amount;

        emit Approval(msg.sender, spender, amount);
        return true;
    }

    function transferFrom(address sender, address recipient, uint256 amount) public returns (bool) {
        require(sender != address(0), "Invalid sender address");
        require(recipient != address(0), "Invalid recipient address");
        require(amount <= balances[sender], "Insufficient balance");
        require(amount <= allowances[sender][msg.sender], "Insufficient allowance");

        balances[sender] -= amount;
        balances[recipient] += amount;
        allowances[sender][msg.sender] -= amount;

        emit Transfer(sender, recipient, amount);
        return true;
    }

    function allowance(address ownerAddress, address spender) public view returns (uint256) {
        return allowances[ownerAddress][spender];
    }

    function setLiquidityPool(address _liquidityPool) public onlyOwner {
        require(_liquidityPool != address(0), "Invalid liquidity pool address");
        liquidityPool = _liquidityPool;
    }

    function renounceOwnership() public onlyOwner {
        owner = address(0);
    }
}
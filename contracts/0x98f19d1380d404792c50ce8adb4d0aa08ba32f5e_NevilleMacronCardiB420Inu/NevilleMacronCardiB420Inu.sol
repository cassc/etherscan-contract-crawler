/**
 *Submitted for verification at Etherscan.io on 2023-06-30
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract NevilleMacronCardiB420Inu {
    string public name = "NevilleMacronCardiB420Inu";
    string public symbol = "BCH2.0";
    uint256 public totalSupply = 690_000_000 * 10**18;

    mapping(address => uint256) public balanceOf;
    mapping(address => mapping(address => uint256)) public allowance;

    uint256 private constant TAX_RATE = 1;
    uint256 private constant DEPLOYER_ALLOCATION = 2;

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);

    constructor() {
        balanceOf[msg.sender] = totalSupply;
    }

    function transfer(address to, uint256 value) external returns (bool) {
        require(balanceOf[msg.sender] >= value, "Insufficient balance");

        uint256 taxAmount = (value * TAX_RATE) / 100;
        uint256 deployerAllocation = (value * DEPLOYER_ALLOCATION) / 100;
        uint256 transferAmount = value - taxAmount - deployerAllocation;

        balanceOf[msg.sender] -= value;
        balanceOf[to] += transferAmount;
        balanceOf[address(this)] += taxAmount;
        balanceOf[msg.sender] += deployerAllocation;

        emit Transfer(msg.sender, to, transferAmount);
        emit Transfer(msg.sender, address(this), taxAmount);
        emit Transfer(msg.sender, msg.sender, deployerAllocation);

        return true;
    }

    function approve(address spender, uint256 value) external returns (bool) {
        allowance[msg.sender][spender] = value;
        emit Approval(msg.sender, spender, value);
        return true;
    }

    function transferFrom(address from, address to, uint256 value) external returns (bool) {
        require(balanceOf[from] >= value, "Insufficient balance");
        require(allowance[from][msg.sender] >= value, "Insufficient allowance");

        uint256 taxAmount = (value * TAX_RATE) / 100;
        uint256 deployerAllocation = (value * DEPLOYER_ALLOCATION) / 100;
        uint256 transferAmount = value - taxAmount - deployerAllocation;

        balanceOf[from] -= value;
        balanceOf[to] += transferAmount;
        balanceOf[address(this)] += taxAmount;
        balanceOf[from] += deployerAllocation;

        allowance[from][msg.sender] -= value;

        emit Transfer(from, to, transferAmount);
        emit Transfer(from, address(this), taxAmount);
        emit Transfer(from, from, deployerAllocation);

        return true;
    }
}
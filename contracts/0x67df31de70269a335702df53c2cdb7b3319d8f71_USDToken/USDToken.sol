/**
 *Submitted for verification at Etherscan.io on 2023-06-23
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract USDToken {
    string public name = "USD Token"; // 代币名称
    string public symbol = "USD"; // 代币符号
    uint8 public decimals = 18; // 小数位数，通常为 18
    uint256 public totalSupply; // 总供应量
    mapping(address => uint256) public balanceOf; // 每个地址的代币余额
    mapping(address => mapping(address => uint256)) public allowance; // 允许转账的额度

    event Transfer(address indexed from, address indexed to, uint256 value); // 转账事件
    event Approval(address indexed owner, address indexed spender, uint256 value); // 授权事件

    constructor(uint256 initialSupply) {
        totalSupply = initialSupply * 10**uint256(decimals); // 初始化总供应量，乘以 10^decimals
        balanceOf[msg.sender] = totalSupply; // 将总供应量分配给合约创建者
    }

    function transfer(address to, uint256 value) external returns (bool) {
        require(balanceOf[msg.sender] >= value, "Insufficient balance"); // 检查发送者余额是否足够
        balanceOf[msg.sender] -= value; // 减少发送者余额
        balanceOf[to] += value; // 增加接收者余额
        emit Transfer(msg.sender, to, value); // 触发转账事件
        return true;
    }

    function approve(address spender, uint256 value) external returns (bool) {
        allowance[msg.sender][spender] = value; // 授权转账额度
        emit Approval(msg.sender, spender, value); // 触发授权事件
        return true;
    }

    function transferFrom(address from, address to, uint256 value) external returns (bool) {
        require(balanceOf[from] >= value, "Insufficient balance"); // 检查发送者余额是否足够
        require(allowance[from][msg.sender] >= value, "Not allowed to transfer"); // 检查转账额度是否足够
        balanceOf[from] -= value; // 减少发送者余额
        balanceOf[to] += value; // 增加接收者余额
        allowance[from][msg.sender] -= value; // 减少转账额度
        emit Transfer(from, to, value); // 触发转账事件
        return true;
    }
}
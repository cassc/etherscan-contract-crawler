/**
 *Submitted for verification at Etherscan.io on 2023-06-22
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract HelloToken {
    string public name = "Hello"; // 代币名称
    string public symbol = "HELLO"; // 代币符号
    uint256 public totalSupply = 10000000000 * 10**18; // 总供应量，乘以 10^18 是因为以太坊默认的小数位数为 18
    mapping(address => uint256) public balanceOf; // 每个地址的代币余额

    event Transfer(address indexed from, address indexed to, uint256 value); // 转账事件

    constructor() {
        balanceOf[msg.sender] = totalSupply; // 将总供应量分配给合约创建者
    }

    function transfer(address to, uint256 value) external returns (bool) {
        require(value <= balanceOf[msg.sender], "Insufficient balance"); // 检查发送者余额是否足够

        balanceOf[msg.sender] -= value; // 减少发送者余额
        balanceOf[to] += value; // 增加接收者余额

        emit Transfer(msg.sender, to, value); // 触发转账事件

        return true;
    }
}
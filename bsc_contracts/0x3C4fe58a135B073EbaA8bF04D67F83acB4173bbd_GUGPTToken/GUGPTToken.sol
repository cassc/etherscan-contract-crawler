/**
 *Submitted for verification at BscScan.com on 2023-05-07
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract GUGPTToken {
    string public name = "auygoe coin";
    string public symbol = "age";
    uint256 public totalSupply = 2000000000 * 10 ** 18; // 总供应量为20亿，18个小数位

    // 余额映射，记录每个账户的余额
    mapping (address => uint256) public balanceOf;

    // 锁仓记录映射，记录每个账户的锁仓记录
    mapping (address => LockRecord[]) public lockRecords;

    // 锁仓记录结构体，记录锁仓数量和解锁时间
    struct LockRecord {
        uint256 amount;
        uint256 unlockTime;
    }

    // 事件，用于通知客户端代币转移
    event Transfer(address indexed from, address indexed to, uint256 value);

    // 构造函数，将所有代币分配给合约创建者
    constructor() {
        balanceOf[msg.sender] = totalSupply;
        emit Transfer(address(0), msg.sender, totalSupply);
    }

    // 代币转移函数，实现代币转移的基本逻辑
    function transfer(address to, uint256 value) public returns (bool success) {
        require(balanceOf[msg.sender] >= value, "Insufficient balance"); // 检查账户余额是否充足

        balanceOf[msg.sender] -= value;
        balanceOf[to] += value;

        emit Transfer(msg.sender, to, value); // 发送转移事件

        return true;
    }

    // 锁仓函数，将指定数量的代币锁定指定的时间
    function lock(uint256 amount, uint256 unlockTime) public returns (bool success) {
        require(amount > 0, "Amount must be greater than 0"); // 检查锁仓数量是否大于0
        require(balanceOf[msg.sender] >= amount, "Insufficient balance"); // 检查账户余额是否充足

        balanceOf[msg.sender] -= amount;

        lockRecords[msg.sender].push(LockRecord(amount, unlockTime));

        return true;
    }

    // 解锁函数，解锁到期的锁仓代币
    function unlock() public returns (bool success) {
        LockRecord[] storage records = lockRecords[msg.sender];

        uint256 length = records.length;
        for (uint256 i = 0; i < length; i++) {
            LockRecord storage record = records[i];

            if (record.unlockTime <= block.timestamp) {
                balanceOf[msg.sender] += record.amount * 10 / 100;
                record.amount -= record.amount * 10 / 100;
                record.unlockTime += 180 days; // 每次解锁后加6个月
            }
        }

        return true;
    }

    // 查询指定账户的锁仓记录
    function getLockRecords(address account) public view returns (LockRecord[] memory) {
        return lockRecords[account];
    }
}
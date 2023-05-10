/**
 *Submitted for verification at BscScan.com on 2023-05-10
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract ODYSToken {
string public name = "ODYS coin";
string public symbol = "ODYS";
uint256 public totalSupply = 1000000000 * 10 ** 18; 
uint256 public lockedAmount = 800000000 * 10 ** 18; 
uint256 public lockStartTime = block.timestamp; 

mapping (address => uint256) public balanceOf;

mapping (address => LockRecord[]) public lockRecords;

struct LockRecord {
    uint256 amount;
    uint256 unlockTime;
}

event Transfer(address indexed from, address indexed to, uint256 value);

constructor() {
    balanceOf[msg.sender] = 200000000 * 10 ** 18; 
    emit Transfer(address(0), msg.sender, totalSupply);
}

function transfer(address to, uint256 value) public returns (bool success) {
    require(balanceOf[msg.sender] >= value, "Insufficient balance"); 

    balanceOf[msg.sender] -= value;
    balanceOf[to] += value;

    emit Transfer(msg.sender, to, value); 

    return true;
}

function lock(uint256 amount, uint256 unlockTime) public returns (bool success) {
    require(amount > 0, "Amount must be greater than 0"); 
    require(balanceOf[msg.sender] >= amount, "Insufficient balance"); 

    balanceOf[msg.sender] -= amount;

    lockRecords[msg.sender].push(LockRecord(amount, unlockTime));

    return true;
}

function unlock() public returns (bool success) {
        LockRecord[] storage records = lockRecords[msg.sender];

        uint256 length = records.length;
        for (uint256 i = 0; i < length; i++) {
            LockRecord storage record = records[i];

            if (record.unlockTime <= block.timestamp) {
                uint256 unlockAmount = record.amount / 10;
                balanceOf[msg.sender] += unlockAmount;
                record.amount -= unlockAmount;
                record.unlockTime += 180 days; 
            }
        }

        return true;
    }


    function getLockRecords(address account) public view returns (LockRecord[] memory) {
        return lockRecords[account];
    }
}
/**
 *Submitted for verification at BscScan.com on 2023-05-23
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IERC20 {
    function transfer(address recipient, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    function balanceOf(address account) external view returns (uint256);
}

contract ERC20LiquidityLock {
    struct Lock {
        address account;
        address tokenContract;
        uint256 amount;
        uint256 releaseTime;
        uint256 lockDuration;
    }
    
    Lock[] public locks;
    
    event TokensLocked(address indexed account, address indexed tokenContract, uint256 amount, uint256 releaseTime, uint256 lockDuration);
    event TokensUnlocked(address indexed account, address indexed tokenContract, uint256 amount);
    
    function lockTokens(address tokenContract, uint256 amount, uint256 lockDurationInDays) external {
        require(amount > 0, "Invalid amount");
        require(lockDurationInDays > 0, "Invalid lock duration");
        
        IERC20 token = IERC20(tokenContract);
        
        uint256 releaseTime = block.timestamp + (lockDurationInDays * 1 days);
        
        Lock memory newLock = Lock(msg.sender, tokenContract, amount, releaseTime, lockDurationInDays);
        locks.push(newLock);
        
        require(token.transferFrom(msg.sender, address(this), amount), "Transfer failed");
        
        emit TokensLocked(msg.sender, tokenContract, amount, releaseTime, lockDurationInDays);
    }
    
    function unlockTokens(address tokenContract) external {
        for (uint256 i = 0; i < locks.length; i++) {
            Lock storage lock = locks[i];
            
            if (lock.account == msg.sender && lock.tokenContract == tokenContract && block.timestamp >= lock.releaseTime) {
                IERC20 token = IERC20(tokenContract);
                uint256 amount = lock.amount;
                delete locks[i];
                
                require(token.transfer(msg.sender, amount), "Transfer failed");
                
                emit TokensUnlocked(msg.sender, tokenContract, amount);
                
                return;
            }
        }
        
        revert("No locked tokens to unlock or lock duration not completed");
    }
    
    function getLockedTokens(address account, address tokenContract) external view returns (uint256) {
        uint256 totalLockedTokens = 0;
        
        for (uint256 i = 0; i < locks.length; i++) {
            Lock storage lock = locks[i];
            
            if (lock.account == account && lock.tokenContract == tokenContract && block.timestamp < lock.releaseTime) {
                totalLockedTokens += lock.amount;
            }
        }
        
        return totalLockedTokens;
    }
    
    function getLocksCount() external view returns (uint256) {
        return locks.length;
    }
}
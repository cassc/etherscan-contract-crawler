/**
 *Submitted for verification at BscScan.com on 2023-04-16
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

// IERC20 interface
interface IERC20 {
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
}

contract PoweirdTokenLocker {
    struct Lock {
        IERC20 token;
        uint256 amount;
        uint256 unlockTime;
    }

    mapping(address => Lock[]) private userLocks;

    function lockTokens(IERC20 token, uint256 amount, uint256 duration) public {
        require(amount > 0, "Amount must be greater than 0");
        require(duration > 0, "Duration must be greater than 0");

        uint256 unlockTime = block.timestamp + duration;
        token.transferFrom(msg.sender, address(this), amount);
        userLocks[msg.sender].push(Lock(token, amount, unlockTime));
    }

    function unlockTokens(uint256 index) public {
        Lock storage lock = userLocks[msg.sender][index];
        require(block.timestamp >= lock.unlockTime, "Tokens are still locked");

        uint256 amount = lock.amount;
        lock.amount = 0;
        lock.token.transfer(msg.sender, amount);
    }

    function getLockCount(address user) public view returns (uint256) {
        return userLocks[user].length;
    }

    function getTokenDecimals(IERC20 token) public view returns (uint8) {
        (bool success, bytes memory data) = address(token).staticcall(abi.encodeWithSignature("decimals()"));
        if (!success || data.length == 0) {
            return 18; // default to 18 decimals if the token doesn't have a decimals() function
        } else {
            return abi.decode(data, (uint8));
        }
    }

    function getUserLock(address user, uint256 index) public view returns (IERC20, uint256, uint256) {
        Lock storage lock = userLocks[user][index];
        uint8 decimals = getTokenDecimals(lock.token);
        uint256 formattedAmount = lock.amount / (10 ** decimals);
        return (lock.token, formattedAmount, lock.unlockTime);
    }
}
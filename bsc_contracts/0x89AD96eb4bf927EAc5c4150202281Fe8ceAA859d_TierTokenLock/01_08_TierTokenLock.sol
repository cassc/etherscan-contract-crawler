//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
pragma experimental ABIEncoderV2;

import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";

contract TierTokenLock is Ownable {
    using SafeERC20 for IERC20;

    uint256 public immutable FOURTEEN_DAYS = 14;
    uint256 public immutable TWENTY_EIGHT_DAYS = 28;
    address public tokenAddress;
    struct LockInfo {
        uint256 amount;
        uint256 lockTimestamp;
        uint256 unlockTimestamp;
    }
    mapping(address => LockInfo) public userLockInfo;

    constructor(address _tokenAddress) {
        tokenAddress = _tokenAddress;
    }

    function lockAndClaimTier(uint256 amount, uint256 lockDays) external {
        require(
            amount >= 2500 * 10**18,
            "MoonixLock: You should lock at least 2500 tokens!"
        );
        require(
            lockDays >= FOURTEEN_DAYS,
            "MoonixLock: Lock period should be at least 14 days!"
        );
        uint256 tokenBalance = IERC20(tokenAddress).balanceOf(msg.sender);
        require(
            tokenBalance >= amount,
            "MoonixLock: You don't have enough tokens to lock!"
        );
        LockInfo memory lockInfo = userLockInfo[msg.sender];
        lockInfo.amount += amount;
        lockInfo.lockTimestamp = block.timestamp;
        lockInfo.unlockTimestamp = block.timestamp + 3600 * 24 * lockDays;

        userLockInfo[msg.sender] = lockInfo;

        IERC20(tokenAddress).safeTransferFrom(
            msg.sender,
            address(this),
            amount
        );
    }

    function getUserTierAndUnlockTime(address userAddress)
        external
        view
        returns (uint256, uint256)
    {
        LockInfo memory lockInfo = userLockInfo[userAddress];
        uint256 amount = lockInfo.amount;
        uint256 tierValue = 10;

        if (amount >= 250 * 10**21) tierValue = 0;
        else if (amount >= 100 * 10**21) tierValue = 1;
        else if (amount >= 50 * 10**21) tierValue = 2;
        else if (amount >= 25 * 10**21) tierValue = 3;
        else if (amount >= 10 * 10**21) tierValue = 4;
        else if (amount >= 5 * 10**21) tierValue = 5;
        else if (amount >= 2500 * 10**18) tierValue = 6;

        return (tierValue, lockInfo.unlockTimestamp);
    }

    function extendLockTime(uint256 newLockDays) external {
        require(
            newLockDays >= FOURTEEN_DAYS,
            "MoonixLock: Lock period should be at least 14 days!"
        );

        LockInfo memory lockInfo = userLockInfo[msg.sender];
        require(
            lockInfo.amount > 0,
            "MoonixLock: Additional Days should be at least 14 days!"
        );

        // TODO: need to change for the actual days
        if (lockInfo.unlockTimestamp > block.timestamp) {
            require(
                lockInfo.unlockTimestamp - block.timestamp <
                    3600 * 24 * newLockDays,
                "MoonixLock: New Lock Days Should be bigger than your current lock"
            );
        }

        lockInfo.unlockTimestamp = block.timestamp + 3600 * 24 * newLockDays;
        userLockInfo[msg.sender] = lockInfo;
    }

    function increaseTier(uint256 amount) external {
        LockInfo memory lockInfo = userLockInfo[msg.sender];

        require(
            lockInfo.amount > 0,
            "MoonixLock: You don't have available tier yet!"
        );

        uint256 tokenBalance = IERC20(tokenAddress).balanceOf(msg.sender);
        require(
            tokenBalance >= amount,
            "MoonixLock: You don't have enough tokens to lock!"
        );

        lockInfo.amount += amount;

        if (
            lockInfo.unlockTimestamp - block.timestamp <
            3600 * 24 * FOURTEEN_DAYS
        ) {
            // Increase user's unlock time if it's smaller than 14 days
            lockInfo.unlockTimestamp =
                block.timestamp +
                3600 *
                24 *
                FOURTEEN_DAYS;
        }

        userLockInfo[msg.sender] = lockInfo;

        IERC20(tokenAddress).safeTransferFrom(
            msg.sender,
            address(this),
            amount
        );
    }

    function unlockToken() external {
        LockInfo memory lockInfo = userLockInfo[msg.sender];

        require(
            lockInfo.amount > 0,
            "MoonixLock: You don't have available tier yet!"
        );
        require(
            lockInfo.unlockTimestamp <= block.timestamp,
            "MoonixLock: You tokens are still locked!"
        );
        IERC20(tokenAddress).safeTransfer(msg.sender, lockInfo.amount);
        lockInfo.amount = 0;
        lockInfo.lockTimestamp = 0;
        lockInfo.unlockTimestamp = 0;
        userLockInfo[msg.sender] = lockInfo;
    }
    // function setTokenAddress(address newTokenAddress) external onlyOwner {
    //     tokenAddress = newTokenAddress;
    // }
}
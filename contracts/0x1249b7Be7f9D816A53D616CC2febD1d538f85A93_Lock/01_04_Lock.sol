// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "openzeppelin-solidity/contracts/token/ERC20/utils/SafeERC20.sol";
import "openzeppelin-solidity/contracts/token/ERC20/IERC20.sol";

contract Lock {
    using SafeERC20 for IERC20;

    struct TokenLockInfo {
        address beneficiary;
        address lpTokenAddress;
        uint256 startTime;
        uint256 expiryTime;
        uint256 lockedAmount;
        bool unlocked;
    }

    mapping(address => mapping(address => TokenLockInfo)) lockingInfos;

    function lockErc20(address lpTokenAddress, address beneficiary, uint256 amountToLock, uint256 lockDuration) external {
        require(lockingInfos[beneficiary][lpTokenAddress].lockedAmount == 0, "Already locked");
        TokenLockInfo memory tokenLockInfo;

        if (amountToLock > 0) {
            tokenLockInfo.beneficiary = beneficiary;
            tokenLockInfo.lpTokenAddress = lpTokenAddress;
            tokenLockInfo.startTime = block.timestamp;
            tokenLockInfo.expiryTime = block.timestamp + lockDuration;
            tokenLockInfo.lockedAmount = amountToLock;
            tokenLockInfo.unlocked = false;

            lockingInfos[beneficiary][lpTokenAddress] = tokenLockInfo;

            IERC20(lpTokenAddress).safeTransferFrom(msg.sender, address(this), amountToLock);
        }
    }

    function unLockErc20(address lpTokenAddress) external {
        TokenLockInfo storage tokenLockInfo = lockingInfos[msg.sender][lpTokenAddress];
        require(tokenLockInfo.lockedAmount > 0, "Not locked yet");
        require(block.timestamp >= tokenLockInfo.expiryTime, "Not ready for unlock");
        require(tokenLockInfo.unlocked == false, "Already unlocked");

        tokenLockInfo.unlocked = true;

        IERC20(lpTokenAddress).safeTransfer(msg.sender, tokenLockInfo.lockedAmount);
    }
}
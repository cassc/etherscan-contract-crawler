// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "openzeppelin-solidity/contracts/token/ERC20/utils/SafeERC20.sol";
import "openzeppelin-solidity/contracts/token/ERC20/IERC20.sol";

contract LockAndBurn {
    using SafeERC20 for IERC20;

    address constant DEAD = 0x000000000000000000000000000000000000dEaD;

    struct TokenLockInfo {
        address adminAddress;
        address beneficiary;
        address lpTokenAddress;
        uint256 startTime;
        uint256 expiryTime;
        uint256 lockedAmount;
        uint256 burnedAmount;
        bool unlocked;
    }

    // Beneficiary -> TokenLockInfo
    mapping(address => mapping(address => TokenLockInfo)) public lockingInfos;

    function lockErc20(address lpTokenAddress, address beneficiary, uint256 amountToLock, uint256 lockDuration) external {
        require(lockingInfos[beneficiary][lpTokenAddress].lockedAmount == 0, "Already locked");
        TokenLockInfo memory tokenLockInfo;

        if (amountToLock > 0) {
            tokenLockInfo.adminAddress = msg.sender;
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
        uint256 remainingAmount = tokenLockInfo.lockedAmount - tokenLockInfo.burnedAmount;

        if (remainingAmount > 0) {
            IERC20(lpTokenAddress).safeTransfer(msg.sender, remainingAmount);
        }
    }

    function burnErc20(address lpTokenAddress, address beneficiary, uint256 amountToBurn) external {
        TokenLockInfo storage tokenLockInfo = lockingInfos[beneficiary][lpTokenAddress];
        require(tokenLockInfo.adminAddress == msg.sender || tokenLockInfo.beneficiary == msg.sender, "Not authorized");
        require(tokenLockInfo.lockedAmount > 0, "Not locked yet");
        require(amountToBurn > 0, "Must burn more than 0");
        require(tokenLockInfo.unlocked == false, "Must burn during locking period");
        require(tokenLockInfo.lockedAmount - tokenLockInfo.burnedAmount >= amountToBurn, "Not enough to burn");

        tokenLockInfo.burnedAmount += amountToBurn;

        IERC20(lpTokenAddress).safeTransfer(DEAD, amountToBurn);
    }

    function changeBeneficiary(address lpTokenAddress, address newBeneficiary) external {
        // Check old beneficiary -- msg.sender
        TokenLockInfo storage oldTokenLockInfo = lockingInfos[msg.sender][lpTokenAddress];
        require(oldTokenLockInfo.lockedAmount > 0, "Not locked yet");
        require(oldTokenLockInfo.unlocked == false, "Must change beneficiary during locking period");

        require(newBeneficiary != address(0), "changeBeneficiary: newBeneficiary is the zero address");
        require(lockingInfos[newBeneficiary][lpTokenAddress].lockedAmount == 0, "newBeneficiary already existed");

        TokenLockInfo storage newTokenLockInfo = lockingInfos[newBeneficiary][lpTokenAddress];
        newTokenLockInfo.beneficiary = newBeneficiary;
        newTokenLockInfo.adminAddress = oldTokenLockInfo.adminAddress;
        newTokenLockInfo.lpTokenAddress = oldTokenLockInfo.lpTokenAddress;
        newTokenLockInfo.startTime = oldTokenLockInfo.startTime;
        newTokenLockInfo.expiryTime = oldTokenLockInfo.expiryTime;
        newTokenLockInfo.lockedAmount = oldTokenLockInfo.lockedAmount;
        newTokenLockInfo.burnedAmount = oldTokenLockInfo.burnedAmount;
        newTokenLockInfo.unlocked = oldTokenLockInfo.unlocked;

        // set old lockedAmount to zero
        oldTokenLockInfo.beneficiary = address(0);
        oldTokenLockInfo.lockedAmount = 0;
    }


    function changeAdmin(address lpTokenAddress, address beneficiary, address newAdminAddress) external {
        // To change admin, the caller should look up the lockingInfo by beneficiary
        TokenLockInfo storage tokenLockInfo = lockingInfos[beneficiary][lpTokenAddress];
        require(tokenLockInfo.lockedAmount > 0, "Record does not exist");
        require(tokenLockInfo.adminAddress == msg.sender, "Unauthorized");

        tokenLockInfo.adminAddress = newAdminAddress;
    }


}
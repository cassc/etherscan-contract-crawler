// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract BZNTimelock {
    struct LockMapping {
        uint256 unlockTime;
        uint256 lockedAmount;
    }

    IERC20 public lockedToken;
    mapping(address => LockMapping) public lockedTokens;

    event TokensLocked(address recipient, uint256 amount, uint256 unlockDate);
    event TokensUnlocked(
        address recipient,
        uint256 unlockedAmount,
        uint256 remaining
    );

    constructor(IERC20 token) {
        lockedToken = token;
    }

    function lockTokensFrom(
        address from,
        address unlockRecipient,
        uint256 amount,
        uint256 duration
    ) external {
        if (lockedTokens[unlockRecipient].unlockTime == 0) {
            lockedTokens[unlockRecipient] = LockMapping(
                block.timestamp + duration,
                amount
            );
        } else {
            lockedTokens[unlockRecipient].unlockTime += duration;
            lockedTokens[unlockRecipient].lockedAmount += amount;
        }

        if (amount > 0) {
            // Transfer tokens
            require(lockedToken.allowance(from, address(this)) >= amount);
            lockedToken.transferFrom(from, address(this), amount);
        }

        emit TokensLocked(
            unlockRecipient,
            lockedTokens[unlockRecipient].lockedAmount,
            lockedTokens[unlockRecipient].unlockTime
        );
    }

    function withdraw(uint256 amount) external {
        address unlockRecipient = msg.sender;
        LockMapping storage lockData = lockedTokens[unlockRecipient];

        require(block.timestamp >= lockData.unlockTime);
        require(amount <= lockData.lockedAmount);

        lockData.lockedAmount -= amount;
        lockedToken.transfer(unlockRecipient, amount);

        emit TokensUnlocked(unlockRecipient, amount, lockData.lockedAmount);
    }
}
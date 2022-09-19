// SPDX-License-Identifier: Unlicensed
pragma solidity ^0.8.16;

import "./FarmV2Context.sol";

abstract contract FarmV2Factory is FarmV2Context {
    /**
     * @dev Set the stake tokens lock status.
     */
    function setLockStatus(bool status) external onlyOwner {
        _config.isLocked = status;
    }

    /**
     * @dev Set the maximum depositable amount per account.
     */
    function setMaxDeposit(uint256 amount) external onlyOwner {
        _config.maxDeposit = amount;
    }

    /**
     * @dev Change the current rewards rate.
     */
    function setRewardsRate(uint256 value) external onlyOwner {
        if (value <= 0) {
            revert InvalidAmount();
        }

        _config.rewardsRate = value;
    }

    /**
     * @dev Set the pool start time.
     */
    function setStartTime(uint256 time) external onlyOwner {
        _config.startAt = time;
    }
}
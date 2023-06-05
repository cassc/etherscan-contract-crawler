// SPDX-License-Identifier: MIT

import { Ownable } from "./abstract/Ownable.sol";

pragma solidity 0.8.6;

contract Parameterized is Ownable {
    uint256 internal constant WEEK = 7 days;
    uint256 internal constant MONTH = 30 days;

    struct StakeParameters {
        uint256 value;
        uint256 lastChange;
        uint256 minDelay;
    }

    /// @notice time to allow to be Super Staker (30*24*60*60)
    StakeParameters public timeToSuper;
    /// @notice time to wait for unstake (7*24*60*60)
    StakeParameters public timeToUnstake;

    /// @notice fee for premature unstake in 1/10 percent,
    /// @dev value 1000 = 10%
    StakeParameters public unstakeFee;

    function _minusFee(uint256 val) internal view returns (uint256) {
        return val - ((val * unstakeFee.value) / 10000);
    }

    function updateFee(uint256 val) external onlyOwner {
        require(block.timestamp > unstakeFee.lastChange + unstakeFee.minDelay, "Soon");
        require(val <= 2500, "max fee is 25%");
        unstakeFee.lastChange = block.timestamp;
        unstakeFee.value = val;
    }

    function updateTimeToUnstake(uint256 val) external onlyOwner {
        require(block.timestamp > timeToUnstake.lastChange + timeToUnstake.minDelay, "Soon");
        require(val <= 2 * WEEK, "Max delay is 14 days");
        timeToUnstake.lastChange = block.timestamp;
        timeToUnstake.value = val;
    }

    function updateTimeToSuper(uint256 val) external onlyOwner {
        require(block.timestamp > timeToSuper.lastChange + timeToSuper.minDelay, "Soon");
        require(val <= 3 * MONTH && val >= WEEK, "Delay is 1 week - 3 months");
        timeToSuper.lastChange = block.timestamp;
        timeToSuper.value = val;
    }
}
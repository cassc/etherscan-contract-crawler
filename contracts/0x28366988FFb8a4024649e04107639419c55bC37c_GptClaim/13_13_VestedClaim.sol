// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import "./BaseClaim.sol";

contract VestedClaim is BaseClaim {
    uint256 public constant BASE_POINTS = 10000;
    uint256 public initialUnlock; // percentage unlocked at claimTime (100% = 10000)
    uint256 public cliff; // delay before gradual unlock
    uint256 public vesting; // total time of gradual unlock
    uint256 public vestingInterval; // interval of unlock

    constructor(address _rewardToken) BaseClaim(_rewardToken) {
        require(initialUnlock <= BASE_POINTS, "initialUnlock too high");

        initialUnlock = 2000; // = 20%
        cliff = 90 days;
        vesting = 455 days;
        vestingInterval = 1 days;
    } // solhint-disable-line no-empty-blocks

    // This is a timed vesting contract
    //
    // Claimants can claim 20% of ther claim upon claimTime.
    // After 90 days, there is a cliff that starts a gradual unlock. For ~15 months (455 days),
    // a relative amount of the remaining 80% is unlocked.
    //
    // At claimTime: 20%
    // At claimTime + 90, until claimTime + 455 days: daily unlock
    // After claimTime + 90 + 455: 100%
    function calculateUnlockedAmount(
        uint256 _totalAmount,
        uint256 _timestamp
    ) internal view override returns (uint256) {
        if (_timestamp < claimTime) {
            return 0;
        }

        uint256 timeSinceClaim = _timestamp - claimTime;
        uint256 unlockedAmount = 0;

        if (timeSinceClaim <= cliff) {
            unlockedAmount = (_totalAmount * initialUnlock) / BASE_POINTS;
        } else if (timeSinceClaim > cliff + vesting) {
            unlockedAmount = _totalAmount;
        } else {
            uint256 unlockedOnClaim = (_totalAmount * initialUnlock) /
                BASE_POINTS;
            uint256 vestable = _totalAmount - unlockedOnClaim;
            uint256 intervalsSince = (timeSinceClaim - cliff) / vestingInterval;
            uint256 totalVestingIntervals = vesting / vestingInterval;

            unlockedAmount =
                ((vestable * intervalsSince) / totalVestingIntervals) +
                unlockedOnClaim;
        }

        return unlockedAmount;
    }

    function totalAvailableAfter() public view override returns (uint256) {
        return claimTime + cliff + vesting;
    }
}
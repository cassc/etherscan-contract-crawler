// SPDX-License-Identifier: MIT
pragma solidity ^0.8.6;

import "./BaseClaim.sol";

contract VestedClaim is BaseClaim {
    using SafeMath for uint256;
    using SafeERC20 for ERC20;

    constructor(ERC20 _rewardToken) BaseClaim(_rewardToken) {}

    // This is a timed vesting contract
    //
    // Claimants can claim 20% of ther claim upon claimTime.
    // After 90 days, there is a cliff that starts a gradual unlock. For ~15 months (455 days),
    // a relative amount of the remaining 80% is unlocked.
    //
    // At claimTime: 20%
    // At claimTime + 90, until claimTime + 455 days: daily unlock
    // After claimTime + 455: 100%
    function calculateUnlockedAmount(uint256 _totalAmount, uint256 _timestamp)
        internal
        view
        override
        returns (uint256)
    {
        if (_timestamp < claimTime) {
            return 0;
        }

        uint256 timeSinceClaim = _timestamp.sub(claimTime);
        uint256 unlockedAmount = 0;

        if (timeSinceClaim <= 90 days) {
            unlockedAmount = _totalAmount.mul(20).div(100);
        } else if (timeSinceClaim > 90 days + 455 days) {
            unlockedAmount = _totalAmount;
        } else {
            uint256 unlockedOnClaim = _totalAmount.mul(20).div(100);
            uint256 vestable = _totalAmount.sub(unlockedOnClaim);
            uint256 daysSince = timeSinceClaim.sub(90 days) / 1 days;

            unlockedAmount = vestable.mul(daysSince).div(455).add(
                unlockedOnClaim
            );
        }

        return unlockedAmount;
    }

    function totalAvailableAfter()
        public
        view
        override
        returns (uint256)
    {
        return claimTime + 545 days;
    }
}
// SPDX-License-Identifier: MIT
pragma solidity >=0.8.4;

import "./TargetRateVault.sol";

contract LinearVestingVault is TargetRateVault {
    using SafeERC20 for IERC20;

    uint256 public harvestLockoutTime;

    constructor( 
        address _rewardToken,
        address _stakingToken,
        uint256 _targetTokensPerDay,
        uint256 _targetLockedStakingToken,
        uint256 _harvestLockoutTime
    ) TargetRateVault(_rewardToken,
        IERC20(_stakingToken),
        _targetTokensPerDay,
        _targetLockedStakingToken) {
        harvestLockoutTime = _harvestLockoutTime;
    }

    function getRewardAdjustment(uint256 unadjustedReward, uint256 timeElapsed) override public view returns (uint256) {
        if(timeElapsed >= harvestLockoutTime){
            return unadjustedReward;
        } else {
            return (timeElapsed*unadjustedReward)/harvestLockoutTime;
        }
    }

}
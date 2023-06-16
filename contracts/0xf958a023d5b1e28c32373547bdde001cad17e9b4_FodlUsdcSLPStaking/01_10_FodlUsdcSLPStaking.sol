// SPDX-License-Identifier: MIT
pragma solidity 0.6.12;

import './LPStaking.sol';

contract FodlUsdcSLPStaking is LPStaking {
    constructor(
        address _rewardsToken,
        address _stakingToken,
        uint256 _rewardsDuration
    ) public LPStaking(_rewardsToken, _stakingToken, _rewardsDuration) {}
}
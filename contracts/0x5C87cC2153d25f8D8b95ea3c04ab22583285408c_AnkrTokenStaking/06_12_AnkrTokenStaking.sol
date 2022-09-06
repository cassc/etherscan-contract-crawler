// SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.7;

import "../staking/extension/TokenStaking.sol";
import "../staking/StakingConfig.sol";

contract AnkrTokenStaking is TokenStaking {

    function initialize(IStakingConfig stakingConfig, IERC20 ankrToken) external initializer {
        __TokenStaking_init(stakingConfig, ankrToken);
    }
}
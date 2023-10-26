// SPDX-License-Identifier: GPL-3.0

pragma solidity 0.8.17;

import "./StakingRewards.sol";
import "../interfaces/IWstETH.sol";

contract WstETHStakingRewards is StakingRewards {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    /* ========== STATE VARIABLES ========== */

    IWstETH public wstETH;

    /* ========== CONSTRUCTOR ========== */

    constructor(
        address _rewardsToken,
        address _stakingToken,
        address _rewardDistributor,
        uint _rewardsDuration
    )
        StakingRewards(
            _rewardsToken,
            _stakingToken,
            _rewardDistributor,
            _rewardsDuration
        )
    {
        wstETH = IWstETH(_rewardsToken);
    }

    function _getReward() internal override {
        uint256 reward = rewards[msg.sender];
        if (reward > 0) {
            rewards[msg.sender] = 0;
            uint received = wstETH.unwrap(reward);
            IERC20(wstETH.stETH()).safeTransfer(msg.sender, received);
            emit RewardPaid(msg.sender, reward);
        }
    }
}
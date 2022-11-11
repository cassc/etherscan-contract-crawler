// SPDX-License-Identifier: MIT
pragma solidity ^0.7.6;

import '../openzeppelin-solidity-3.4.0/contracts/token/ERC20/IERC20.sol';
import '../openzeppelin-solidity-3.4.0/contracts/access/Ownable.sol';

import './StakingRewards.sol';

contract StakingRewardsFactory is Ownable {
    // immutables
    /// The token rewards will be paid in.
    address public rewardsToken;
    /// The earliest time at which staking rewards may start.
    uint public stakingRewardsGenesis;

    /// The staking tokens for which the rewards contract has been deployed
    address[] public stakingTokens;

    /// info about rewards for a particular staking token
    struct StakingRewardsInfo {
        address stakingRewards;
        uint rewardAmount;
    }

    /// rewards info by staking token
    mapping(address => StakingRewardsInfo) public stakingRewardsInfoByStakingToken;

    /// Deploy a new StakingRewardsFactory to distribute the specified rewards token staring at a specific genesis time.
    constructor(
        address _rewardsToken,
        uint _stakingRewardsGenesis
    ) Ownable() {
        require(_stakingRewardsGenesis >= block.timestamp, 'StakingRewardsFactory::constructor: genesis too soon');

        rewardsToken = _rewardsToken;
        stakingRewardsGenesis = _stakingRewardsGenesis;
    }

    ///// permissioned functions

    /// Deploy a staking reward contract for the staking token, and store the reward amount.
    /// The reward will be distributed to the staking reward contract no sooner than the genesis.
    function deploy(address stakingToken, uint rewardAmount) external onlyOwner {
        StakingRewardsInfo storage info = stakingRewardsInfoByStakingToken[stakingToken];
        require(info.stakingRewards == address(0), 'StakingRewardsFactory::deploy: already deployed');

        info.stakingRewards = address(new StakingRewards(/*_rewardsDistribution=*/ address(this), rewardsToken, stakingToken));
        info.rewardAmount = rewardAmount;
        stakingTokens.push(stakingToken);
    }

    ///// permissionless functions

    /// Call notifyRewardAmount for all staking tokens.
    function notifyRewardAmounts() external {
        require(stakingTokens.length > 0, 'StakingRewardsFactory::notifyRewardAmounts: called before any deploys');
        for (uint i = 0; i < stakingTokens.length; i++) {
            notifyRewardAmount(stakingTokens[i]);
        }
    }

    /// Notify reward amount for an individual staking token.
    /// This is a fallback in case the notifyRewardAmounts costs too much gas to call for all contracts.
    function notifyRewardAmount(address stakingToken) public {
        require(block.timestamp >= stakingRewardsGenesis, 'StakingRewardsFactory::notifyRewardAmount: not ready');

        StakingRewardsInfo storage info = stakingRewardsInfoByStakingToken[stakingToken];
        require(info.stakingRewards != address(0), 'StakingRewardsFactory::notifyRewardAmount: not deployed');

        if (info.rewardAmount > 0) {
            uint rewardAmount = info.rewardAmount;
            info.rewardAmount = 0;

            require(
                IERC20(rewardsToken).transfer(info.stakingRewards, rewardAmount),
                'StakingRewardsFactory::notifyRewardAmount: transfer failed'
            );
            StakingRewards(info.stakingRewards).notifyRewardAmount(rewardAmount);
        }
    }
}
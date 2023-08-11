// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

interface IFarmV3 {
    struct PoolInfo {
        uint256 origTotSupply; // supply of rewards tokens put up to be rewarded by original owner
        uint256 curRewardsSupply; // current supply of rewards
        uint256 totalTokensStaked; // current amount of tokens staked
        uint256 creationBlock; // block this contract was created
        uint256 perBlockNum; // amount of rewards tokens rewarded per block
        uint256 lastRewardBlock; // Prev block where distribution updated (ie staking/unstaking updates this)
        uint256 accERC20PerShare; // Accumulated ERC20s per share, times 1e36.
        uint256 stakeTimeLockSec; // number of seconds after depositing the user is required to stake before unstaking
    }

    struct StakerInfo {
        uint256 blockOriginallyStaked; // block the user originally staked
        uint256 timeOriginallyStaked; // unix timestamp in seconds that the user originally staked
        uint256 blockLastHarvested; // the block the user last claimed/harvested rewards
        uint256 rewardDebt; // Reward debt. See explanation below.
    }

    function pool() external view returns (PoolInfo memory);

    function stakers(address user) external view returns (StakerInfo memory);

    function balanceOf(address user) external view returns (uint256 balance);

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

    function unstakeTokens(
        uint256 _amount,
        bool shouldHarvest
    ) external payable;
}
// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;

interface IRewards {
    function balanceOf(address _account) external view returns (uint256);

    function stake(address, uint256) external;

    function stakeFor(address, uint256) external;

    function withdraw(address, uint256) external;

    function withdrawAndUnwrap(uint256 amount, bool claim) external;

    function exit(address) external;

    function getReward(address) external;

    function getReward(address _account, bool _claimExtras) external;

    function queueNewRewards(uint256) external;

    function notifyRewardAmount(uint256) external;

    function addExtraReward(address) external;

    function stakingToken() external view returns (address);

    function rewardToken() external view returns (address);

    function earned(address account) external view returns (uint256);
}
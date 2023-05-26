// SPDX-License-Identifier: MIT
pragma solidity >=0.7.0;

interface IGensoMetaStakingPool {
    // Views

    function balanceOf(address account) external view returns (uint256);

    function earned(address account) external view returns (uint256);

    function getRewardForDuration() external view returns (uint256);

    function lastTimeRewardApplicable() external view returns (uint256);

    function rewardPerToken() external view returns (uint256);

    function totalSupply() external view returns (uint256);

    // Mutative

    function exit() external;

    function claim() external;

    function stake(uint256 amount) external;

    function unstake(uint256 amount) external;
}
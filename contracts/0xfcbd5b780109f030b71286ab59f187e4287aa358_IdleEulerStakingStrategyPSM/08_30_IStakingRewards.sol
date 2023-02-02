// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

// Original contract can be found under the following link:
// https://github.com/Synthetixio/synthetix/blob/master/contracts/interfaces/IStakingRewards.sol
interface IStakingRewards {
    // Views

    function balanceOf(address account) external view returns (uint256);

    function earned(address account) external view returns (uint256);

    function getRewardForDuration() external view returns (uint256);

    function lastTimeRewardApplicable() external view returns (uint256);

    function rewardPerToken() external view returns (uint256);
    function rewardRate() external view returns (uint256);

    function totalSupply() external view returns (uint256);

    // Mutative

    function exit() external;
    function exit(uint subAccountId) external;

    function getReward() external;

    function stake(uint256 amount) external;
    function stake(uint subAccountId, uint256 amount) external;

    function withdraw(uint256 amount) external;
    function withdraw(uint subAccountId, uint256 amount) external;
}
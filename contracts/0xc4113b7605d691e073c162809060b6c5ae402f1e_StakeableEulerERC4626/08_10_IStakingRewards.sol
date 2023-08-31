// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

// Original contract can be found under the following link:
// https://github.com/Synthetixio/synthetix/blob/master/contracts/interfaces/IStakingRewards.sol
interface IStakingRewards {

    // Views
    function rewardsToken() external view returns (address);
    function stakingToken() external view returns (address);
    function balanceOf(address account) external view returns (uint256);
    function earned(address account) external view returns (uint256);

    // Mutative
    function exit() external;
    function getReward() external;
    function stake(uint256 amount) external;
    function withdraw(uint256 amount) external;
}
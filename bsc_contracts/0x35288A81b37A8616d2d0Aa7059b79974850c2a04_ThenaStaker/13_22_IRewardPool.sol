// SPDX-License-Identifier: MIT

pragma solidity 0.8.13;

interface IRewardPool {
    function notifyRewardAmount() external;

    function stake(uint256 amount) external;

    function withdraw(uint256 amount) external;

    function getReward() external;

    function balanceOf(address account) external view returns (uint256);

    function earned(address account) external view returns (uint256);
}
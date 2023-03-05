// SPDX-License-Identifier: MIT
pragma solidity >=0.8.4;

interface IVirtualBalanceRewardPool {
    function earned(address account) external view returns(uint);
    function rewardToken() external view returns(address);
    function getReward() external;
}
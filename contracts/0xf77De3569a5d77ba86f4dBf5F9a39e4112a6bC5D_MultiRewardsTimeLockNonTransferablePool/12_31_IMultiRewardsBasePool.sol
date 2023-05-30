// SPDX-License-Identifier: MIT
pragma solidity 0.8.7;
interface IMultiRewardsBasePool {
    function distributeRewards(address _reward, uint256 _amount) external;
}
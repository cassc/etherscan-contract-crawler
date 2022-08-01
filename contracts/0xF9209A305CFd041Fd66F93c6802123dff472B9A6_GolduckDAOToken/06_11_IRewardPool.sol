// SPDX-License-Identifier: MIT

pragma solidity 0.8.13;

import "./IRewardDistributor.sol";

interface IRewardPool {
    function rewardOf(address reward,address account) external view returns(uint256);
    function withdrawnRewardOf(address reward,address user) external view returns(uint256);
    function setBalance(address account, uint256 newBalance) external;
}
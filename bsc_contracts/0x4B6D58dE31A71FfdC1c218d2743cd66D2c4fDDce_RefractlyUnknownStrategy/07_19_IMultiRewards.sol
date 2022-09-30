// SPDX-License-Identifier: MIT

pragma solidity 0.8.16;

interface IMultiRewards {
  function earned(address account, address _rewardsToken) external returns (uint256);
}
// SPDX-License-Identifier: MIT

pragma solidity 0.7.6;

interface IConvexVirtualBalanceRewardPool {
  function earned(address account) external view returns (uint256);
}
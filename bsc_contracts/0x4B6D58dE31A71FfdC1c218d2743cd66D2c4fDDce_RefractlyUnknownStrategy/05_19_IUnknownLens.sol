// SPDX-License-Identifier: MIT

pragma solidity 0.8.16;

interface IUnknownLens {
  function userProxyByAccount(address acount) external returns (address);

  function stakingRewardsByConePool(address conePoolAddress) external returns (address);
}
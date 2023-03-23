// SPDX-License-Identifier: BUSL-1.1

pragma solidity ^0.8.17;

interface IPool {
  function transferBase(address _to, uint256 _amount) external;

  function transferFromPool(
    address _token,
    address _to,
    uint256 _amount
  ) external;

  function getBaseBalance() external view returns (uint256);
}
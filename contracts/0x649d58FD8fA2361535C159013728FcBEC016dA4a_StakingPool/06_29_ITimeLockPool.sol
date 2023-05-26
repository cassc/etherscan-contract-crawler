// SPDX-License-Identifier: MIT
pragma solidity 0.8.10;

interface ITimeLockPool {
  function deposit(
    uint256 _amount,
    uint256 _duration,
    address _receiver
  ) external;
}
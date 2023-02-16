// SPDX-License-Identifier: MIT
pragma solidity 0.8.4;

interface IBitXGoldSwap {
  function transferReward(address _to, uint256 _amount) external;
}
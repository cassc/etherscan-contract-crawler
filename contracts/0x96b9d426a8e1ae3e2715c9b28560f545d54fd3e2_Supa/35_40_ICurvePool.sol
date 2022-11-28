// SPDX-License-Identifier: agpl-3.0

pragma solidity >=0.7.0 <0.9.0;

interface ICurvePool {

  function exchange(int128 i, int128 j, uint256 dx, uint256 min_dy) external payable;
}
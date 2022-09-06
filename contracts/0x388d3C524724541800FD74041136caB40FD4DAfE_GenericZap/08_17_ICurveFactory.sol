pragma solidity ^0.8.4;
// SPDX-License-Identifier: AGPL-3.0-or-later

interface ICurveFactory {
  function get_n_coins(address pool) external view returns (uint256);
  function get_meta_n_coins(address pool) external view returns (uint256, uint256);
}
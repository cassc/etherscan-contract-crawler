// SPDX-License-Identifier: MIT
pragma solidity =0.8.9;

interface ICurveRegistry {
  function get_lp_token(address _pool) external view returns (address);

  function get_gauges(address _pool) external view returns (address[10] memory, address[10] memory);
}
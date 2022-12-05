// SPDX-License-Identifier: MIT

pragma solidity ^0.7.6;

// solhint-disable func-name-mixedcase

interface ICurvePoolRegistry {
  function get_lp_token(address _pool) external view returns (address);

  function get_pool_from_lp_token(address _token) external view returns (address);
}
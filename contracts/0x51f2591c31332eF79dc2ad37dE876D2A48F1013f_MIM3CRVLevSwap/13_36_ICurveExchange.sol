// SPDX-License-Identifier: AGPL-3.0
pragma solidity ^0.8.0;

interface ICurveExchange {
  function exchange(
    address _pool,
    address _from,
    address _to,
    uint256 _amount,
    uint256 _expected,
    address _receiver
  ) external payable returns (uint256);

  function exchange_multiple(
    address[9] memory _route,
    uint256[3][4] memory _swap_params,
    uint256 _amount,
    uint256 _expected,
    address[4] memory _pools,
    address _receiver
  ) external payable returns (uint256);
}
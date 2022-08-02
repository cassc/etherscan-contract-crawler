// SPDX-License-Identifier: MIT
pragma solidity >=0.5.0;
pragma experimental ABIEncoderV2;


interface ICurveRouter {
  function get_best_rate(
    address from, address to, uint256 _amount) external view returns (address, uint256);
  
  function exchange_with_best_rate(
    address _from,
    address _to,
    uint256 _amount,
    uint256 _expected
  ) external returns (uint256);
  
  function exchange_with_best_rate(
    address _from,
    address _to,
    uint256 _amount,
    uint256 _expected,
    address _receiver
  ) external returns (uint256);
  
  function exchange(
    address _pool,
    address _from,
    address _to,
    uint256 _amount,
    uint256 _expected,
    address _receiver
  ) external returns (uint256);
}
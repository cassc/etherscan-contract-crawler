// SPDX-License-Identifier: MIT

pragma solidity >=0.7.0 <0.8.0;

interface ICurveInt256 {
  function get_dy(
    int256,
    int256,
    uint256
  ) external view returns (uint256);

  function exchange(
    int256,
    int256,
    uint256,
    uint256
  ) external returns (uint256);

  function coins(int256) external view returns (address);
}
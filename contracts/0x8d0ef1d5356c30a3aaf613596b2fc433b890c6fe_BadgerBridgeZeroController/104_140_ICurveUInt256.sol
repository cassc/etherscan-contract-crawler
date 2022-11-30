// SPDX-License-Identifier: MIT

pragma solidity >=0.7.0 <0.8.0;

interface ICurveUInt256 {
  function get_dy(
    uint256,
    uint256,
    uint256
  ) external view returns (uint256);

  function exchange(
    uint256,
    uint256,
    uint256,
    uint256
  ) external returns (uint256);

  function coins(uint256) external view returns (address);
}
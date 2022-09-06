// SPDX-License-Identifier: MIT

pragma solidity 0.7.6;

// solhint-disable var-name-mixedcase, func-name-mixedcase
interface ICurveFactoryPool {
  function get_dy(
    int128 i,
    int128 j,
    uint256 dx
  ) external view returns (uint256);

  function exchange(
    int128 i,
    int128 j,
    uint256 _dx,
    uint256 _min_dy,
    address _receiver
  ) external returns (uint256);

  function coins(uint256 index) external returns (address);
}
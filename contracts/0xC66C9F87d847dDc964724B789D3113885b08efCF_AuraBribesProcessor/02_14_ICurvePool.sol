// SPDX-License-Identifier: MIT
pragma solidity >=0.5.0;
pragma experimental ABIEncoderV2;


interface ICurvePool {
  function coins(uint256 n) external view returns (address);
  function get_dy(int128 i, int128 j, uint256 dx) external view returns (uint256);
  function exchange(int128 i, int128 j, uint256 _dx, uint256 _min_dy) external returns (uint256);
  function get_virtual_price() external view returns (uint256);
  function get_balances() external view returns (uint256[] memory);
  function fee() external view returns (uint256);
}
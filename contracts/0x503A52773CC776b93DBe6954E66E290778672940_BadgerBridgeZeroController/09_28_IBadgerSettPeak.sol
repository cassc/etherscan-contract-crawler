// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0;

interface IBadgerSettPeak {
  function mint(
    uint256,
    uint256,
    bytes32[] calldata
  ) external returns (uint256);

  function redeem(uint256, uint256) external returns (uint256);
}
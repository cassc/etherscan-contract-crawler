// SPDX-License-Identifier: agpl-3.0
pragma solidity ^0.8.0;


interface IPremium {
  function getPremium(uint256 curveIdx, uint256 vol) external view returns (uint256);
  function precision() external pure returns (uint256);
}
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IYVUSDC {
  function withdraw(uint256 maxShares) external returns (uint256);

  function pricePerShare() external view returns (uint256);
}
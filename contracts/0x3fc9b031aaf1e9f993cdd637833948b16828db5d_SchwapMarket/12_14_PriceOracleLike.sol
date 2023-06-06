// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.13;

interface PriceOracleLike {
  function getPriceFor(address, address, uint256) external view returns (uint256);
}
// SPDX-License-Identifier: BSD-3-Clause

pragma solidity ^0.8.17;

interface ITownHall {
  function unlockTime(uint256 tokenId) external view returns (uint256);
}
// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.10;

import "@openzeppelin/contracts-upgradeable/interfaces/IERC721EnumerableUpgradeable.sol";

interface CBKLandInterface is IERC721EnumerableUpgradeable {
  function get(uint256 id) external view returns (uint256, uint256, uint256, uint256, address);

  function getOwned(address owner) external view returns (uint256[] memory ownedIds);
}
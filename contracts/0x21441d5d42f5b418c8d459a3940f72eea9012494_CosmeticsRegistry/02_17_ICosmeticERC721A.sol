// SPDX-License-Identifier: Unliscensed

pragma solidity ^0.8.17;

/**
 * @title ICosmeticERC721A
 * @dev Interface for the CosmeticERC721A contract.
 */

interface ICosmeticERC721A {
  function isEligible (address _address) external returns (bool);
  function claim (address _to) external;
  function setCosmeticRegistry(address _cosmeticRegistry) external;
  function balanceOf(address _owner) external view returns (uint256);
}
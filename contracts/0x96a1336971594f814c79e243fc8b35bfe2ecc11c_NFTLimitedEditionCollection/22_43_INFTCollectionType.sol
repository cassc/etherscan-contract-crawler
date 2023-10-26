// SPDX-License-Identifier: MIT OR Apache-2.0

pragma solidity ^0.8.18;

/**
 * @title Declares the type of the collection contract.
 * @dev This interface is declared as an ERC-165 interface.
 * @author reggieag
 */
interface INFTCollectionType {
  function getNFTCollectionType() external view returns (string memory collectionType);
}
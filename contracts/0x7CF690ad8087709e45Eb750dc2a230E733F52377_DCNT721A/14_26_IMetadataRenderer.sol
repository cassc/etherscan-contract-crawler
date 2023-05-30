// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IMetadataRenderer {
  function tokenURI(uint256) external view returns (string memory);

  function contractURI() external view returns (string memory);

  function initializeWithData(bytes memory initData) external;

  /// @notice Storage for token edition information
  struct TokenEditionInfo {
    string description;
    string imageURI;
    string animationURI;
  }
}
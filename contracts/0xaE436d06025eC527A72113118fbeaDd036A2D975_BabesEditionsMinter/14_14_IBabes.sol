// SPDX-License-Identifier: None
pragma solidity ^0.8.17;

interface IBabes {
  /// @notice Mint a group of tokenIds to a single address
  /// @param to The recipient address for the newly minted tokens
  /// @param tokenIds The tokenIds to mint
  function mint(address to, uint256[] calldata tokenIds) external;
}
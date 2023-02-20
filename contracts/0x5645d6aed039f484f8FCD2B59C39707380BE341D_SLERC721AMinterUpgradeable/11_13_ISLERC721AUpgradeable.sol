// SPDX-License-Identifier: MIT

pragma solidity ^0.8.17;

import "erc721a-upgradeable/contracts/IERC721AUpgradeable.sol";

interface ISLERC721AUpgradeable is IERC721AUpgradeable {
  /// @notice Mint NFT(s). No restriction, but must be minter.
  /// @param to NFT recipient
  /// @param quantity number of NFT to mint
  function mintTo(address to, uint256 quantity) external payable;

  /// @notice Setting starting index only once
  function setStartingIndex(uint256 maxSupply) external;
}
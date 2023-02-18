// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

import {IERC721Sale} from "./IERC721Sale.sol";

contract ERC721SaleStorage {
  /// @notice Configuration for NFT minting contract storage
  IERC721Sale.Configuration public config;

  /// @notice Sales configuration
  IERC721Sale.SalesConfiguration public salesConfig;

  /// @notice Base URI for token URIs
  string public baseURI;

  /// @dev Mapping for presale mint counts by address to allow public mint limit
  mapping(address => uint256) public publicMintsByAddress;

  /// @dev Mapping for presale mint counts by address to allow public mint limit
  mapping(address => uint256) public presaleMintsByAddress;

  /// @dev Mapping for waitlist mint counts by address to allow public mint limit
  mapping(address => uint256) public waitlistMintsByAddress;
}
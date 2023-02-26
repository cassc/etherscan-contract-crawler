// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (token/ERC721/CHECKS721.sol)

pragma solidity ^0.8.0;

import "erc721a/contracts/IERC721A.sol";

/// @title EIP-721 Metadata Update Extension
interface IERC4906 is IERC721A {
  /// @dev This event emits when the metadata of a token is changed.
  /// Third-party platforms such as NFT marketplaces can listen to
  /// the event and auto-update the tokens in their apps.
  event MetadataUpdate(uint256 _tokenId);
}
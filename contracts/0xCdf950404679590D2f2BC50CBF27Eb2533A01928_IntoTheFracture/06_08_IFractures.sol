// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

interface IFractures {
  /// @dev Burns `tokenId`. See {ERC721A-_burn}.
  ///      Requirements:
  ///      - The caller must own `tokenId` or be an approved operator.
  function burn(uint256 tokenId) external;

  /// @dev Returns the owner of the `tokenId` token.
  ///      Requirements:
  ///      - `tokenId` must exist.
  function ownerOf(uint256 tokenId) external view returns (address owner);

  /// @dev Returns the account approved for `tokenId` token.
  ///      Requirements:
  ///      - `tokenId` must exist.
  function getApproved(uint256 tokenId) external view returns (address operator);

  /// @dev Returns if the `operator` is allowed to manage all of the assets of `owner`.
  function isApprovedForAll(address owner, address operator) external view returns (bool);
}
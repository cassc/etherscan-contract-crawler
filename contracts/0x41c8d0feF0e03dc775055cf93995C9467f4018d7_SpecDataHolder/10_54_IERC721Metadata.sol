// SPDX-License-Identifier: CC0-1.0
pragma solidity 0.8.16;

// implementing this locally since the OZ extension inherits IERC721 (which we don't need)
interface IERC721Metadata {
  function name() external view returns (string memory);

  function symbol() external view returns (string memory);

  function tokenURI(uint256 tokenId) external view returns (string memory);
}
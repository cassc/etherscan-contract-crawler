// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/extensions/IERC721Metadata.sol";
import "../ERC721B.sol";

/**
 * @dev ERC721 token with storage based token URI management.
 */
abstract contract ERC721BStaticTokenURI is ERC721B, IERC721Metadata {
  // Optional mapping for token URIs
  mapping(uint256 => string) private _tokenURIs;

  /**
   * @dev See {IERC721Metadata-tokenURI}.
   */
  function tokenURI(uint256 tokenId) public view virtual returns(string memory) {
    return staticTokenURI(tokenId);
  }

  /**
   * @dev See {IERC721Metadata-tokenURI}.
   */
  function staticTokenURI(uint256 tokenId) public view virtual returns(string memory) {
    if(!_exists(tokenId)) revert NonExistentToken();
    return _tokenURIs[tokenId];
  }

  /**
   * @dev Sets `_tokenURI` as the tokenURI of `tokenId`.
   *
   * Requirements:
   *
   * - `tokenId` must exist.
   */
  function _setTokenURI(uint256 tokenId, string memory _tokenURI) internal virtual {
    if(!_exists(tokenId)) revert NonExistentToken();
    _tokenURIs[tokenId] = _tokenURI;
  }
}
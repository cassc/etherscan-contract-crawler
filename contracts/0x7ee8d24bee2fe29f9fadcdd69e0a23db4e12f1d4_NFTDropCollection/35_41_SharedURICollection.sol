// SPDX-License-Identifier: MIT OR Apache-2.0

pragma solidity ^0.8.18;

import "@openzeppelin/contracts-upgradeable/token/ERC721/ERC721Upgradeable.sol";

error SharedURICollection_URI_Not_Set();

/**
 * @title Implements a URI for a collection which is shared by all tokens.
 * @author HardlyDifficult
 */
abstract contract SharedURICollection is ERC721Upgradeable {
  string private $baseURI;

  /**
   * @notice Set the base URI to be used for all tokens.
   * @param uri The base URI to use.
   */
  function _setBaseURI(string calldata uri) internal {
    if (bytes(uri).length == 0) {
      revert SharedURICollection_URI_Not_Set();
    }
    $baseURI = uri;
  }

  /**
   * @inheritdoc ERC721Upgradeable
   */
  function _baseURI() internal view virtual override returns (string memory uri) {
    uri = $baseURI;
  }
}
// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/extensions/IERC721Metadata.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "../ERC721B.sol";

/**
 * @dev ERC721B token where token URIs are determined with a base URI
 */
abstract contract ERC721BBaseTokenURI is ERC721B, IERC721Metadata {
  using Strings for uint256;
  string private _baseTokenURI;

  /**
   * @dev See {IERC721Metadata-tokenURI}.
   */
  function tokenURI(uint256 tokenId) public view virtual returns(string memory) {
    if(!_exists(tokenId)) revert NonExistentToken();
    string memory baseURI = _baseTokenURI;
    return bytes(baseURI).length > 0 ? string(
      abi.encodePacked(baseURI, tokenId.toString())
    ) : "";
  }
  
  /**
   * @dev The base URI for token data ex. https://creatures-api.opensea.io/api/creature/
   * Example Usage: 
   *  Strings.strConcat(baseTokenURI(), Strings.uint2str(tokenId))
   */
  function baseTokenURI() public view returns (string memory) {
    return _baseTokenURI;
  }

  /**
   * @dev Setting base token uri would be acceptable if using IPFS CIDs
   */
  function _setBaseURI(string memory uri) internal virtual {
    _baseTokenURI = uri;
  }
}
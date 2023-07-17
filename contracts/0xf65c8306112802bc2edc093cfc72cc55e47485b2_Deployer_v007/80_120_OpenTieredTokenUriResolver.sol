// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import '@openzeppelin/contracts/utils/Strings.sol';

import '../interfaces/IToken721UriResolver.sol';

contract OpenTieredTokenUriResolver is IToken721UriResolver {
  using Strings for uint256;

  string public baseUri;

  /**
    @notice An ERC721-style token URI resolver that appends token id to the end of a base uri.

    @dev This contract is meant to go with NFTs minted using OpenTieredPriceResolver. The URI returned from tokenURI is based on the low 8 bits of the token id provided.

    @param _baseUri Root URI
    */
  constructor(string memory _baseUri) {
    baseUri = _baseUri;
  }

  function tokenURI(uint256 _tokenId) external view override returns (string memory uri) {
    uri = string(abi.encodePacked(baseUri, uint256(uint8(_tokenId)).toString()));
  }
}
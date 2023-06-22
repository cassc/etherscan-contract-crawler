// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import '@openzeppelin/contracts/utils/Strings.sol';

import '../interfaces/IToken721UriResolver.sol';

/**
 * @dev Implements pseudo ERC1155 functionality into an ERC721 token while maintaining unique token id and serving the same metadata for some range of ids.
 */
contract TieredTokenUriResolver is IToken721UriResolver {
  using Strings for uint256;
  error INVALID_ID_SORT_ORDER(uint256);
  error ID_OUT_OF_RANGE();

  string public baseUri;
  uint256[] public idRange;

  /**
    @notice An ERC721-style token URI resolver that appends tier to the end of a base uri.

    @dev This contract is meant to go with NFTs minted using TieredPriceResolver. The URI returned from tokenURI is based on where the given id fits in the range provided to the constructor.

    @param _baseUri Root URI
    @param _idRange List of token id cutoffs between tiers; must be sorted ascending.
    */
  constructor(string memory _baseUri, uint256[] memory _idRange) {
    baseUri = _baseUri;

    // idRange = new uint256[](_idRange.length - 1);
    for (uint256 i; i != _idRange.length; ) {
      if (i != 0) {
        if (idRange[i - 1] > _idRange[i]) {
          revert INVALID_ID_SORT_ORDER(i);
        }
      }
      idRange.push(_idRange[i]);
      unchecked {
        ++i;
      }
    }
  }

  function tokenURI(uint256 _tokenId) external view override returns (string memory uri) {
    uint256 tier;
    for (uint256 i; i != idRange.length; ) {
      if (_tokenId < idRange[i]) {
        tier = i + 1;
        break;
      }
      unchecked {
        ++i;
      }
    }

    if (tier == 0) {
      revert ID_OUT_OF_RANGE();
    }

    uri = string(abi.encodePacked(baseUri, tier.toString()));
  }
}
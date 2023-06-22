// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../ERC721B.sol";

/**
 * @dev ERC721B contract with a URI descriptor
 */
abstract contract ERC721BContractURIStorage is ERC721B {
  //immutable contract uri
  string private _contractURI;

  /**
   * @dev The URI for contract data ex. https://creatures-api.opensea.io/contract/opensea-creatures/contract.json
   * Example Format:
   * {
   *   "name": "OpenSea Creatures",
   *   "description": "OpenSea Creatures are adorable aquatic beings primarily for demonstrating what can be done using the OpenSea platform. Adopt one today to try out all the OpenSea buying, selling, and bidding feature set.",
   *   "image": "https://openseacreatures.io/image.png",
   *   "external_link": "https://openseacreatures.io",
   *   "seller_fee_basis_points": 100, # Indicates a 1% seller fee.
   *   "fee_recipient": "0xA97F337c39cccE66adfeCB2BF99C1DdC54C2D721" # Where seller fees will be paid to.
   * }
   */
  function contractURI() external view returns (string memory) {
    return _contractURI;
  }

  /**
   * @dev Sets contract uri
   */
  function _setContractURI(string memory uri) internal virtual {
    _contractURI = uri;
  }
}
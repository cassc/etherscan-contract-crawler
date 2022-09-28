// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/access/Ownable.sol";

abstract contract Uri is Ownable {
  string public baseURI;
  string public _contractURI;

  /**
   * Sets the Base URI for the token API
   */
  function setBaseURI(string memory uri) public onlyOwner {
    baseURI = uri;
  }

  /**
   * OpenSea contract level metdata standard for displaying on storefront.
   * https://docs.opensea.io/docs/contract-level-metadata
   */
  function contractURI() public view returns (string memory) {
    return _contractURI;
  }

  function setContractURI(string memory uri) public onlyOwner {
    _contractURI = uri;
  }
}
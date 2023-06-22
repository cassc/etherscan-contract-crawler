// SPDX-License-Identifier: MIT
pragma solidity >=0.8.9;

abstract contract Metadata {
  string public baseTokenURI;

  constructor(string memory _baseURI) {
    _setBaseTokenURI(_baseURI);
  }

  function _setBaseTokenURI(string memory _baseURI) internal {
    baseTokenURI = _baseURI;
  }
}
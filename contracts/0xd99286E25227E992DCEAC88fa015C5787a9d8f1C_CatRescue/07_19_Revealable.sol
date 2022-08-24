// SPDX-License-Identifier: MIT

// Revelable helps to reveal tokenURIs.

pragma solidity ^0.8.0;
pragma experimental ABIEncoderV2;

import '@openzeppelin/contracts/utils/Counters.sol';
import '@openzeppelin/contracts/token/ERC721/ERC721.sol';

abstract contract Revealable {
  string private __baseURI;

  function r_baseURI() internal view returns (string memory) {
    return __baseURI;
  }

  function _setBaseURI(string calldata baseURI_) internal {
    __baseURI = baseURI_;
  }

  function _tokenURI(uint256 tokenId)
    internal
    view
    virtual
    returns (string memory)
  {
    return
      string(abi.encodePacked(__baseURI, Strings.toString(tokenId), '.json'));
  }
}
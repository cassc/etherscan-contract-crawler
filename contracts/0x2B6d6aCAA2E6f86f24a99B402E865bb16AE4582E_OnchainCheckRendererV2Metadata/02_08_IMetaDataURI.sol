// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.16;

interface IMetaDataURI {
  function tokenURI(uint256 tokenId, uint256 seed, uint24 gasPrice)
    external
    view
    returns (string memory);
}
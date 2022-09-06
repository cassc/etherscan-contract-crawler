//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

interface IStrxngersMetadata {

  function tokenURI(uint256 tokenId) external view returns (string memory);

}
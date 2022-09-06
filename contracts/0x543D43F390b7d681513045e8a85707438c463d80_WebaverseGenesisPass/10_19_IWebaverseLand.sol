// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.15;

interface IWebaverseLand {
  // Function to call to return the tokenURI for a passed token Id
  function uriForToken(uint256 tokenId_) external view returns (string memory);
}
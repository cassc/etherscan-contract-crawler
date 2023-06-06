// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import '@openzeppelin/contracts/token/ERC721/extensions/IERC721Metadata.sol';

// Interface or store-level metadata
interface IStrawberryMetadata is IERC721Metadata {
  // Set the contractURI
  function setContractURI(string memory contractURI) external;

  // Set the baseURI
  function setBaseURI(string memory baseURI) external;

  // Returns URL for storefront-level metadata
  function contractURI() external view returns(string memory);

  // Returns URL for token-level metadata
  function tokenURI(uint256 tokenId) external view override returns(string memory);
}
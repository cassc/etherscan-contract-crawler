// SPDX-License-Identifier: MIT
pragma solidity ^0.8.11;

import "@openzeppelin/contracts-upgradeable/token/ERC721/extensions/IERC721MetadataUpgradeable.sol";

interface IERC721Mirrored is IERC721MetadataUpgradeable {
  function safeMint(address to, uint256 tokenId) external;
  function burn(uint256 tokenId) external;
  function setTokenURI(uint256 tokenId, string memory _tokenURI) external;
  function setBaseURI(string memory baseURL) external;
}
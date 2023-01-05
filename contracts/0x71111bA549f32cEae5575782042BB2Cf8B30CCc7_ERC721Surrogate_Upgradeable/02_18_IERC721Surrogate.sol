// SPDX-License-Identifier: BSD-3
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/extensions/IERC721Metadata.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/IERC721Enumerable.sol";

interface IERC721Surrogate is IERC721Metadata, IERC721Enumerable {
  //IERC721Surrogate
  function setSurrogate(uint256 tokenId, address surrogate) external;
  function setSurrogates(uint256[] calldata tokenIds, address[] calldata surrogates) external;

  function softSync(uint256 tokenId) external;
  function softSync(uint256[] calldata tokenIds) external;

  function syncSurrogate(uint256 tokenId) external;
  function syncSurrogates(uint256[] calldata tokenIds) external;

  function unsetSurrogate(uint256 tokenId) external;
  function unsetSurrogates(uint256[] calldata tokenIds) external;


  //IERC721
  function balanceOf(address owner) external view returns (uint256 balance);
  function ownerOf(uint256 tokenId) external view returns (address owner);

  //IERC721Metadata
  function name() external view returns (string memory);
  function symbol() external view returns (string memory);
  function tokenURI(uint256 tokenId) external view returns (string memory);

  //IER721Enumerable
  function tokenByIndex(uint256 index) external view returns (uint256);
  function tokenOfOwnerByIndex(address owner, uint256 index) external view returns (uint256);
  function totalSupply() external view returns (uint256);
}
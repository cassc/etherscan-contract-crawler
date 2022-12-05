// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/extensions/IERC721Metadata.sol";

interface IERC721Surrogate is IERC721Metadata {
  //IERC721Metadata
  function balanceOf(address owner) external view returns (uint256 balance);
  function ownerOf(uint256 tokenId) external view returns (address owner);
  function tokenURI(uint256 tokenId) external view returns (string memory);

  //IERC721Surrogate
  function setSurrogate( uint tokenId, address surrogate ) external;
  function setSurrogates( uint[] calldata tokenIds, address[] calldata surrogates ) external;

  function syncSurrogate( uint tokenId ) external;
  function syncSurrogates( uint[] calldata tokenIds ) external;

  function unsetSurrogate( uint tokenId ) external;
  function unsetSurrogates( uint[] calldata tokenIds ) external;
}
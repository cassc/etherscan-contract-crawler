// SPDX-License-Identifier: MIT

// Project A-Heart: https://a-he.art

pragma solidity ^0.8.18;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";

interface IAHeart is IERC721 {
  function emitBatchMetadataUpdate(uint256 fromTokenId, uint256 toTokenId) external;

  function setMinter(address newMinter) external;

  function mint(address to, uint256 tokenId) external;

  function setBaseTokenURI(string calldata newBaseTokenURI) external;

  function setExtension(address extension, bool value) external;

  function addSuffixKey(string calldata key) external;

  function removeSuffixKey(uint256 keyIndex) external;

  function setSuffixValue(uint256 keyIndex, uint256 tokenId, string calldata value) external;

  function tokenURISuffix(uint256 tokenId) external view returns (string memory);

  function setEmissionRateDelta(uint256 tokenId, uint96 value) external;

  function chemistry(address tokenOwner, uint256 tokenId) external pure returns (uint256);

  function emissionRate(uint256 tokenId) external view returns (uint256);

  function rewardAmount(uint256 tokenId) external view returns (uint256);

  function addReward(uint256 tokenId, uint256 amount) external;

  function removeReward(uint256 tokenId, uint256 amount) external;

  function transferWithReward(address to, uint256 tokenId) external;
}
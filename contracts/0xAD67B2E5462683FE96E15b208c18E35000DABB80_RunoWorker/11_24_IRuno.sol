// SPDX-License-Identifier: MIT

pragma solidity ^0.8.13;
pragma abicoder v2;

import "@openzeppelin/contracts/token/ERC721/extensions/IERC721Enumerable.sol";

import "../types/Type.sol";

interface IRuno is IERC721Enumerable {
  function tokenURI(
    uint256 tokenId_
  ) external view returns (string memory);

  function tokensOf(
    address owner_,
    uint256 offset_,
    uint256 limit_
  ) external view returns (uint256[] memory, uint256[] memory);

  function getTokenTier(
    uint256 tokenId_
  ) external view returns (uint256); 

  function getMaxTier(
  ) external view returns (uint256);

  function getTierInfo(
    uint256 tier_
  ) external view returns (TierInfo memory);

  function getMintedTokenList(
    uint256 offset_,
    uint256 limit_
  ) external view returns (
    uint256,
    uint256[] memory,
    uint256[] memory,
    address[] memory
  );

  function isTokenRunning(
    uint256 tokenId_
  ) external view returns (bool);

  function toggleRunning(
    uint256 tokenId_
  ) external;

  function mint(
    address to_,
    uint256 tier_
  ) external returns (uint256);

  function updateBaseUri(
    string memory baseUri_
  ) external;

  function updateTierCap(
    uint256 tier_,
    uint256 cap_
  ) external;

  function setDefaultRoyalty(
    address beneficiary_,
    uint96 feeNumerator_
  ) external;

  function getRewardContractAddress(
  ) external view returns (address);

  function setRewardContractAddress(
    address rewardContract_
  ) external;

  function destroy(
    address payable to_
  ) external;
}
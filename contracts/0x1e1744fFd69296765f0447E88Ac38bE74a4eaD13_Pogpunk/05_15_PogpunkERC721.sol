// SPDX-License-Identifier: MIT
pragma solidity 0.8.0;

interface PogpunkERC721 {
  function addToAllowList(address[] calldata addresses) external;

  function onAllowList(address addr) external returns (bool);

  function removeFromAllowList(address[] calldata addresses) external;

  function allowListClaimedBy(address owner) external returns (uint256);

  function purchase(uint256 numberOfTokens) external payable;

  function purchaseAllowList(uint256 numberOfTokens) external payable;

  function gift(address to) external;

  function setIsActive(bool isActive) external;

  function setIsAllowListActive(bool isAllowListActive) external;

  function setAllowListMaxMint(uint256 maxMint) external;

  function setProof(string memory proofString) external;

  function withdraw() external;
}
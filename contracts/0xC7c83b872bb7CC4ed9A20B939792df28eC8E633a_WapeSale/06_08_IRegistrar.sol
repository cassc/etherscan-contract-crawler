// SPDX-License-Identifier: MIT
pragma solidity ^0.8.3;

interface IRegistrar {
  function transferFrom(
    address from,
    address to,
    uint256 tokenId
  ) external;

  function registerDomainAndSend(
    uint256 parentId,
    string memory label,
    address minter,
    string memory metadataUri,
    uint256 royaltyAmount,
    bool locked,
    address sendToUser
  ) external returns (uint256);

  function registerDomainInGroupBulk(
    uint256 parentId,
    uint256 groupId,
    uint256 namingOffset,
    uint256 startingIndex,
    uint256 endingIndex,
    address minter,
    uint256 royaltyAmount,
    address sendTo
  ) external;

  function createDomainGroup(string memory baseMetadataUri) external;

  function tokenByIndex(uint256 index) external view returns (uint256);

  function parentOf(uint256 id) external view returns (uint256);

  function ownerOf(uint256 id) external view returns (address);

  function numDomainGroups() external view returns (uint256);

  function isController(address account) external view returns (bool);

  function addController(address controller) external;

  function registerSubdomainContract(
    uint256 parentId,
    string memory label,
    address minter,
    string memory metadataUri,
    uint256 royaltyAmount,
    bool locked,
    address sendToUser
  ) external returns (uint256);

  function adminSetMetadataUri(uint256 id, string calldata uri) external;
}
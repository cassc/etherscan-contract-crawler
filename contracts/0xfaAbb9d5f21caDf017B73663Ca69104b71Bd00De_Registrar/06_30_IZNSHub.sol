// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import {IRegistrar} from "./IRegistrar.sol";

interface IZNSHub {
  function addRegistrar(uint256 rootDomainId, address registrar) external;

  function isController(address controller) external returns (bool);

  function getRegistrarForDomain(uint256 domainId)
    external
    view
    returns (IRegistrar);

  function ownerOf(uint256 domainId) external view returns (address);

  function domainExists(uint256 domainId) external view returns (bool);

  function owner() external view returns (address);

  function registrarBeacon() external view returns (address);

  function domainTransferred(
    address from,
    address to,
    uint256 tokenId
  ) external;

  function domainCreated(
    uint256 id,
    string calldata name,
    uint256 nameHash,
    uint256 parent,
    address minter,
    address controller,
    string calldata metadataUri,
    uint256 royaltyAmount,
    uint256 groupId,
    uint256 groupFileIndex
  ) external;

  function metadataLockChanged(
    uint256 id,
    address locker,
    bool isLocked
  ) external;

  function metadataChanged(uint256 id, string calldata uri) external;

  function royaltiesAmountChanged(uint256 id, uint256 amount) external;

  // Returns the parent domain of a child domain
  function parentOf(uint256 id) external view returns (uint256);

  function domainGroupUpdated(uint256 folderGroupId, string calldata baseUri)
    external;

  function subdomainRegistrars(uint256 id) external view returns (address);
}
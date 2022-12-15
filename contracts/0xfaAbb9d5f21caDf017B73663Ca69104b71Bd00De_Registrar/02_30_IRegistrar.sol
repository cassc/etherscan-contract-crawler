// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "../oz/token/ERC721/IERC721EnumerableUpgradeable.sol";
import "../oz/token/ERC721/IERC721MetadataUpgradeable.sol";

interface IRegistrar is
  IERC721MetadataUpgradeable,
  IERC721EnumerableUpgradeable
{
  // Emitted when a controller is removed
  event ControllerAdded(address indexed controller);

  // Emitted whenever a controller is removed
  event ControllerRemoved(address indexed controller);

  // Emitted whenever a new domain is created
  event DomainCreated(
    uint256 indexed id,
    string label,
    uint256 indexed labelHash,
    uint256 indexed parent,
    address minter,
    address controller,
    string metadataUri,
    uint256 royaltyAmount
  );

  // Emitted whenever the metadata of a domain is locked
  event MetadataLockChanged(uint256 indexed id, address locker, bool isLocked);

  // Emitted whenever the metadata of a domain is changed
  event MetadataChanged(uint256 indexed id, string uri);

  // Emitted whenever the royalty amount is changed
  event RoyaltiesAmountChanged(uint256 indexed id, uint256 amount);

  // Authorises a controller, who can register domains.
  function addController(address controller) external;

  // Revoke controller permission for an address.
  function removeController(address controller) external;

  // Registers a new sub domain
  function registerDomain(
    uint256 parentId,
    string memory label,
    address minter,
    string memory metadataUri,
    uint256 royaltyAmount,
    bool locked
  ) external returns (uint256);

  function registerDomainAndSend(
    uint256 parentId,
    string memory label,
    address minter,
    string memory metadataUri,
    uint256 royaltyAmount,
    bool locked,
    address sendToUser
  ) external returns (uint256);

  function registerSubdomainContract(
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

  // Set a domains metadata uri and lock that domain from being modified
  function setAndLockDomainMetadata(uint256 id, string memory uri) external;

  // Lock a domain's metadata so that it cannot be changed
  function lockDomainMetadata(uint256 id, bool toLock) external;

  // Update a domain's metadata uri
  function setDomainMetadataUri(uint256 id, string memory uri) external;

  // Sets the asked royalty amount on a domain (amount is a percentage with 5 decimal places)
  function setDomainRoyaltyAmount(uint256 id, uint256 amount) external;

  // Returns whether an address is a controller
  function isController(address account) external view returns (bool);

  // Checks whether or not a domain exists
  function domainExists(uint256 id) external view returns (bool);

  // Returns the original minter of a domain
  function minterOf(uint256 id) external view returns (address);

  // Checks if a domains metadata is locked
  function isDomainMetadataLocked(uint256 id) external view returns (bool);

  // Returns the address which locked the domain metadata
  function domainMetadataLockedBy(uint256 id) external view returns (address);

  // Gets the controller that registered a domain
  function domainController(uint256 id) external view returns (address);

  // Gets a domains current royalty amount
  function domainRoyaltyAmount(uint256 id) external view returns (uint256);

  // Returns the parent domain of a child domain
  function parentOf(uint256 id) external view returns (uint256);

  function createDomainGroup(string memory baseMetadataUri)
    external
    returns (uint256);

  function updateDomainGroup(uint256 id, string memory baseMetadataUri)
    external;

  function numDomainGroups() external view returns (uint256);
}
// SPDX-License-Identifier: MIT OR Apache-2.0
pragma solidity 0.8.16;

import "lib/openzeppelin-contracts/contracts/utils/Counters.sol";
import "lib/openzeppelin-contracts-upgradeable/contracts/proxy/utils/UUPSUpgradeable.sol";
import "lib/openzeppelin-contracts-upgradeable/contracts/access/OwnableUpgradeable.sol";
import "lib/openzeppelin-contracts-upgradeable/contracts/security/PausableUpgradeable.sol";
import "lib/openzeppelin-contracts-upgradeable/contracts/token/ERC721/extensions/ERC721EnumerableUpgradeable.sol";

// import "../node_modules/hardhat/console.sol";

/// @title RAFT Contract
/// @author Otterspace
/// @notice The RAFT NFT gives the owner the ability to create a DAO within Otterspace
/// @dev Inherits from ERC721Enumerable so that we can access useful functions for
/// querying owners of tokens from the web app.
contract Raft is
  ERC721EnumerableUpgradeable,
  UUPSUpgradeable,
  OwnableUpgradeable,
  PausableUpgradeable
{
  using Counters for Counters.Counter;
  Counters.Counter private _tokenIds;

  mapping(uint256 => string) private _tokenURIs;
  mapping(uint256 => mapping(address => bool)) private _admins;

  event MetadataUpdate(uint256 indexed tokenId);
  event AdminUpdate(
    uint256 indexed tokenId,
    address indexed admin,
    bool isAdded
  );

  /// @custom:oz-upgrades-unsafe-allow constructor
  constructor() {
    _disableInitializers();
  }

  function initialize(
    address nextOwner,
    string memory name_,
    string memory symbol_
  ) public initializer {
    __ERC721Enumerable_init();
    __ERC721_init(name_, symbol_);
    __UUPSUpgradeable_init();
    __Ownable_init();
    // Passing in the owner's address allows an EOA to deploy and set a multi-sig as the owner.
    transferOwnership(nextOwner);
    // pause the contract by default
    _pause();
  }

  function mint(address recipient, string memory uri)
    public
    virtual
    returns (uint256)
  {
    // owners can always mint tokens
    // non-owners can only mint when the contract is unpaused
    require(msg.sender == owner() || !paused(), "mint: unauthorized to mint");
    _tokenIds.increment();
    uint256 newItemId = _tokenIds.current();
    require(recipient != address(0), "cannot mint to zero address");
    _mint(recipient, newItemId);
    _tokenURIs[newItemId] = uri;

    return newItemId;
  }

  function pause() public onlyOwner {
    _pause();
  }

  function unpause() public onlyOwner {
    _unpause();
  }

  // we are basically implementing the functionality of ERC721URIStorage ourselves here
  function setTokenURI(uint256 tokenId, string memory uri)
    public
    virtual
    onlyOwner
  {
    require(_exists(tokenId), "setTokenURI: URI set of nonexistent token");
    _tokenURIs[tokenId] = uri;

    emit MetadataUpdate(tokenId);
  }

  function setAdmin(
    uint256 tokenId,
    address admin,
    bool isActive
  ) public virtual {
    require(_exists(tokenId), "addAdmin: tokenId does not exist");
    require(ownerOf(tokenId) == msg.sender, "addAdmin: unauthorized");

    _admins[tokenId][admin] = isActive;

    emit AdminUpdate(tokenId, admin, isActive);
  }

  function isAdminActive(uint256 tokenId, address admin)
    public
    view
    virtual
    returns (bool)
  {
    return _admins[tokenId][admin];
  }

  function tokenURI(uint256 tokenId)
    public
    view
    virtual
    override
    returns (string memory)
  {
    return _tokenURIs[tokenId];
  }

  function _authorizeUpgrade(address) internal override onlyOwner {}
}
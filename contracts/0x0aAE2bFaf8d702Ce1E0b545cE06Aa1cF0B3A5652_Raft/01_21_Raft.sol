// SPDX-License-Identifier: MIT OR Apache-2.0
pragma solidity 0.8.16;

import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "@openzeppelin-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin-upgradeable/security/PausableUpgradeable.sol";
import "@openzeppelin-upgradeable/token/ERC721/extensions/ERC721EnumerableUpgradeable.sol";

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

  /**
   * @dev Initializes the contract by setting up the initial owner, name and symbol of the ERC721 token and pausing the contract.
   * @param nextOwner The address of the initial owner of the contract.
   * @param name_ The name of the ERC721 token.
   * @param symbol_ The symbol of the ERC721 token.
   */
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

  /**
   * @dev Mint a new token and assign it to the recipient, with the given URI.
   * @param recipient The address to which the newly minted token will be assigned.
   * @param uri The URI of the newly minted token.
   * @return The ID of the newly minted token.
   */
  function mint(
    address recipient,
    string memory uri
  ) public virtual returns (uint256) {
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

  /**
   * @dev Sets the URI of the token with the given ID.
   *      Reverts if the token does not exist.
   * @param tokenId uint256 ID of the token to set its URI.
   * @param uri string URI to assign to the token.
   * @notice Only the owner of the contract can call this function.
   */
  function setTokenURI(
    uint256 tokenId,
    string memory uri
  ) public virtual onlyOwner {
    require(_exists(tokenId), "setTokenURI: URI set of nonexistent token");
    _tokenURIs[tokenId] = uri;

    emit MetadataUpdate(tokenId);
  }

  /**
   * @dev Sets multiple admins for a given tokenId.
   * @param tokenId The token ID for which the admins are being set.
   * @param admins An array of addresses representing the admins.
   * @param isActive An array of booleans representing the admin status (active or not).
   */

  function addAdmins(
    uint256 tokenId,
    address[] memory admins,
    bool[] memory isActive
  ) public virtual {
    require(_exists(tokenId), "addAdmins: tokenId does not exist");
    require(ownerOf(tokenId) == msg.sender, "addAdmins: unauthorized");
    require(
      admins.length == isActive.length,
      "addAdmins: admins and isActive arrays must have the same length"
    );

    for (uint256 i = 0; i < admins.length; i++) {
      _admins[tokenId][admins[i]] = isActive[i];
      emit AdminUpdate(tokenId, admins[i], isActive[i]);
    }
  }

  /**
   * @dev Removes multiple admins for a given tokenId.
   * @param tokenId The token ID for which the admins are being removed.
   * @param admins An array of addresses representing the admins to be removed.
   */

  function removeAdmins(
    uint256 tokenId,
    address[] memory admins
  ) public virtual {
    require(_exists(tokenId), "removeAdmins: tokenId does not exist");
    require(ownerOf(tokenId) == msg.sender, "removeAdmins: unauthorized");

    for (uint256 i = 0; i < admins.length; i++) {
      delete _admins[tokenId][admins[i]];
      emit AdminUpdate(tokenId, admins[i], false);
    }
  }

  /** @dev Returns a boolean value indicating whether the specified admin address is active for the given token ID.
   * @param tokenId The ID of the token.
   * @param admin The address of the admin to check.
   * @return A boolean value indicating whether the specified admin address is active for the given token ID.
   */
  function isAdminActive(
    uint256 tokenId,
    address admin
  ) public view virtual returns (bool) {
    return _admins[tokenId][admin];
  }

  /** @dev Returns the URI of a given token.
   * @param tokenId The ID of the token to retrieve the URI for.
   * @return The URI of the specified token.
   */
  function tokenURI(
    uint256 tokenId
  ) public view virtual override returns (string memory) {
    return _tokenURIs[tokenId];
  }

  function _authorizeUpgrade(address) internal override onlyOwner {}
}
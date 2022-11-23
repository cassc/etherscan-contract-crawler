// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/security/Pausable.sol";

struct OutputCrate {
  uint256 crateId;
}

/**
@title SamuraiLegends crates contract
@author Leo
*/
contract SamuraiLegendsCrates is ERC721Enumerable, AccessControl, Pausable {
  using Counters for Counters.Counter;

  Counters.Counter private _tokenIds;

  bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");

  string private _tokenURI;

  constructor(
    string memory name_,
    string memory symbol_,
    string memory tokenURI_
  ) ERC721(name_, symbol_) {
    /**
     * @notice Grants ADMIN and MINTER roles to contract creator.
     */
    _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
    _setupRole(MINTER_ROLE, msg.sender);

    _tokenURI = tokenURI_;
  }

  /**
   * @notice Batch mint new crates.
   * @param users Users to min new crates to.
   */
  function batchMintCrate(address[] calldata users)
    external
    onlyRole(DEFAULT_ADMIN_ROLE)
  {
    for (uint256 i = 0; i < users.length; i++) {
      mintCrate(users[i]);
    }

    emit CratesMinted();
  }

  /**
   * @notice Mints new crates.
   * @param user User to min new crates to.
   */
  function mintCrate(address user)
    public
    onlyRole(MINTER_ROLE)
    whenNotPaused
    returns (uint256)
  {
    uint256 id = _tokenIds.current();
    _tokenIds.increment();

    _mint(user, id);

    emit CrateMinted();

    return id;
  }

  function _baseURI() internal view override returns (string memory) {
    return _tokenURI;
  }

  function updateTokenURI(string memory tokenURI_) external onlyRole(DEFAULT_ADMIN_ROLE) {
    _tokenURI = tokenURI_;
  }

  function supportsInterface(bytes4 interfaceId)
    public
    view
    virtual
    override(ERC721Enumerable, AccessControl)
    returns (bool)
  {
    return super.supportsInterface(interfaceId);
  }

  function getAllCratesOfUser(address user) external view returns (OutputCrate[] memory) {
    uint256 balance = balanceOf(user);
    OutputCrate[] memory ids = new OutputCrate[](balance);

    for (uint256 i = 0; i < balance; i++) {
      ids[i].crateId = tokenOfOwnerByIndex(user, i);
    }

    return ids;
  }

  /**
   * @notice Lets the owner pause the contract.
   */
  function pause() external onlyRole(DEFAULT_ADMIN_ROLE) whenNotPaused {
    _pause();
  }

  /**
   * @notice Lets the owner unpause the contract.
   */
  function unpause() external onlyRole(DEFAULT_ADMIN_ROLE) whenPaused {
    _unpause();
  }

  event CrateMinted();
  event CratesMinted();
}
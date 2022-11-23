// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/security/Pausable.sol";

struct Output {
  uint256 tokenId;
}

/**
@title SamuraiLegends mystery boxes contract
@author Leo
*/
contract SamuraiLegendsMysteryBoxes is ERC721Enumerable, AccessControl, Pausable {
  using Counters for Counters.Counter;

  Counters.Counter private _tokenIds;

  bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");
  address public constant BURN_ADDRESS = 0x000000000000000000000000000000000000dEaD;

  string private _tokenURI;
  bool public openable;

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
   * @notice Batch mint new items.
   * @param users Users to min new items to.
   */
  function batchMint(address[] calldata users) external onlyRole(DEFAULT_ADMIN_ROLE) {
    for (uint256 i = 0; i < users.length; i++) {
      mint(users[i]);
    }
  }

  /**
   * @notice Mints new items.
   * @param user User to min new items to.
   */
  function mint(address user) public onlyRole(MINTER_ROLE) whenNotPaused returns (uint256) {
    uint256 id = _tokenIds.current();
    _tokenIds.increment();

    _mint(user, id);

    emit Minted(user, id);

    return id;
  }

  /**
   * @notice Opens mystery box.
   * @param tokenId Mystery box tokenId to open.
   */
  function open(uint256 tokenId) external whenNotPaused whenOpenable {
    require(ownerOf(tokenId) == msg.sender, "SamuraiLegendsMysteryBoxes::open: sender isn't the owner");

    safeTransferFrom(msg.sender, BURN_ADDRESS, tokenId);

    emit Opened(msg.sender, tokenId);
  }

  function _baseURI() internal view override returns (string memory) {
    return _tokenURI;
  }

  function updateTokenURI(string memory tokenURI_) external onlyRole(DEFAULT_ADMIN_ROLE) {
    _tokenURI = tokenURI_;
  }

  function supportsInterface(bytes4 interfaceId) public view virtual override(ERC721Enumerable, AccessControl) returns (bool) {
    return super.supportsInterface(interfaceId);
  }

  function balanceOfBatch(address owner) external view returns (Output[] memory) {
    uint256 balance = balanceOf(owner);
    Output[] memory ids = new Output[](balance);

    for (uint256 i = 0; i < balance; i++) {
      ids[i].tokenId = tokenOfOwnerByIndex(owner, i);
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

  /**
   * @notice Sets openable value
   */
  function setOpenable(bool _openable) external onlyRole(DEFAULT_ADMIN_ROLE) whenNotPaused {
    openable = _openable;

    emit OpenableSet();
  }

  /**
   * @notice Checks if the mystery box is openable
   */
  modifier whenOpenable() {
    require(openable == true, "SamuraiLegendsMysteryBoxes::whenOpenable: mystery box isn't openable");
    _;
  }

  event Minted(address indexed user, uint256 tokenId);
  event Opened(address indexed user, uint256 tokenId);
  event OpenableSet();
}
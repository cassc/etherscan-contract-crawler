// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/utils/Counters.sol";

struct OutputItem {
  uint256 tokenId;
}

/**
 * @title SamuraiLegends nfts contract
 * @author Leo
 */
contract Equipment is ERC721Enumerable, AccessControl {
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
   * @notice Batch mint new items.
   * @param users Users to min new items to.
   */
  function batchMint(address[] calldata users) external onlyRole(MINTER_ROLE) {
    for (uint256 i = 0; i < users.length; i++) {
      mint(users[i]);
    }
  }

  /**
   * @notice Mints new items.
   * @param user User to min new items to.
   */
  function mint(address user) public onlyRole(MINTER_ROLE) returns (uint256) {
    uint256 id = _tokenIds.current();

    _tokenIds.increment();

    _mint(user, id);

    return id;
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

  function getAllItemsOfUser(address user) external view returns (OutputItem[] memory) {
    uint256 balance = balanceOf(user);
    OutputItem[] memory ids = new OutputItem[](balance);

    for (uint256 i = 0; i < balance; i++) {
      ids[i].tokenId = tokenOfOwnerByIndex(user, i);
    }

    return ids;
  }
}
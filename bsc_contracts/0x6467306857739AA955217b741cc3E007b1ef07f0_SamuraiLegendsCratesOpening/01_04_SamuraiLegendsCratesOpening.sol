// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";

interface Crates {
  function ownerOf(uint256 tokenId) external returns (address);

  function transferFrom(
    address from,
    address to,
    uint256 tokenId
  ) external;
}

interface Items {
  function mint(address user) external returns (uint256);
}

/**
 * @title Crates opening contract
 * @notice Contract that adds support of crates opening.
 * @author Leo
 */
contract SamuraiLegendsCratesOpening is Ownable, Pausable {
  Crates public immutable crates;
  Items public immutable items;

  string public name;

  address public constant BURN_ADDRESS = 0x000000000000000000000000000000000000dEaD;

  mapping(uint256 => uint256) public itemIdToCrateId;

  constructor(
    string memory name_,
    Crates crates_,
    Items items_
  ) {
    name = name_;
    crates = crates_;
    items = items_;

    _pause();
  }

  /**
   * @notice Opens crates.
   * @param crateIds user crate ids to open.
   */
  function openCrates(uint256[] calldata crateIds) external whenNotPaused {
    for (uint256 i = 0; i < crateIds.length; i++) {
      uint256 crateId = crateIds[i];
      require(crates.ownerOf(crateId) == msg.sender, "sender isn't the owner");

      crates.transferFrom(msg.sender, BURN_ADDRESS, crateId);
      uint256 itemId = items.mint(msg.sender);

      itemIdToCrateId[itemId] = crateId;

      emit CrateOpened(msg.sender, crateId, itemId);
    }
  }

  /**
   * @notice Lets the owner pause the contract.
   */
  function pause() external whenNotPaused onlyOwner {
    _pause();
  }

  /**
   * @notice Lets the owner unpause the contract.
   */
  function unpause() external whenPaused onlyOwner {
    _unpause();
  }

  event CrateOpened(address indexed user, uint256 crateId, uint256 itemId);
}
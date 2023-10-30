// SPDX-License-Identifier: MIT OR Apache-2.0
pragma solidity ^0.8.18;

import { ERC721Upgradeable } from "@openzeppelin/contracts-upgradeable/token/ERC721/ERC721Upgradeable.sol";

import { WorldsUserRoles } from "../../mixins/worlds/WorldsUserRoles.sol";

error WorldsTransfer2Step_Caller_Not_Token_Owner_Or_Approved();
error WorldsTransfer2Step_Not_Pending_Owner_For_Token_Id(address pendingOwner);
error WorldsTransfer2Step_Transfer_To_Already_Initiated();

/**
 * @title Introduces 2 step transfers for World NFTs.
 * @author reggieag
 */
abstract contract WorldsTransfer2Step is ERC721Upgradeable, WorldsUserRoles {
  /// @notice Stores the pending owner for a token ID.
  mapping(uint256 worldId => address pendingOwner) private $worldIdToPendingOwner;

  /**
   * @notice Emitted when a transfer is started or cancelled.
   * @param to The pending recipient's address.
   * When the `to address` is the zero address, this indicates that the transfer has been canceled.
   * @param worldId The ID of the token.
   */
  event BeginTransfer(address indexed to, uint256 indexed worldId);

  ////////////////////////////////////////////////////////////////
  // Transfer flow
  ////////////////////////////////////////////////////////////////

  /**
   * @notice Begins a 2 step transfer by setting the pending owner. The recipient can complete the process by calling
   * `acceptTransfer`.
   * @param to The pending recipient's address.
   * To cancel a transfer for a World, call this function with the `to` set to address(0).
   * @param worldId The ID of the World to transfer.
   * @dev Callable by the World owner or an approved address.
   */
  function beginTransfer(address to, uint256 worldId) external {
    if (!_isApprovedOrOwner(_msgSender(), worldId)) {
      revert WorldsTransfer2Step_Caller_Not_Token_Owner_Or_Approved();
    }
    if ($worldIdToPendingOwner[worldId] == to) {
      revert WorldsTransfer2Step_Transfer_To_Already_Initiated();
    }

    $worldIdToPendingOwner[worldId] = to;

    emit BeginTransfer(to, worldId);
  }

  /**
   * @notice Accept a pending 2 step transfer by the pending owner, completing the transfer.
   * @param worldId The ID of the World to receive.
   * @dev The previous owner will be granted the admin user role for the World.
   */
  function acceptTransfer(uint256 worldId) external {
    address pendingOwner = $worldIdToPendingOwner[worldId];
    if (pendingOwner != _msgSender()) {
      revert WorldsTransfer2Step_Not_Pending_Owner_For_Token_Id(pendingOwner);
    }

    address previousOwner = ownerOf(worldId);
    _transfer(previousOwner, pendingOwner, worldId);

    // Grant the previous owner the admin role if they do not already have it.
    if (!hasAdminRole(worldId, previousOwner)) {
      setAdminRole(worldId, previousOwner);
    }
  }

  /**
   * @notice Get the pending owner for a worldId.
   * @param worldId The ID of the token to transfer.
   * @return pendingOwner The pending owner which can `acceptTransfer`. Returns address(0) if no transfer is pending or
   * the token ID does not exist.
   */
  function getPendingOwner(uint256 worldId) external view returns (address pendingOwner) {
    pendingOwner = $worldIdToPendingOwner[worldId];
  }

  ////////////////////////////////////////////////////////////////
  // Cleanup
  ////////////////////////////////////////////////////////////////

  function _afterTokenTransfer(
    address from,
    address to,
    uint256 firstTokenId,
    uint256 batchSize
  ) internal virtual override {
    if (from != address(0)) {
      // Clear pending owner after a transfer or burn. This is not required on Mint since tokenIDs are not reused.
      delete $worldIdToPendingOwner[firstTokenId];
    }

    super._afterTokenTransfer(from, to, firstTokenId, batchSize);
  }

  /**
   * @notice This empty reserved space is put in place to allow future versions to add new variables without shifting
   * down storage in the inheritance chain. See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
   * @dev This file uses a total of 1,000 slots.
   */
  uint256[999] private __gap;
}
// SPDX-License-Identifier: MIT OR Apache-2.0
pragma solidity ^0.8.18;

import { ERC721Upgradeable } from "@openzeppelin/contracts-upgradeable/token/ERC721/ERC721Upgradeable.sol";

import { IWorldsNFTMarket } from "../../interfaces/internal/IWorldsNFTMarket.sol";

import { WorldsPaymentInfo } from "./WorldsPaymentInfo.sol";
import { WorldsUserRoles } from "./WorldsUserRoles.sol";

error WorldsAllowlistBySeller_Address_0_May_Not_Be_Added();
error WorldsAllowlistBySeller_Seller_Already_On_Allowlist();
error WorldsAllowlistBySeller_Seller_Not_Allowed();
error WorldsAllowlistBySeller_Take_Rate_Too_Low(uint16 minimumTakeRateInBasisPoints);

/**
 * @title Allows curators to grant permissions to list with a World, authorized by the NFT's seller's address.
 * @author HardlyDifficult
 */
abstract contract WorldsAllowlistBySeller is IWorldsNFTMarket, WorldsUserRoles, WorldsPaymentInfo {
  struct SellerPermissions {
    bool isAllowed;
    // Per-seller take rates and other configuration may be added in the future.
  }

  /// @notice Stores permissions for individual sellers on a per-World basis.
  mapping(uint256 worldId => mapping(address seller => SellerPermissions permissions))
    private $worldIdToSellerToPermissions;

  /**
   * @notice Emitted when a seller is added to an allowlist.
   * @param worldId The World the seller was added to.
   * @param seller The seller which was given permissions to list with a World.
   */
  event AddToAllowlistBySeller(uint256 indexed worldId, address indexed seller);

  ////////////////////////////////////////////////////////////////
  // Management
  ////////////////////////////////////////////////////////////////

  /**
   * @notice Adds a seller to the allowlist for a World.
   * @param worldId The World the seller is being added to.
   * @param seller The seller to give permissions to list with a World.
   * @dev Callable by the World owner, admin, or editor.
   */
  function addToAllowlistBySeller(uint256 worldId, address seller) external onlyEditor(worldId) {
    _addToAllowlistBySeller(worldId, seller);
  }

  function _addToAllowlistBySeller(uint256 worldId, address seller) internal {
    if (seller == address(0)) {
      revert WorldsAllowlistBySeller_Address_0_May_Not_Be_Added();
    }

    SellerPermissions storage permissions = $worldIdToSellerToPermissions[worldId][seller];
    if (permissions.isAllowed) {
      revert WorldsAllowlistBySeller_Seller_Already_On_Allowlist();
    }

    permissions.isAllowed = true;

    emit AddToAllowlistBySeller(worldId, seller);
  }

  ////////////////////////////////////////////////////////////////
  // Authorization
  ////////////////////////////////////////////////////////////////

  /**
   * @notice Reverts if the seller is not allowed to list with a World.
   * @param worldId The World the seller is trying to list with.
   * @param seller The seller trying to list with a World.
   */
  function _authorizeBySeller(uint256 worldId, uint16 takeRateInBasisPoints, address seller) internal view {
    if (!$worldIdToSellerToPermissions[worldId][seller].isAllowed) {
      revert WorldsAllowlistBySeller_Seller_Not_Allowed();
    }
    if (takeRateInBasisPoints < getDefaultTakeRate(worldId)) {
      revert WorldsAllowlistBySeller_Take_Rate_Too_Low(getDefaultTakeRate(worldId));
    }
  }

  /**
   * @notice Returns true if the seller is allowed to list with a World.
   * @param worldId The World the seller is trying to list with.
   * @param seller The seller trying to list with a World.
   * @dev Always returns false if the World DNE or has been burned.
   */
  function isSellerAllowed(uint256 worldId, address seller) external view returns (bool isAllowed) {
    if (_ownerOf(worldId) != address(0)) {
      isAllowed = $worldIdToSellerToPermissions[worldId][seller].isAllowed;
    }
  }

  ////////////////////////////////////////////////////////////////
  // Inheritance Requirements
  // (no-ops to avoid compile errors)
  ////////////////////////////////////////////////////////////////

  function _burn(uint256 tokenId) internal virtual override(ERC721Upgradeable, WorldsPaymentInfo) {
    super._burn(tokenId);
  }

  /**
   * @notice This empty reserved space is put in place to allow future versions to add new variables without shifting
   * down storage in the inheritance chain. See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
   * @dev This file uses a total of 1,000 slots.
   */
  uint256[999] private __gap;
}
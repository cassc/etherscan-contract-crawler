// SPDX-License-Identifier: MIT OR Apache-2.0
pragma solidity ^0.8.18;

import { ERC721Upgradeable } from "@openzeppelin/contracts-upgradeable/token/ERC721/ERC721Upgradeable.sol";
import { SafeCast } from "@openzeppelin/contracts/utils/math/SafeCast.sol";

import { IWorldsNFTMarket } from "../../interfaces/internal/IWorldsNFTMarket.sol";

import { WorldsMetadata } from "./WorldsMetadata.sol";
import { WorldsPaymentInfo } from "./WorldsPaymentInfo.sol";
import { WorldsUserRoles } from "./WorldsUserRoles.sol";

error WorldsManagement_Worlds_Not_Migrated();

/**
 * @title Allows curators to mint and burn worlds.
 * @author HardlyDifficult
 */
abstract contract WorldsManagement is IWorldsNFTMarket, WorldsUserRoles, WorldsMetadata, WorldsPaymentInfo {
  using SafeCast for uint256;

  /// @notice The sequence id for worlds, set to the most recent World created.
  /// @dev Capping the size of this variable to 32 bits allows us to save gas by using uint32s elsewhere.
  uint32 private $latestWorldIdMinted;

  /// @notice Prevent minting new worlds until the migration is complete.
  /// @dev This ensures og IDs are not taken before they are able to migrate.
  modifier onlyIfMigrated() {
    // Only the latter check is necessary, but the former is included to save gas in the happy path.
    if ($latestWorldIdMinted == 0 && _getInitializedVersion() < 2) {
      revert WorldsManagement_Worlds_Not_Migrated();
    }
    _;
  }

  ////////////////////////////////////////////////////////////////
  // Setup
  ////////////////////////////////////////////////////////////////

  /// @notice Stores the next tokenID to use when minting new Worlds, after the migration is complete.
  function _initializeWorldsManagement(uint256 lastExhibitionIdCreated) internal {
    $latestWorldIdMinted = lastExhibitionIdCreated.toUint32();
  }

  ////////////////////////////////////////////////////////////////
  // Management
  ////////////////////////////////////////////////////////////////

  /**
   * @notice Allows a curator to mint a new World NFT.
   * @param defaultTakeRateInBasisPoints The curator's take rate for sales of curated pieces in supported marketplaces.
   * @param paymentAddress The address that will receive curator payments for the World.
   * @param name The World's name.
   */
  function mint(
    uint16 defaultTakeRateInBasisPoints,
    address payable paymentAddress,
    string calldata name
  ) external onlyIfMigrated returns (uint256 worldId) {
    // Checked math ensures that the worldId won't overflow 32 bits.
    worldId = ++$latestWorldIdMinted;
    _mintWorld(worldId, defaultTakeRateInBasisPoints, paymentAddress, name);
  }

  function _mintWorld(
    uint256 worldId,
    uint16 defaultTakeRateInBasisPoints,
    address payable paymentAddress,
    string memory name
  ) internal {
    _mintWorldsPaymentInfo(worldId, defaultTakeRateInBasisPoints, paymentAddress);
    _mintMetadata(worldId, name);
    _safeMint(_msgSender(), worldId);
  }

  /**
   * @notice Allows a curator to burn a World NFT they own.
   * @param worldId The id of the World NFT to burn.
   */
  function burn(uint256 worldId) external onlyOwner(worldId) {
    _burn(worldId);
  }

  ////////////////////////////////////////////////////////////////
  // Inheritance Requirements
  // (no-ops to avoid compile errors)
  ////////////////////////////////////////////////////////////////

  function _burn(uint256 tokenId) internal virtual override(ERC721Upgradeable, WorldsMetadata, WorldsPaymentInfo) {
    super._burn(tokenId);
  }

  function supportsInterface(
    bytes4 interfaceId
  ) public view virtual override(ERC721Upgradeable, WorldsMetadata) returns (bool isSupported) {
    isSupported = super.supportsInterface(interfaceId);
  }

  function tokenURI(
    uint256 worldId
  ) public view virtual override(ERC721Upgradeable, WorldsMetadata) returns (string memory uri) {
    uri = super.tokenURI(worldId);
  }

  /**
   * @notice This empty reserved space is put in place to allow future versions to add new variables without shifting
   * down storage in the inheritance chain. See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
   * @dev This file uses a total of 1,000 slots.
   */
  uint256[999] private __gap;
}
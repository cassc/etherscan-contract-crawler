// SPDX-License-Identifier: MIT OR Apache-2.0
pragma solidity ^0.8.18;

import { ERC721Upgradeable } from "@openzeppelin/contracts-upgradeable/token/ERC721/ERC721Upgradeable.sol";

import { INFTDropMarketExhibitionMigration } from "../../interfaces/internal/INFTDropMarketExhibitionMigration.sol";
import { INFTMarketExhibitionMigration } from "../../interfaces/internal/INFTMarketExhibitionMigration.sol";

import { NFTDropMarketNode } from "../shared/NFTDropMarketNode.sol";
import { NFTMarketNode } from "../shared/NFTMarketNode.sol";

import { WorldsAllowlistBySeller } from "./WorldsAllowlistBySeller.sol";
import { WorldsInventoryByCollection } from "./WorldsInventoryByCollection.sol";
import { WorldsInventoryByNft } from "./WorldsInventoryByNft.sol";
import { WorldsManagement } from "./WorldsManagement.sol";

// Migration errors
error WorldsNftMarketExhibitionMigration_Caller_Is_Not_The_Curator();
error WorldsNftMarketExhibitionMigration_Collection_Not_Listed_With_Exhibition(address nftContract);
error WorldsNftMarketExhibitionMigration_Exhibition_Does_Not_Exist();
error WorldsNftMarketExhibitionMigration_NFT_Not_Listed_With_Exhibition(address nftContract, uint256 nftTokenId);
error WorldsNftMarketExhibitionMigration_No_Listings_Provided();

/**
 * @title Coordinates the migration of NFTMarket contract's exhibitions to the Worlds contract.
 * @author HardlyDifficult
 */
abstract contract WorldsNftMarketExhibitionMigration is
  NFTMarketNode,
  NFTDropMarketNode,
  WorldsAllowlistBySeller,
  WorldsInventoryByCollection,
  WorldsInventoryByNft,
  WorldsManagement
{
  ////////////////////////////////////////////////////////////////
  // Setup
  ////////////////////////////////////////////////////////////////

  /**
   * @notice Called by Foundation once after the Worlds contract is deployed and market contracts upgraded in order to
   * complete the migration and allow World NFTs to be minted.
   */
  function initializeWorldsNftMarketExhibitionMigration() external reinitializer(2) onlyFoundationAdmin {
    uint256 lastExhibitionIdCreated = INFTMarketExhibitionMigration(nftMarket).worldsInitializeMigration();
    _initializeWorldsManagement(lastExhibitionIdCreated);
  }

  ////////////////////////////////////////////////////////////////
  // Migration
  ////////////////////////////////////////////////////////////////

  /**
   * @notice Migrate an exhibition from the NFTMarket and NFTDropMarket contracts to the Worlds contract.
   * @param exhibitionId The ID of the exhibition to migrate.
   * @param sellers The sellers which should be added to the World's seller allowlist.
   * These sellers may or may not already be added to the exhibition.
   * @param nftListings The NFT listings which already exist in the NFTMarket for this exhibition, and should be
   * added to the World's NFT inventory.
   * @param collectionListings The collection listings which already exist in the NFTDropMarket for this exhibition, and
   * should be added to the World's collection inventory.
   * @dev We are unable to guarantee that all state is migrated. Any sellers not provided will no longer be associated
   * with the World or exhibition. Markets will continue to respect any missed listings, but they will not be recognized
   * by the World and eventually that data will be obsoleted.
   */
  function migrateFromExhibition(
    uint256 exhibitionId,
    address[] calldata sellers,
    INFTMarketExhibitionMigration.NFTListing[] calldata nftListings,
    address[] calldata collectionListings
  ) external onlyIfMigrated {
    address curator = _msgSender();

    // Verify and clean up NFTMarket state.
    (string memory name, uint16 takeRateInBasisPoints) = INFTMarketExhibitionMigration(nftMarket)
      .worldsMigrateExhibition(exhibitionId, curator);

    // Mint the World NFT
    _mintWorld({
      worldId: exhibitionId,
      defaultTakeRateInBasisPoints: takeRateInBasisPoints,
      paymentAddress: payable(curator),
      name: name
    });

    // Store the sellers specified. Verification not required since this list was originally provided by the curator.
    for (uint256 i = 0; i < sellers.length; ) {
      _addToAllowlistBySeller(exhibitionId, sellers[i]);

      unchecked {
        ++i;
      }
    }

    // Migrate listings.
    _resumeMigrateFromExhibition(exhibitionId, takeRateInBasisPoints, nftListings, collectionListings);
  }

  /**
   * @notice Migrate any additional exhibition listings from the NFTMarket and NFTDropMarket contracts to the Worlds
   * contract.
   * @param exhibitionId The ID of the exhibition to migrate.
   * @param nftListings The NFT listings which already exist in the NFTMarket for this exhibition, and should be
   * added to the World's NFT inventory.
   * @param collectionListings The collection listings which already exist in the NFTDropMarket for this exhibition, and
   * should be added to the World's collection inventory.
   * @dev This is a permissionless call, anyone can resume migrating missed listings.
   */
  function resumeMigrateFromExhibition(
    uint256 exhibitionId,
    INFTMarketExhibitionMigration.NFTListing[] calldata nftListings,
    address[] calldata collectionListings
  ) external {
    _requireMinted(exhibitionId);
    if (nftListings.length == 0 && collectionListings.length == 0) {
      revert WorldsNftMarketExhibitionMigration_No_Listings_Provided();
    }

    _resumeMigrateFromExhibition(exhibitionId, getDefaultTakeRate(exhibitionId), nftListings, collectionListings);
  }

  function _resumeMigrateFromExhibition(
    uint256 exhibitionId,
    uint16 takeRateInBasisPoints,
    INFTMarketExhibitionMigration.NFTListing[] calldata nftListings,
    address[] calldata collectionListings
  ) private {
    // Migrate NFT listings (only verified listings)
    if (nftListings.length > 0) {
      // Verify listings, clean up NFTMarket state, and return the seller for each.
      address[] memory nftSellers = INFTMarketExhibitionMigration(nftMarket).worldsMigrateExhibitionListings(
        exhibitionId,
        nftListings
      );

      // Store each listing locally.
      for (uint256 i = 0; i < nftListings.length; ) {
        _addToWorldByNft(
          exhibitionId,
          nftSellers[i],
          nftListings[i].nftContract,
          nftListings[i].nftTokenId,
          takeRateInBasisPoints
        );

        unchecked {
          ++i;
        }
      }
    }

    // Migrate World listings (only verified listings)
    if (collectionListings.length > 0) {
      // Verify listings, clean up NFTDropMarket state, and return the seller for each.
      address[] memory collectionSellers = INFTDropMarketExhibitionMigration(nftDropMarket)
        .worldsMigrateExhibitionListings(exhibitionId, collectionListings);

      // Store each listing locally.
      for (uint256 i = 0; i < collectionListings.length; ) {
        _addToWorldByCollection(exhibitionId, collectionSellers[i], collectionListings[i], takeRateInBasisPoints);

        unchecked {
          ++i;
        }
      }
    }
  }

  ////////////////////////////////////////////////////////////////
  // Inheritance Requirements
  // (no-ops to avoid compile errors)
  ////////////////////////////////////////////////////////////////

  function _burn(uint256 worldId) internal virtual override(WorldsAllowlistBySeller, WorldsManagement) {
    super._burn(worldId);
  }

  function supportsInterface(
    bytes4 interfaceId
  ) public view virtual override(ERC721Upgradeable, WorldsManagement) returns (bool isSupported) {
    isSupported = super.supportsInterface(interfaceId);
  }

  function tokenURI(
    uint256 worldId
  ) public view virtual override(ERC721Upgradeable, WorldsManagement) returns (string memory uri) {
    uri = super.tokenURI(worldId);
  }

  // This mixin uses 0 slots.
}
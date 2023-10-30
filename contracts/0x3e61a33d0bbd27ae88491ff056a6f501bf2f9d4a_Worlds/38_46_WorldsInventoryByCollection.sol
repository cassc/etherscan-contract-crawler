// SPDX-License-Identifier: MIT OR Apache-2.0
pragma solidity ^0.8.18;

import { SafeCast } from "@openzeppelin/contracts/utils/math/SafeCast.sol";

import { IWorldsDropMarket } from "../../interfaces/internal/IWorldsDropMarket.sol";

import { WorldsAllowlist } from "./WorldsAllowlist.sol";

error WorldsInventoryByCollection_Already_In_This_World();

/**
 * @title Allows listing collections with a World.
 * @author HardlyDifficult
 */
abstract contract WorldsInventoryByCollection is IWorldsDropMarket, WorldsAllowlist {
  using SafeCast for uint256;

  struct CollectionInventorySettings {
    uint32 worldId;
    uint16 takeRateInBasisPoints;
  }

  /// @notice The settings for each Collection that is listed with a World.
  mapping(address seller => mapping(address nftContract => CollectionInventorySettings settings))
    private $sellerToNftContractToSettings;

  /**
   * @notice Emitted when an NFT Collection is added to a World.
   * @param worldId The ID of the World that the NFT Collection was added to.
   * @param seller The address of the seller that added the NFT Collection to the World.
   * @param nftContract The address of the collection that was added to the World.
   * @param takeRateInBasisPoints The take rate the seller agreed to pay if the NFT Collection is sold.
   */
  event AddToWorldByCollection(
    uint256 indexed worldId,
    address indexed seller,
    address indexed nftContract,
    uint16 takeRateInBasisPoints
  );

  /**
   * @notice Emitted when NFT(s) from a collection in a World is sold.
   * @param worldId The ID of the World that was credited with the sale.
   * @param marketplace The address of the marketplace that sold the NFT(s).
   * @param seller The address of the seller that added the NFT Collection to the World.
   * @param nftContract The address of the collection that was added to the World.
   * @param count The number of NFT(s) sold.
   * @param totalSalePrice The total sale price of the NFT(s) sold.
   * @param takeRateInBasisPoints The take rate the seller agreed to pay when NFTs are sold.
   */
  event SoldInWorldByCollection(
    uint256 indexed worldId,
    address indexed marketplace,
    address indexed seller,
    address nftContract,
    uint256 count,
    uint256 totalSalePrice,
    uint16 takeRateInBasisPoints
  );

  ////////////////////////////////////////////////////////////////
  // Inventory Management
  ////////////////////////////////////////////////////////////////

  /**
   * @notice Add an NFT Collection to a World for the msg.sender as the seller.
   * @dev A trusted router can select the seller which is used here.
   * @param worldId The ID of the World to add the NFT Collection to.
   * @param nftContract The address of the NFT Collection to add to the World.
   * @param takeRateInBasisPoints The take rate the seller agrees to pay if the NFT Collection is sold.
   */
  function addToWorldByCollection(
    uint256 worldId,
    address nftContract,
    uint16 takeRateInBasisPoints
  ) external onlyAllowedInventoryAddition(worldId, takeRateInBasisPoints) {
    _addToWorldByCollection(worldId, _msgSender(), nftContract, takeRateInBasisPoints);
  }

  function _addToWorldByCollection(
    uint256 worldId,
    address seller,
    address nftContract,
    uint16 takeRateInBasisPoints
  ) internal {
    if (
      worldId == $sellerToNftContractToSettings[seller][nftContract].worldId &&
      takeRateInBasisPoints == $sellerToNftContractToSettings[seller][nftContract].takeRateInBasisPoints
    ) {
      // Revert if the request is a no-op.
      revert WorldsInventoryByCollection_Already_In_This_World();
    }

    $sellerToNftContractToSettings[seller][nftContract] = CollectionInventorySettings(
      worldId.toUint32(),
      takeRateInBasisPoints
    );

    emit AddToWorldByCollection(worldId, seller, nftContract, takeRateInBasisPoints);
  }

  /**
   * @notice Returns the World association for an NFT Collection that is listed with a World, or zeros if not listed.
   * @param nftContract The address of the NFT Collection that was added to the World.
   * @param seller The address of the seller that added the NFT Collection to the World.
   * @return worldId The ID of the World that the NFT Collection was added to.
   * @return takeRateInBasisPoints The take rate the seller agreed to pay if the NFT Collection is sold.
   */
  function getAssociationByCollection(
    address nftContract,
    address seller
  ) external view returns (uint256 worldId, uint16 takeRateInBasisPoints) {
    worldId = $sellerToNftContractToSettings[seller][nftContract].worldId;
    if (_ownerOf(worldId) != address(0)) {
      // If a World association was found and has not been burned, then return the take rate as well.
      takeRateInBasisPoints = $sellerToNftContractToSettings[seller][nftContract].takeRateInBasisPoints;
    } else {
      // Otherwise return (0, 0).
      worldId = 0;
    }
  }

  ////////////////////////////////////////////////////////////////
  // Sales
  ////////////////////////////////////////////////////////////////

  /**
   * @notice Called by the marketplace when an NFT is sold, emitting sale details and returning the expected payment
   * info.
   * @param seller The address of the seller that added the NFT Collection to the World.
   * @param nftContract The address of the collection that was added to the World.
   * @param count The number of NFT(s) sold.
   * @param totalSalePrice The total sale price of the NFT(s) sold.
   * @return worldId The ID of the World that was credited with the sale.
   * @return paymentAddress The address that should receive the payment for the sale.
   * @return takeRateInBasisPoints The take rate the seller agreed to pay when NFTs are sold.
   */
  function soldInWorldByCollection(
    address seller,
    address nftContract,
    uint256 count,
    uint256 totalSalePrice
  ) external returns (uint256 worldId, address payable paymentAddress, uint16 takeRateInBasisPoints) {
    worldId = $sellerToNftContractToSettings[seller][nftContract].worldId;
    if (worldId != 0) {
      if (_ownerOf(worldId) == address(0)) {
        // The World has since been burned, so ignore the relationship.
        worldId = 0;
      } else {
        takeRateInBasisPoints = $sellerToNftContractToSettings[seller][nftContract].takeRateInBasisPoints;
        paymentAddress = getPaymentAddress(worldId);

        emit SoldInWorldByCollection({
          worldId: worldId,
          marketplace: msg.sender,
          seller: seller,
          nftContract: nftContract,
          count: count,
          totalSalePrice: totalSalePrice,
          takeRateInBasisPoints: takeRateInBasisPoints
        });
      }
    }
  }

  /**
   * @notice This empty reserved space is put in place to allow future versions to add new variables without shifting
   * down storage in the inheritance chain. See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
   * @dev This file uses a total of 1,000 slots.
   */
  uint256[999] private __gap;
}
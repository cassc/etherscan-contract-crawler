// SPDX-License-Identifier: MIT OR Apache-2.0
pragma solidity ^0.8.18;

import { SafeCast } from "@openzeppelin/contracts/utils/math/SafeCast.sol";

import { IWorldsNFTMarket } from "../../interfaces/internal/IWorldsNFTMarket.sol";

import { WorldsAllowlist } from "./WorldsAllowlist.sol";

error WorldsInventoryByNft_Already_In_This_World();
error WorldsInventoryByNft_Not_In_A_World();

/**
 * @title Allows listing NFTs with a World.
 * @author HardlyDifficult
 */
abstract contract WorldsInventoryByNft is IWorldsNFTMarket, WorldsAllowlist {
  using SafeCast for uint256;

  struct NftInventorySettings {
    uint32 worldId;
    uint16 takeRateInBasisPoints;
  }

  /// @notice The settings for each NFT that is listed with a World.
  // solhint-disable-next-line max-line-length
  mapping(address seller => mapping(address nftContract => mapping(uint256 nftTokenId => NftInventorySettings settings)))
    private $sellerToNftContractToTokenIdToSettings;

  /**
   * @notice Emitted when an NFT is added to a World.
   * @param worldId The ID of the World that the NFT was added to.
   * @param seller The address of the seller that added the NFT to the World.
   * @param nftContract The address of the collection for the NFT that was added to the World.
   * @param nftTokenId The tokenID of the NFT that was added to the World.
   * @param takeRateInBasisPoints The take rate the seller agreed to pay if the NFT is sold.
   */
  event AddToWorldByNft(
    uint256 indexed worldId,
    address indexed seller,
    address indexed nftContract,
    uint256 nftTokenId,
    uint16 takeRateInBasisPoints
  );

  /**
   * @notice Emitted when an NFT is remove from a World.
   * @param worldId The ID of the World that the NFT was previous a part of.
   * @param seller The address of the seller that removed the NFT from the World.
   * @param nftContract The address of the collection for the NFT that was removed from the World.
   * @param nftTokenId The tokenID of the NFT that was removed from the World.
   */
  event RemoveFromWorldByNft(
    uint256 indexed worldId,
    address indexed seller,
    address indexed nftContract,
    uint256 nftTokenId
  );

  /**
   * @notice Emitted when an NFT in a World is sold.
   * @param worldId The ID of the World that was credited with the sale.
   * @param marketplace The address of the marketplace that sold the NFT.
   * @param seller The address of the seller that added the NFT to the World.
   * @param nftContract The address of the collection for the NFT that was added to the World.
   * @param nftTokenId The tokenID of the NFT that was added to the World.
   * @param buyer The address of the buyer that purchased the NFT.
   * @param salePrice The total sale price of the NFT sold.
   * @param takeRateInBasisPoints The take rate the seller agreed to pay when NFTs are sold.
   */
  event SoldInWorldByNft(
    uint256 indexed worldId,
    address indexed marketplace,
    address indexed seller,
    address nftContract,
    uint256 nftTokenId,
    address buyer,
    uint256 salePrice,
    uint16 takeRateInBasisPoints
  );

  ////////////////////////////////////////////////////////////////
  // Inventory Management
  ////////////////////////////////////////////////////////////////

  /**
   * @notice Add an NFT to a World for the msg.sender as the seller.
   * @dev A trusted router can select the seller which is used here.
   * @param worldId The ID of the World to add the NFT to.
   * @param nftContract The address of the collection for the NFT to add to the World.
   * @param nftTokenId The tokenID of the NFT to add to the World.
   * @param takeRateInBasisPoints The take rate the seller agrees to pay if the NFT is sold.
   */
  function addToWorldByNft(
    uint256 worldId,
    address nftContract,
    uint256 nftTokenId,
    uint16 takeRateInBasisPoints
  ) external onlyAllowedInventoryAddition(worldId, takeRateInBasisPoints) {
    _addToWorldByNft(worldId, _msgSender(), nftContract, nftTokenId, takeRateInBasisPoints);
  }

  function _addToWorldByNft(
    uint256 worldId,
    address seller,
    address nftContract,
    uint256 nftTokenId,
    uint16 takeRateInBasisPoints
  ) internal {
    if (
      worldId == $sellerToNftContractToTokenIdToSettings[seller][nftContract][nftTokenId].worldId &&
      takeRateInBasisPoints ==
      $sellerToNftContractToTokenIdToSettings[seller][nftContract][nftTokenId].takeRateInBasisPoints
    ) {
      // Revert if the request is a no-op.
      revert WorldsInventoryByNft_Already_In_This_World();
    }

    $sellerToNftContractToTokenIdToSettings[seller][nftContract][nftTokenId] = NftInventorySettings(
      worldId.toUint32(),
      takeRateInBasisPoints
    );

    emit AddToWorldByNft(worldId, seller, nftContract, nftTokenId, takeRateInBasisPoints);
  }

  /**
   * @notice Remove an NFT from a World for the sender as the seller.
   * @param nftContract The address of the collection for the NFT to remove from the World it currently belongs to.
   * @param nftTokenId The tokenID of the NFT to remove from the World it currently belongs to.
   */
  function removeFromWorldByNft(address nftContract, uint256 nftTokenId) external {
    address seller = _msgSender();
    uint256 previousWorldId = $sellerToNftContractToTokenIdToSettings[seller][nftContract][nftTokenId].worldId;
    if (previousWorldId == 0) {
      revert WorldsInventoryByNft_Not_In_A_World();
    }

    delete $sellerToNftContractToTokenIdToSettings[seller][nftContract][nftTokenId];

    emit RemoveFromWorldByNft(previousWorldId, seller, nftContract, nftTokenId);
  }

  /**
   * @notice Returns the World association for an NFT that is listed with a World, or zeros if not listed.
   * @param nftContract The address of the collection for the NFT that was added to a World.
   * @param nftTokenId The tokenID of the NFT that was added to a World.
   * @param seller The address of the seller that added the NFT to a World.
   * @return worldId The ID of the World that the NFT was added to.
   * @return takeRateInBasisPoints The take rate the seller agreed to pay if the NFT is sold.
   */
  function getAssociationByNft(
    address nftContract,
    uint256 nftTokenId,
    address seller
  ) external view returns (uint256 worldId, uint16 takeRateInBasisPoints) {
    worldId = $sellerToNftContractToTokenIdToSettings[seller][nftContract][nftTokenId].worldId;
    if (worldId != 0 && _ownerOf(worldId) != address(0)) {
      // If a World association was found and has not been burned, then return the take rate as well.
      takeRateInBasisPoints = $sellerToNftContractToTokenIdToSettings[seller][nftContract][nftTokenId]
        .takeRateInBasisPoints;
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
   * @param seller The address of the seller that added the NFT to the World.
   * @param nftContract The address of the collection that was added to the World.
   * @param nftTokenId The tokenID of the NFT that was added to the World.
   * @param buyer The address of the buyer that purchased the NFT.
   * @param salePrice The sale price of the NFT sold.
   * @return worldId The ID of the World that was credited with the sale.
   * @return paymentAddress The address that should receive the payment for the sale.
   * @return takeRateInBasisPoints The take rate the seller agreed to pay when NFTs are sold.
   */
  function soldInWorldByNft(
    address seller,
    address nftContract,
    uint256 nftTokenId,
    address buyer,
    uint256 salePrice
  ) external returns (uint256 worldId, address payable paymentAddress, uint16 takeRateInBasisPoints) {
    worldId = $sellerToNftContractToTokenIdToSettings[seller][nftContract][nftTokenId].worldId;
    if (worldId != 0) {
      if (_ownerOf(worldId) == address(0)) {
        // The World has since been burned, so ignore the relationship.
        worldId = 0;
      } else {
        paymentAddress = getPaymentAddress(worldId);
        takeRateInBasisPoints = $sellerToNftContractToTokenIdToSettings[seller][nftContract][nftTokenId]
          .takeRateInBasisPoints;
        // Cannot clear on sale here since the market is not authorized

        emit SoldInWorldByNft(
          worldId,
          msg.sender,
          seller,
          nftContract,
          nftTokenId,
          buyer,
          salePrice,
          takeRateInBasisPoints
        );
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
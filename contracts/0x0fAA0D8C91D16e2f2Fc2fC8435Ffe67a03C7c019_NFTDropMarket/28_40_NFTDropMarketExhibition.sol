// SPDX-License-Identifier: MIT OR Apache-2.0

pragma solidity ^0.8.12;

import "@openzeppelin/contracts/utils/Context.sol";
import "@openzeppelin/contracts-upgradeable/utils/AddressUpgradeable.sol";

import "../../interfaces/internal/INFTMarketExhibition.sol";

error NFTDropMarketExhibition_Exhibition_Does_Not_Exist();
error NFTDropMarketExhibition_NFT_Market_Is_Not_A_Contract();
error NFTDropMarketExhibition_Seller_Not_Allowed_In_Exhibition();

/**
 * @title Enables a curation surface for sellers to exhibit their NFTs in the drop market.
 * @author HardlyDifficult & philbirt
 */
abstract contract NFTDropMarketExhibition is Context {
  using AddressUpgradeable for address;

  /// @notice Maps a collection to the exhibition it was listed with.
  mapping(address => uint256) private nftContractToExhibitionId;

  /// @notice The NFT Market contract address, containing exhibition definitions.
  address private immutable _nftMarket;

  /**
   * @notice Emitted when a collection is added to an exhibition.
   * @param nftContract The contract address of the collection.
   * @param exhibitionId The ID of the exhibition the collection was added to.
   */
  event CollectionAddedToExhibition(address indexed nftContract, uint256 indexed exhibitionId);

  /**
   * @notice Set immutable variables for the implementation contract.
   * @dev Using immutable instead of constants allows us to use different values on testnet.
   * @param nftMarket The NFT Market contract address, containing exhibition definitions.
   */
  constructor(address nftMarket) {
    if (!nftMarket.isContract()) {
      revert NFTDropMarketExhibition_NFT_Market_Is_Not_A_Contract();
    }
    _nftMarket = nftMarket;
  }

  /**
   * @notice Adds a collection to an exhibition, if the ID provided is not 0.
   */
  function _addCollectionToExhibition(address nftContract, uint256 exhibitionId) internal {
    if (exhibitionId != 0) {
      // If there is an exhibition, make sure the seller is allowed to list in it
      if (
        !INFTMarketExhibition(_nftMarket).isAllowedSellerForExhibition({
          exhibitionId: exhibitionId,
          seller: _msgSender()
        })
      ) {
        (address curator, ) = INFTMarketExhibition(_nftMarket).getExhibitionPaymentDetails(exhibitionId);
        if (curator == address(0)) {
          // Provides a more useful error when an exhibition never existed or has since been deleted.
          revert NFTDropMarketExhibition_Exhibition_Does_Not_Exist();
        }
        revert NFTDropMarketExhibition_Seller_Not_Allowed_In_Exhibition();
      }

      nftContractToExhibitionId[nftContract] = exhibitionId;

      emit CollectionAddedToExhibition(nftContract, exhibitionId);
    }
  }

  /**
   * @notice Returns the exhibition ID for a given Collection.
   * @param nftContract The contract address of the Collection.
   * @return exhibitionId The ID of the exhibition this Collection is assigned to, or 0 if it's
   * not assigned to an exhibition.
   */
  function getExhibitionIdForCollection(address nftContract) external view returns (uint256 exhibitionId) {
    exhibitionId = nftContractToExhibitionId[nftContract];
  }

  /**
   * @notice Returns the contract which contains the exhibition definitions.
   * @return nftMarket The NFT Market contract address.
   */
  function getNftMarket() external view returns (address nftMarket) {
    nftMarket = _nftMarket;
  }

  /**
   * @notice Returns the exhibition payment details for a given Collection.
   * @dev The payment address and take rate will be 0 if the collection is not assigned to an exhibition or if the
   * exhibition has seen been deleted.
   */
  function _getExhibitionByCollection(
    address nftContract
  ) internal view returns (address payable curator, uint16 takeRateInBasisPoints) {
    uint256 exhibitionId = nftContractToExhibitionId[nftContract];
    if (exhibitionId != 0) {
      (curator, takeRateInBasisPoints) = INFTMarketExhibition(_nftMarket).getExhibitionPaymentDetails(exhibitionId);
    }
  }

  /**
   * @notice This empty reserved space is put in place to allow future versions to add new
   * variables without shifting down storage in the inheritance chain.
   * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
   * @dev This mixin uses 1,000 slots in total.
   */
  uint256[999] private __gap;
}
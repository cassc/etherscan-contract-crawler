// SPDX-License-Identifier: MIT OR Apache-2.0

pragma solidity ^0.8.12;

import "@openzeppelin/contracts/utils/Context.sol";

import "../../interfaces/internal/INFTMarketExhibition.sol";
import "../shared/Constants.sol";

/// @param curator The curator for this exhibition.
error NFTMarketExhibition_Caller_Is_Not_Curator(address curator);
error NFTMarketExhibition_Can_Not_Add_Dupe_Seller();
error NFTMarketExhibition_Curator_Automatically_Allowed();
error NFTMarketExhibition_Exhibition_Does_Not_Exist();
error NFTMarketExhibition_Seller_Not_Allowed_In_Exhibition();
error NFTMarketExhibition_Sellers_Required();
error NFTMarketExhibition_Take_Rate_Too_High();

/**
 * @title Enables a curation surface for sellers to exhibit their NFTs.
 * @author HardlyDifficult
 */
abstract contract NFTMarketExhibition is INFTMarketExhibition, Context {
  /**
   * @notice Stores details about an exhibition.
   */
  struct Exhibition {
    /// @notice The curator which created this exhibition.
    address payable curator;
    /// @notice The rate of the sale which goes to the curator.
    uint16 takeRateInBasisPoints;
    // 80-bits available in the first slot

    /// @notice A name for the exhibition.
    string name;
  }

  /// @notice Tracks the next sequence ID to be assigned to an exhibition.
  uint256 private latestExhibitionId;

  /// @notice Maps the exhibition ID to their details.
  mapping(uint256 => Exhibition) private idToExhibition;

  /// @notice Maps an exhibition to the list of sellers allowed to list with it.
  mapping(uint256 => mapping(address => bool)) private exhibitionIdToSellerToIsAllowed;

  /// @notice Maps an NFT to the exhibition it was listed with.
  mapping(address => mapping(uint256 => uint256)) private nftContractToTokenIdToExhibitionId;

  /**
   * @notice Emitted when an exhibition is created.
   * @param exhibitionId The ID for this exhibition.
   * @param curator The curator which created this exhibition.
   * @param name The name for this exhibition.
   * @param takeRateInBasisPoints The rate of the sale which goes to the curator.
   */
  event ExhibitionCreated(
    uint256 indexed exhibitionId,
    address indexed curator,
    string name,
    uint16 takeRateInBasisPoints
  );

  /**
   * @notice Emitted when an exhibition is deleted.
   * @param exhibitionId The ID for the exhibition.
   */
  event ExhibitionDeleted(uint256 indexed exhibitionId);

  /**
   * @notice Emitted when an NFT is listed in an exhibition.
   * @param nftContract The contract address of the NFT.
   * @param tokenId The ID of the NFT.
   * @param exhibitionId The ID of the exhibition it was listed with.
   */
  event NftAddedToExhibition(address indexed nftContract, uint256 indexed tokenId, uint256 indexed exhibitionId);

  /**
   * @notice Emitted when an NFT is no longer associated with an exhibition for reasons other than a sale.
   * @param nftContract The contract address of the NFT.
   * @param tokenId The ID of the NFT.
   * @param exhibitionId The ID of the exhibition it was originally listed with.
   */
  event NftRemovedFromExhibition(address indexed nftContract, uint256 indexed tokenId, uint256 indexed exhibitionId);

  /**
   * @notice Emitted when sellers are granted access to list with an exhibition.
   * @param exhibitionId The ID of the exhibition.
   * @param sellers The list of sellers granted access.
   */
  event SellersAddedToExhibition(uint256 indexed exhibitionId, address[] sellers);

  /// @notice Requires the caller to be the curator of the exhibition.
  modifier onlyExhibitionCurator(uint256 exhibitionId) {
    address curator = idToExhibition[exhibitionId].curator;
    if (curator != _msgSender()) {
      if (curator == address(0)) {
        // If the curator is not a match, check if the exhibition exists in order to provide a better error message.
        revert NFTMarketExhibition_Exhibition_Does_Not_Exist();
      }
      revert NFTMarketExhibition_Caller_Is_Not_Curator(curator);
    }
    _;
  }

  /// @notice Requires the caller pass in some number of sellers
  modifier sellersRequired(address[] calldata sellers) {
    if (sellers.length == 0) {
      revert NFTMarketExhibition_Sellers_Required();
    }
    _;
  }

  /**
   * @notice Adds sellers to exhibition.
   * @param exhibitionId The exhibition ID.
   * @param sellers The new list of sellers to be allowed to list with this exhibition.
   */
  function addSellersToExhibition(
    uint256 exhibitionId,
    address[] calldata sellers
  ) external onlyExhibitionCurator(exhibitionId) sellersRequired(sellers) {
    _addSellersToExhibition(exhibitionId, sellers);
  }

  /**
   * @notice Creates an exhibition.
   * @param name The name for this exhibition.
   * @param takeRateInBasisPoints The rate of the sale which goes to the msg.sender as the curator of this exhibition.
   * @param sellers The list of sellers allowed to list with this exhibition.
   * @dev The list of sellers may be modified after the exhibition is created via addSellersToExhibition,
   *      which only allows for adding (not removing) new sellers.
   */
  function createExhibition(
    string calldata name,
    uint16 takeRateInBasisPoints,
    address[] calldata sellers
  ) external sellersRequired(sellers) returns (uint256 exhibitionId) {
    if (takeRateInBasisPoints > MAX_EXHIBITION_TAKE_RATE) {
      revert NFTMarketExhibition_Take_Rate_Too_High();
    }

    // Create exhibition
    unchecked {
      exhibitionId = ++latestExhibitionId;
    }
    address payable sender = payable(_msgSender());
    idToExhibition[exhibitionId] = Exhibition({
      curator: sender,
      takeRateInBasisPoints: takeRateInBasisPoints,
      name: name
    });
    emit ExhibitionCreated({
      exhibitionId: exhibitionId,
      curator: sender,
      name: name,
      takeRateInBasisPoints: takeRateInBasisPoints
    });

    _addSellersToExhibition(exhibitionId, sellers);
  }

  /**
   * @notice Deletes an exhibition created by the msg.sender.
   * @param exhibitionId The ID of the exhibition to delete.
   * @dev Once deleted, any NFTs listed with this exhibition will still be listed but will no longer be associated with
   * or share revenue with the exhibition.
   */
  function deleteExhibition(uint256 exhibitionId) external onlyExhibitionCurator(exhibitionId) {
    delete idToExhibition[exhibitionId];
    emit ExhibitionDeleted(exhibitionId);
  }

  function _addSellersToExhibition(uint256 exhibitionId, address[] calldata sellers) private {
    // Populate allow list
    for (uint256 i = 0; i < sellers.length; ) {
      address seller = sellers[i];
      if (exhibitionIdToSellerToIsAllowed[exhibitionId][seller]) {
        revert NFTMarketExhibition_Can_Not_Add_Dupe_Seller();
      }
      if (seller == _msgSender()) {
        revert NFTMarketExhibition_Curator_Automatically_Allowed();
      }
      exhibitionIdToSellerToIsAllowed[exhibitionId][seller] = true;
      unchecked {
        ++i;
      }
    }
    emit SellersAddedToExhibition(exhibitionId, sellers);
  }

  /**
   * @notice Assigns an NFT to an exhibition.
   * @param nftContract The contract address of the NFT.
   * @param tokenId The ID of the NFT.
   * @param exhibitionId The ID of the exhibition to list the NFT with.
   * @dev This call is a no-op if the `exhibitionId` is 0.
   */
  function _addNftToExhibition(address nftContract, uint256 tokenId, uint256 exhibitionId) internal {
    if (exhibitionId != 0) {
      Exhibition storage exhibition = idToExhibition[exhibitionId];
      if (exhibition.curator == address(0)) {
        revert NFTMarketExhibition_Exhibition_Does_Not_Exist();
      }
      address sender = _msgSender();
      if (!exhibitionIdToSellerToIsAllowed[exhibitionId][sender] && exhibition.curator != sender) {
        revert NFTMarketExhibition_Seller_Not_Allowed_In_Exhibition();
      }
      nftContractToTokenIdToExhibitionId[nftContract][tokenId] = exhibitionId;
      emit NftAddedToExhibition(nftContract, tokenId, exhibitionId);
    }
  }

  /**
   * @notice Returns exhibition details if this NFT was assigned to one, and clears the assignment.
   * @return paymentAddress The address to send the payment to, or address(0) if n/a.
   * @return takeRateInBasisPoints The rate of the sale which goes to the curator, or 0 if n/a.
   * @dev This does not emit NftRemovedFromExhibition, instead it's expected that SellerReferralPaid will be emitted.
   */
  function _getExhibitionForPayment(
    address nftContract,
    uint256 tokenId
  ) internal returns (address payable paymentAddress, uint16 takeRateInBasisPoints) {
    uint256 exhibitionId = nftContractToTokenIdToExhibitionId[nftContract][tokenId];
    if (exhibitionId != 0) {
      paymentAddress = idToExhibition[exhibitionId].curator;
      takeRateInBasisPoints = idToExhibition[exhibitionId].takeRateInBasisPoints;
      delete nftContractToTokenIdToExhibitionId[nftContract][tokenId];
    }
  }

  /**
   * @notice Clears an NFT's association with an exhibition.
   */
  function _removeNftFromExhibition(address nftContract, uint256 tokenId) internal {
    uint256 exhibitionId = nftContractToTokenIdToExhibitionId[nftContract][tokenId];
    if (exhibitionId != 0) {
      delete nftContractToTokenIdToExhibitionId[nftContract][tokenId];
      emit NftRemovedFromExhibition(nftContract, tokenId, exhibitionId);
    }
  }

  /**
   * @notice Returns exhibition details for a given ID.
   * @param exhibitionId The ID of the exhibition to look up.
   * @return name The name of the exhibition.
   * @return curator The curator of the exhibition.
   * @return takeRateInBasisPoints The rate of the sale which goes to the curator.
   * @dev If the exhibition does not exist or has since been deleted, the curator will be address(0).
   */
  function getExhibition(
    uint256 exhibitionId
  ) external view returns (string memory name, address payable curator, uint16 takeRateInBasisPoints) {
    Exhibition memory exhibition = idToExhibition[exhibitionId];
    name = exhibition.name;
    curator = exhibition.curator;
    takeRateInBasisPoints = exhibition.takeRateInBasisPoints;
  }

  /**
   * @notice Returns the exhibition ID for a given NFT.
   * @param nftContract The contract address of the NFT.
   * @param tokenId The ID of the NFT.
   * @return exhibitionId The ID of the exhibition this NFT is assigned to, or 0 if it's not assigned to an exhibition.
   */
  function getExhibitionIdForNft(address nftContract, uint256 tokenId) external view returns (uint256 exhibitionId) {
    exhibitionId = nftContractToTokenIdToExhibitionId[nftContract][tokenId];
  }

  /**
   * @notice Returns exhibition payment details for a given ID.
   * @param exhibitionId The ID of the exhibition to look up.
   * @return curator The curator of the exhibition.
   * @return takeRateInBasisPoints The rate of the sale which goes to the curator.
   * @dev If the exhibition does not exist or has since been deleted, the curator will be address(0).
   */
  function getExhibitionPaymentDetails(
    uint256 exhibitionId
  ) external view returns (address payable curator, uint16 takeRateInBasisPoints) {
    Exhibition storage exhibition = idToExhibition[exhibitionId];
    curator = exhibition.curator;
    takeRateInBasisPoints = exhibition.takeRateInBasisPoints;
  }

  /**
   * @notice Checks if a given seller is approved to list with a given exhibition.
   * @param exhibitionId The ID of the exhibition to check.
   * @param seller The address of the seller to check.
   * @return allowedSeller True if the seller is approved to list with the exhibition.
   */
  function isAllowedSellerForExhibition(
    uint256 exhibitionId,
    address seller
  ) external view returns (bool allowedSeller) {
    address curator = idToExhibition[exhibitionId].curator;
    if (curator != address(0)) {
      allowedSeller = exhibitionIdToSellerToIsAllowed[exhibitionId][seller] || seller == curator;
    }
  }

  /**
   * @notice This empty reserved space is put in place to allow future versions to add new
   * variables without shifting down storage in the inheritance chain.
   * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
   * @dev This file uses a total of 500 slots.
   */
  uint256[496] private __gap;
}
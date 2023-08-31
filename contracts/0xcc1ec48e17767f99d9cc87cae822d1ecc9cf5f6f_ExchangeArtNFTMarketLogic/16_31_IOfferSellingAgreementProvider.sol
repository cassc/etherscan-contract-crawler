// SPDX-License-Identifier: MIT
pragma solidity ^0.8.8;

struct Offer {
  /// @notice The address of the NFT contract.
  address nftContract;
  /// @notice The id of the NFT.
  uint256 tokenId;
  /// @notice The address of the wallet placing the offer.
  address buyer;
  /// @notice The amount the buyer is willing to pay for the NFT.
  uint256 offerPrice;
}

interface IOfferSellingAgreementProvider {
  /**
   * @notice Emitted when a buy now selling agreement is created by a seller.
   *
   * @param nftContract   : The address of the contract that minted the NFT.
   * @param tokenId       : The ID of the NFT within the contract.
   * @param buyer         : The address of the seller who created the selling agreement.
   * @param price         : The price at which someone could buy this NFT. Needs to be greater than 0.
   */
  event OfferSellingAgreementCreated(
    address indexed nftContract,
    uint256 indexed tokenId,
    address indexed buyer,
    uint256 price
  );

  /**
   * @notice Emitted when a buy now selling agreement is created by a seller.
   * @param offerId   : The unique Id of the cancelled offer
   */
  event OfferSellingAgreementCancelled(uint256 offerId);

  /**
   * @notice Emitted when a buy now selling agreement is created by a seller.
   *
   * @param nftContract   : The address of the contract that minted the NFT.
   * @param tokenId       : The ID of the NFT within the contract.
   * @param buyer         : The address of the seller who created the selling agreement.
   * @param price         : The price at which someone could buy this NFT. Needs to be greater than 0.
   * @param isPrimarySale : Whether this is a primary or secondary sale. Relevant for revenue split.

   */
  event OfferSellingAgreementAccepted(
    address indexed nftContract,
    uint256 indexed tokenId,
    address indexed buyer,
    uint256 price,
    bool isPrimarySale
  );

  /**
   * @notice Allows a buyer to place an offer for an NFT.
   *
   * @param nftContract   : The address of the contract that minted the NFT.
   * @param tokenId       : The ID of the NFT within the contract.
   * @param offerAmount   : The ID of the NFT within the contract.
   */
  function createOfferSellingAgreement(
    address nftContract,
    uint256 tokenId,
    uint256 offerAmount
  ) external payable;

  /**
   * @notice Allows a buyer to cancel their offer for a specific NFT.
   * @param offerId   : The ID of the offer to cancel.
   */
  function cancelOfferSellingAgreement(uint256 offerId) external;

  /**
   * @notice Allows the owner of an NFT to accept an offer placed on that NFT
   * @param offerId   : The ID of the offer to accept.
   */
  function acceptOfferSellingAgreement(
    uint256 offerId,
    bool isPrimarySale
  ) external payable;

  function getOfferSellingAgreementDetails(
    uint256 offerId
  )
    external
    view
    returns (
      address nftContract,
      uint256 tokenId,
      address buyer,
      uint256 offerAmount
    );
}
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.8;

struct BuyNowSellingAgreement {
  address payable seller;
  uint256 price;
  uint256 startTime; // if the start time is 0, then the sale start immediately.
  bool isPrimarySale;
  uint256 id; // a unique identifier for each selling agreement
}

/**
 * @dev Interface which declares the custom types, events, errors, and public function that a contract needs to have
 * @dev to offer the buy-now mechanics.
 */
interface IBuyNowSellingAgreementProvider {
  /**
   * @notice Emitted when a buy now selling agreement is created by a seller.
   *
   * @param nftContract   : The address of the contract that minted the NFT.
   * @param tokenId       : The ID of the NFT within the contract.
   * @param seller        : The address of the seller who created the selling agreement.
   * @param price         : The price at which someone could buy this NFT. Needs to be greater than 0.
   * @param startTime     : The timestamp indicating when this NFT can be sold. If set to 0, then the sale starts immediately.
   * @param isPrimarySale : Flag indicating if this is a primary sale. Royalty distribution is affected depending on this.
   * @param id            : Unique identifier of the sale

   */
  event BuyNowSellingAgreementCreated(
    address indexed nftContract,
    uint256 indexed tokenId,
    address indexed seller,
    uint256 price,
    uint256 startTime,
    bool isPrimarySale,
    uint256 id
  );

  /**
   * @notice Emitted when a buy now selling agreement is accepted by a buyer.
   *
   * @param nftContract    : The address of the contract that minted the NFT.
   * @param tokenId        : The ID of the NFT within the contract.
   * @param seller         : The address of the seller.
   * @param buyer          : The address of the seller.
   * @param wasPrimarySale : Flag indicating if this was a primary sale. Royalty distribution is affected depending on this.
   * @param id             : Unique identifier of the sale
   * @param price         : The price at which someone could buy this NFT. Needs to be greater than 0.


   */
  event BuyNowSellingAgreementAccepted(
    address indexed nftContract,
    uint256 indexed tokenId,
    address indexed seller,
    address buyer,
    bool wasPrimarySale,
    uint256 id,
    uint256 price
  );

  /**
   * @notice Emitted when a buy now selling agreement is cancelled by the seller.
   *
   * @param nftContract : The address of the contract that minted the NFT.
   * @param tokenId     : The ID of the NFT within the contract.
   * @param seller      : The address of the seller.
   * @param id            : Unique identifier of the sale

   */
  event BuyNowSellingAgreementCancelled(
    address indexed nftContract,
    uint256 indexed tokenId,
    address indexed seller,
    uint256 id
  );

  /**
   * @notice Emitted when a buy now selling agreement is edited by the seller.
   *
   * @param nftContract : The address of the contract that minted the NFT.
   * @param tokenId     : The ID of the NFT within the contract.
   * @param seller      : The address of the seller.
   * @param newPrice    : The new price of the selling agreement.
   * @param id          : Unique identifier of the sale

   */
  event BuyNowSellingAgreementEdited(
    address indexed nftContract,
    uint256 indexed tokenId,
    address indexed seller,
    uint256 newPrice,
    uint256 id
  );

  /**
   * @notice Allows a seller to create a buy now selling agreement for an NFT.
   *
   * @param nftContractAddress   : The address of the contract that minted the NFT.
   * @param tokenId              : The ID of the NFT within the contract.
   * @param price                : The price at which someone could buy this NFT. Needs to be greater than 0.
   * @param startTime            : The timestamp indicating when this NFT can be sold. If set to 0, then the sale starts immediately.
   * @param isPrimarySale        : Flag indicating if this is a primary sale. Royalty distribution is affected depending on this.
   *
   * @dev There should be no incentive for users to pass the wrong `isPrimarySale` value.
   */
  function createBuyNowSellingAgreement(
    address nftContractAddress,
    uint256 tokenId,
    uint256 price,
    uint256 startTime,
    bool isPrimarySale
  ) external;

  /**
   * @notice Allows a buyer to accept a buy now sale agreement for an NFT.
   *
   * @param nftContractAddress   : The address of the contract that minted the NFT.
   * @param tokenId              : The ID of the NFT within the contract.
   */
  function acceptBuyNowSellingAgreement(
    address nftContractAddress,
    uint256 tokenId
  ) external payable;

  /**
   * @notice Allows a seller to cancel a buy now sale agreement for an NFT which is already on sale.
   *
   * @param nftContractAddress   : The address of the contract that minted the NFT.
   * @param tokenId              : The ID of the NFT within the contract.
   */
  function cancelBuyNowSellingAgreement(
    address nftContractAddress,
    uint256 tokenId
  ) external;

  /**
   * @notice Allows a user to edit the price for a buy now selling agreement.
   *
   * @param nftContractAddress : The address of the contract that minted the NFT.
   * @param tokenId            : The ID of the NFT within the contract.
   * @param newPrice           : The new set price for the NFT. Needs to be greater than 0.
   */
  function editBuyNowSellingAgreement(
    address nftContractAddress,
    uint256 tokenId,
    uint256 newPrice
  ) external;

  /**
   * @notice Returns the buy now sale details for an NFT if one is available.
   *
   * @dev If no price is found, seller will be address(0) and price will be max uint256.
   *
   * @param nftContract The address of the NFT contract.
   * @param tokenId The id of the NFT.
   *
   * @return id Unique identification of the sale.
   * @return seller The address of the owner that listed a buy price for this NFT.
   *         Returns `address(0)` if there is no buy price set for this NFT.
   * @return price The price of the NFT.
   *         Returns 0 if there is no buy price set for this NFT (since a price of 0 is supported).
   * @return startTime The start time of this buy now sale.
   *         Returns 0 if sale is not scheduled
   * @return isPrimarySale Flag to determine if this is a primary sale.
   *         Returns flase if sale does not exist
   */
  function getBuyNowSellingAgreementDetails(
    address nftContract,
    uint256 tokenId
  )
    external
    view
    returns (
      uint256 id,
      address seller,
      uint256 price,
      uint256 startTime,
      bool isPrimarySale
    );
}
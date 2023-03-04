// SPDX-License-Identifier: MIT OR Apache-2.0

pragma solidity ^0.8.12;

import "../../libraries/AddressLibrary.sol";
import "../shared/TxDeadline.sol";

import "./apis/NFTCollectionFactoryRouterAPIs.sol";
import "./apis/NFTDropMarketRouterAPIs.sol";

/// @notice Parameters used to create a timed edition collection.
struct TimedEditionCollectionCreationParams {
  /// @notice The collection's `name`.
  string name;
  /// @notice The collection's `symbol`.
  string symbol;
  /// @notice The token URI for the collection.
  string tokenURI;
  /// @notice The nonce used by the creator to create this collection.
  uint96 nonce;
}

/// @notice Parameters used to create a fixed price sale.
struct FixedPriceSaleParams {
  /// @notice The exhibition to associate this fix priced sale to.
  /// Set this to 0 to exist outside of an exhibition.
  uint256 exhibitionId;
  /// @notice The fixed price per NFT in the collection.
  uint256 price;
  /// @notice The max number of NFTs an account may mint in this sale.
  uint256 limitPerAccount;
  /// @notice The start time of the general availability period, in seconds since the Unix epoch.
  /// @dev When set to 0, general availability is set to the block timestamp the transaction is mined.
  uint256 generalAvailabilityStartTime;
}

/**
 * @title Offers value-added functions for creating edition collections using the NFTCollectionFactory contract
 * and creating sales using the NFTDropMarket contract.
 * An example of a value-added function is the ability to create a collection and sale in a single transaction.
 * @author reggieag & HardlyDifficult
 */
abstract contract NFTCreateAndListTimedEditionCollection is
  TxDeadline,
  NFTCollectionFactoryRouterAPIs,
  NFTDropMarketRouterAPIs
{
  /**
   * @notice How long the minting period is open, after the general availability start time.
   */
  uint256 private constant MINT_END_TIME_DURATION = 1 days;

  /**
   * @notice Create a new edition collection contract and timed sale.
   * The sale will last for 24 hours starting at `fixedPriceSaleParams.generalAvailabilityStartTime`.
   * @param collectionParams The parameters for the edition collection creation.
   * @param fixedPriceSaleParams  The parameters for the sale creation.
   * @param txDeadlineTime The deadline timestamp for the transaction to be mined, in seconds since Unix epoch.
   * @return collection The address of the newly created collection contract.
   * @dev The collection will include the `nftDropMarket` as an approved minter.
   */
  function createTimedEditionCollectionAndFixedPriceSale(
    TimedEditionCollectionCreationParams calldata collectionParams,
    FixedPriceSaleParams calldata fixedPriceSaleParams,
    uint256 txDeadlineTime
  ) external txDeadlineNotExpired(txDeadlineTime) returns (address collection) {
    uint256 generalAvailabilityStartTime = fixedPriceSaleParams.generalAvailabilityStartTime;
    if (generalAvailabilityStartTime == 0) {
      generalAvailabilityStartTime = block.timestamp;
    }
    collection = _createNFTTimedEditionCollection({
      name: collectionParams.name,
      symbol: collectionParams.symbol,
      tokenURI: collectionParams.tokenURI,
      mintEndTime: generalAvailabilityStartTime + MINT_END_TIME_DURATION,
      approvedMinter: nftDropMarket,
      nonce: collectionParams.nonce
    });
    _createFixedPriceSaleV3({
      nftContract: collection,
      exhibitionId: fixedPriceSaleParams.exhibitionId,
      price: fixedPriceSaleParams.price,
      limitPerAccount: fixedPriceSaleParams.limitPerAccount,
      generalAvailabilityStartTime: generalAvailabilityStartTime,
      // The deadline provided has already been validated above.
      txDeadlineTime: 0
    });
  }

  /**
   * @notice Create a new edition collection contract and timed sale with a payment factory.
   * The sale will last for 24 hours starting at `fixedPriceSaleParams.generalAvailabilityStartTime`.
   * @param collectionParams The parameters for the edition collection creation.
   * @param paymentAddressFactoryCall The contract call which will return the address to use for payments.
   * @param fixedPriceSaleParams  The parameters for the sale creation.
   * @param txDeadlineTime The deadline timestamp for the transaction to be mined, in seconds since Unix epoch.
   * @return collection The address of the newly created collection contract.
   * @dev The collection will include the `nftDropMarket` as an approved minter.
   */
  function createTimedEditionCollectionAndFixedPriceSaleWithPaymentFactory(
    TimedEditionCollectionCreationParams calldata collectionParams,
    CallWithoutValue calldata paymentAddressFactoryCall,
    FixedPriceSaleParams calldata fixedPriceSaleParams,
    uint256 txDeadlineTime
  ) external txDeadlineNotExpired(txDeadlineTime) returns (address collection) {
    uint256 generalAvailabilityStartTime = fixedPriceSaleParams.generalAvailabilityStartTime;
    if (generalAvailabilityStartTime == 0) {
      generalAvailabilityStartTime = block.timestamp;
    }
    collection = _createNFTTimedEditionCollectionWithPaymentFactory({
      name: collectionParams.name,
      symbol: collectionParams.symbol,
      tokenURI: collectionParams.tokenURI,
      mintEndTime: generalAvailabilityStartTime + MINT_END_TIME_DURATION,
      approvedMinter: nftDropMarket,
      nonce: collectionParams.nonce,
      paymentAddressFactoryCall: paymentAddressFactoryCall
    });
    _createFixedPriceSaleV3({
      nftContract: collection,
      exhibitionId: fixedPriceSaleParams.exhibitionId,
      price: fixedPriceSaleParams.price,
      limitPerAccount: fixedPriceSaleParams.limitPerAccount,
      generalAvailabilityStartTime: generalAvailabilityStartTime,
      // The deadline provided has already been validated above.
      txDeadlineTime: 0
    });
  }
}
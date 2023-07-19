// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.8.4;

import {DataTypes} from "../libraries/types/DataTypes.sol";
import {CountersUpgradeable} from "@openzeppelin/contracts-upgradeable/utils/CountersUpgradeable.sol";

interface IDebtMarket {
  /*//////////////////////////////////////////////////////////////
                          EVENTS
  //////////////////////////////////////////////////////////////*/
  /**
   * @dev Emitted on initialization to share location of dependent notes
   * @param pool The address of the associated lend pool
   */
  event Initialized(address indexed pool);

  /**
   * @dev Emitted when a debt listing  is created with a fixed price
   * @param debtId The debt listing identifier
   * @param debtor The owner of the debt listing
   * @param nftAsset The address of the underlying NFT used as collateral
   * @param tokenId The token id of the underlying NFT used as collateral
   * @param sellType The type of sell ( Fixed price or Auction )
   * @param state The state of the actual debt offer ( New,Active,Sold,Canceled )
   * @param sellPrice The price for to sell the debt
   * @param reserveAsset The asset from the reserve
   * @param debtAmount The total debt value
   */
  event DebtListingCreated(
    uint256 debtId,
    address debtor,
    address indexed nftAsset,
    uint256 indexed tokenId,
    DataTypes.DebtMarketType indexed sellType,
    DataTypes.DebtMarketState state,
    uint256 sellPrice,
    address reserveAsset,
    uint256 debtAmount,
    uint256 auctionEndTimestamp,
    uint256 startBiddingPrice
  );

  /**
   * @dev Emitted when a debt with auction listing  is created
   * @param debtId The debt listing identifier
   * @param debtor The owner of the debt listing
   * @param nftAsset The address of the underlying NFT used as collateral
   * @param tokenId The token id of the underlying NFT used as collateral
   * @param sellType The type of sell ( Fixed price or Auction )
   * @param state The state of the actual debt offer ( New,Active,Sold,Canceled )
   * @param sellPrice The price for to sell the debt
   * @param reserveAsset The asset from the reserve
   * @param debtAmount The total debt value
   */
  event DebtAuctionCreated(
    uint256 debtId,
    address debtor,
    address indexed nftAsset,
    uint256 indexed tokenId,
    DataTypes.DebtMarketType indexed sellType,
    DataTypes.DebtMarketState state,
    uint256 sellPrice,
    address reserveAsset,
    uint256 debtAmount
  );

  /**
   * @dev Emitted when a debt listing  is canceled
   * @param onBehalfOf Address of the user who will receive
   * @param debtId The debt listing identifier
   * @param marketListing The object of the debt
   * @param totalByCollection Total debts listings by collection from the actual debtId collection
   * @param totalByUserAndCollection Total debts listings by user from the actual debtId user
   */
  event DebtListingCanceled(
    address indexed onBehalfOf,
    uint256 indexed debtId,
    DataTypes.DebtMarketListing marketListing,
    uint256 totalByCollection,
    uint256 totalByUserAndCollection
  );

  /**
   * @dev Emitted when a bid is placed on a debt listing with auction
   * @param bidderAddress Address of the last bidder
   * @param reserveAsset The asset from the reserve
   * @param nftAsset The address of the underlying NFT used as collateral
   * @param tokenId The token id of the underlying NFT used as collateral
   * @param debtId The debt listing identifier
   * @param bidPrice Amount that bidder spend on the bid
   */
  event BidPlaced(
    address bidderAddress,
    address reserveAsset,
    address indexed nftAsset,
    uint256 indexed tokenId,
    uint256 debtId,
    uint256 bidPrice
  );

  /**
   * @dev Emitted when a debt is bought
   * @param from Address of owner of the debt
   * @param to Buyer address
   * @param debtId The debt listing identifier
   */
  event DebtSold(address indexed from, address indexed to, uint256 indexed debtId);

  /**
   * @dev Emitted when a debt is claimed
   * @param from Address of owner of the debt
   * @param to Claimer address
   * @param debtId The debt listing identifier
   */
  event DebtClaimed(address indexed from, address indexed to, uint256 indexed debtId);

  /**
   * @dev Emited when a new address is authorized to cancel debt listings
   * @param authorizedAddress Address to authorize
   */
  event AuthorizedAddressChanged(address indexed authorizedAddress, bool isAuthorized);

  /**
   * @dev Emitted when the pause is triggered.
   */
  event Paused();

  /**
   * @dev Emitted when the pause is lifted.
   */
  event Unpaused();

  /*//////////////////////////////////////////////////////////////
                        MAIN LOGIC
  //////////////////////////////////////////////////////////////*/
  function createDebtListing(
    address nftAsset,
    uint256 tokenId,
    uint256 sellPrice,
    address onBehalfOf,
    uint256 startBiddingPrice,
    uint256 auctionEndTimestamp
  ) external;

  function cancelDebtListing(address nftAsset, uint256 tokenId) external;

  function buy(address nftAsset, uint256 tokenId, address onBehalfOf, uint256 amount) external;

  function bid(address nftAsset, uint256 tokenId, uint256 bidPrice, address onBehalfOf) external;

  function claim(address nftAsset, uint256 tokenId, address onBehalfOf) external;

  /*//////////////////////////////////////////////////////////////
                         GETTERS & SETTERS
  //////////////////////////////////////////////////////////////*/
  function getDebtId(address nftAsset, uint256 tokenId) external view returns (uint256);

  function getDebt(uint256 debtId) external view returns (DataTypes.DebtMarketListing memory sellDebt);

  function getDebtIdTracker() external view returns (CountersUpgradeable.Counter memory);

  function setDeltaBidPercent(uint256 value) external;

  function setAuthorizedAddress(address newAuthorizedAddress, bool val) external;

  function paused() external view returns (bool);

  function setPause(bool val) external;
}
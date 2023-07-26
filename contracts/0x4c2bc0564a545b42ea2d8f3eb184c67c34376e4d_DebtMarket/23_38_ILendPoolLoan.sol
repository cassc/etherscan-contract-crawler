// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.8.4;

import {DataTypes} from "../libraries/types/DataTypes.sol";
import {CountersUpgradeable} from "@openzeppelin/contracts-upgradeable/utils/CountersUpgradeable.sol";

interface ILendPoolLoan {
  /**
   * @dev Emitted on initialization to share location of dependent notes
   * @param pool The address of the associated lend pool
   */
  event Initialized(address indexed pool);

  /**
   * @dev Emitted when a loan is created
   * @param user The address initiating the action
   */
  event LoanCreated(
    address indexed user,
    address indexed onBehalfOf,
    uint256 indexed loanId,
    address nftAsset,
    uint256 nftTokenId,
    address reserveAsset,
    uint256 amount,
    uint256 borrowIndex
  );

  /**
   * @dev Emitted when a loan is updated
   * @param user The address initiating the action
   */
  event LoanUpdated(
    address indexed user,
    uint256 indexed loanId,
    address nftAsset,
    uint256 nftTokenId,
    address reserveAsset,
    uint256 amountAdded,
    uint256 amountTaken,
    uint256 borrowIndex
  );

  /**
   * @dev Emitted when a loan is repaid by the borrower
   * @param user The address initiating the action
   */
  event LoanRepaid(
    address indexed user,
    uint256 indexed loanId,
    address nftAsset,
    uint256 nftTokenId,
    address reserveAsset,
    uint256 amount,
    uint256 borrowIndex
  );

  /**
   * @dev Emitted when a loan is auction by the liquidator
   * @param user The address initiating the action
   */
  event LoanAuctioned(
    address indexed user,
    uint256 indexed loanId,
    address nftAsset,
    uint256 nftTokenId,
    uint256 amount,
    uint256 borrowIndex,
    address bidder,
    uint256 price,
    address previousBidder,
    uint256 previousPrice
  );

  /**
   * @dev Emitted when a loan is bought out
   * @param loanId The loanId that was bought out
   */
  event LoanBoughtOut(
    address indexed user,
    uint256 indexed loanId,
    address nftAsset,
    uint256 nftTokenId,
    uint256 bidBorrowAmount,
    uint256 borrowIndex,
    uint256 buyoutAmount
  );

  /**
   * @dev Emitted when a loan is redeemed
   * @param user The address initiating the action
   */
  event LoanRedeemed(
    address indexed user,
    uint256 indexed loanId,
    address nftAsset,
    uint256 nftTokenId,
    address reserveAsset,
    uint256 amountTaken,
    uint256 borrowIndex
  );

  /**
   * @dev Emitted when a loan is liquidate by the liquidator
   * @param user The address initiating the action
   */
  event LoanLiquidated(
    address indexed user,
    uint256 indexed loanId,
    address nftAsset,
    uint256 nftTokenId,
    address reserveAsset,
    uint256 amount,
    uint256 borrowIndex
  );

  /**
   * @dev Emitted when a loan is liquidated in an external market
   */
  event LoanLiquidatedMarket(
    uint256 indexed loanId,
    address nftAsset,
    uint256 nftTokenId,
    address reserveAsset,
    uint256 amount,
    uint256 borrowIndex
  );

  function initNft(address nftAsset, address uNftAddress) external;

  /**
   * @dev Create store a loan object with some params
   * @param initiator The address of the user initiating the borrow
   * @param onBehalfOf The address receiving the loan
   * @param nftAsset The address of the underlying NFT asset
   * @param nftTokenId The token Id of the underlying NFT asset
   * @param uNftAddress The address of the uNFT token
   * @param reserveAsset The address of the underlying reserve asset
   * @param amount The loan amount
   * @param borrowIndex The index to get the scaled loan amount
   */
  function createLoan(
    address initiator,
    address onBehalfOf,
    address nftAsset,
    uint256 nftTokenId,
    address uNftAddress,
    address reserveAsset,
    uint256 amount,
    uint256 borrowIndex
  ) external returns (uint256);

  /**
   * @dev Update the given loan with some params
   *
   * Requirements:
   *  - The caller must be a holder of the loan
   *  - The loan must be in state Active
   * @param initiator The address of the user updating the loan
   * @param loanId The loan ID
   * @param amountAdded The amount added to the loan
   * @param amountTaken The amount taken from the loan
   * @param borrowIndex The index to get the scaled loan amount
   */
  function updateLoan(
    address initiator,
    uint256 loanId,
    uint256 amountAdded,
    uint256 amountTaken,
    uint256 borrowIndex
  ) external;

  /**
   * @dev Repay the given loan
   *
   * Requirements:
   *  - The caller must be a holder of the loan
   *  - The caller must send in principal + interest
   *  - The loan must be in state Active
   *
   * @param initiator The address of the user initiating the repay
   * @param loanId The loan getting burned
   * @param uNftAddress The address of uNFT
   * @param amount The amount repaid
   * @param borrowIndex The index to get the scaled loan amount
   */
  function repayLoan(
    address initiator,
    uint256 loanId,
    address uNftAddress,
    uint256 amount,
    uint256 borrowIndex
  ) external;

  /**
   * @dev Auction the given loan
   *
   * Requirements:
   *  - The price must be greater than current highest price
   *  - The loan must be in state Active or Auction
   *
   * @param initiator The address of the user initiating the auction
   * @param loanId The loan getting auctioned
   * @param bidPrice The bid price of this auction
   */
  function auctionLoan(
    address initiator,
    uint256 loanId,
    address onBehalfOf,
    uint256 bidPrice,
    uint256 borrowAmount,
    uint256 borrowIndex
  ) external;

  /**
   * @dev Buyout the given loan
   *
   * Requirements:
   *  - The price has to be the valuation price of the nft
   *  - The loan must be in state Active or Auction
   */
  function buyoutLoan(
    address initiator,
    uint256 loanId,
    address uNftAddress,
    uint256 borrowAmount,
    uint256 borrowIndex,
    uint256 buyoutAmount
  ) external;

  /**
   * @dev Redeem the given loan with some params
   *
   * Requirements:
   *  - The caller must be a holder of the loan
   *  - The loan must be in state Auction
   * @param initiator The address of the user initiating the borrow
   * @param loanId The loan getting redeemed
   * @param amountTaken The taken amount
   * @param borrowIndex The index to get the scaled loan amount
   */
  function redeemLoan(address initiator, uint256 loanId, uint256 amountTaken, uint256 borrowIndex) external;

  /**
   * @dev Liquidate the given loan
   *
   * Requirements:
   *  - The caller must send in principal + interest
   *  - The loan must be in state Active
   *
   * @param initiator The address of the user initiating the auction
   * @param loanId The loan getting burned
   * @param uNftAddress The address of uNFT
   * @param borrowAmount The borrow amount
   * @param borrowIndex The index to get the scaled loan amount
   */
  function liquidateLoan(
    address initiator,
    uint256 loanId,
    address uNftAddress,
    uint256 borrowAmount,
    uint256 borrowIndex
  ) external;

  /**
   * @dev Liquidate the given loan on an external market
   * @param loanId The loan getting burned
   * @param uNftAddress The address of the underlying uNft
   * @param borrowAmount Amount borrowed in the loan
   * @param borrowIndex The reserve index
   */
  function liquidateLoanMarket(uint256 loanId, address uNftAddress, uint256 borrowAmount, uint256 borrowIndex) external;

  /**
   * @dev Updates the `_marketAdapters` mapping, setting the params to
   * valid/unvalid adapters through the `flag` parameter
   * @param adapters The adapters addresses to be updated
   * @param flag `true` to set addresses as valid adapters, `false` otherwise
   */
  function updateMarketAdapters(address[] calldata adapters, bool flag) external;

  /**
   *  @dev returns the borrower of a specific loan
   * param loanId the loan to get the borrower from
   */
  function borrowerOf(uint256 loanId) external view returns (address);

  /**
   *  @dev returns the loan corresponding to a specific NFT
   * param nftAsset the underlying NFT asset
   * param tokenId the underlying token ID for the NFT
   */
  function getCollateralLoanId(address nftAsset, uint256 nftTokenId) external view returns (uint256);

  /**
   *  @dev returns the loan corresponding to a specific loan Id
   * param loanId the loan Id
   */
  function getLoan(uint256 loanId) external view returns (DataTypes.LoanData memory loanData);

  /**
   *  @dev returns the collateral and reserve corresponding to a specific loan
   * param loanId the loan Id
   */
  function getLoanCollateralAndReserve(
    uint256 loanId
  ) external view returns (address nftAsset, uint256 nftTokenId, address reserveAsset, uint256 scaledAmount);

  /**
   *  @dev returns the reserve and borrow __scaled__ amount corresponding to a specific loan
   * param loanId the loan Id
   */
  function getLoanReserveBorrowScaledAmount(uint256 loanId) external view returns (address, uint256);

  /**
   *  @dev returns the reserve and borrow  amount corresponding to a specific loan
   * param loanId the loan Id
   */
  function getLoanReserveBorrowAmount(uint256 loanId) external view returns (address, uint256);

  function getLoanHighestBid(uint256 loanId) external view returns (address, uint256);

  /**
   *  @dev returns the collateral amount for a given NFT
   * param nftAsset the underlying NFT asset
   */
  function getNftCollateralAmount(address nftAsset) external view returns (uint256);

  /**
   *  @dev returns the collateral amount for a given NFT and a specific user
   * param user the user
   * param nftAsset the underlying NFT asset
   */
  function getUserNftCollateralAmount(address user, address nftAsset) external view returns (uint256);

  /**
   *  @dev returns the counter tracker for all the loan ID's in the protocol
   */
  function getLoanIdTracker() external view returns (CountersUpgradeable.Counter memory);

  function reMintUNFT(address nftAsset, uint256 tokenId, address oldOnBehalfOf, address newOnBehalfOf) external;
}
// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.8.4;

import {ILendPoolAddressesProvider} from "./ILendPoolAddressesProvider.sol";
import {IIncentivesController} from "./IIncentivesController.sol";

interface IUiPoolDataProvider {
  struct AggregatedReserveData {
    address underlyingAsset;
    string name;
    string symbol;
    uint256 decimals;
    uint256 reserveFactor;
    bool borrowingEnabled;
    bool isActive;
    bool isFrozen;
    // base data
    uint128 liquidityIndex;
    uint128 variableBorrowIndex;
    uint128 liquidityRate;
    uint128 variableBorrowRate;
    uint40 lastUpdateTimestamp;
    address uTokenAddress;
    address debtTokenAddress;
    address interestRateAddress;
    //
    uint256 availableLiquidity;
    uint256 totalVariableDebt;
    uint256 priceInEth;
    uint256 variableRateSlope1;
    uint256 variableRateSlope2;
  }

  struct UserReserveData {
    address underlyingAsset;
    uint256 uTokenBalance;
    uint256 variableDebt;
  }

  struct AggregatedNftData {
    address underlyingAsset;
    string name;
    string symbol;
    bool isActive;
    bool isFrozen;
    address uNftAddress;
    uint256 totalCollateral;
  }

  struct AggregatedNftConfiguration {
    address underlyingAsset;
    uint256 tokenId;
    uint256 ltv;
    uint256 liquidationThreshold;
    uint256 liquidationBonus;
    uint256 redeemDuration;
    uint256 auctionDuration;
    uint256 redeemFine;
    uint256 redeemThreshold;
    uint256 minBidFine;
    bool isActive;
    bool isFrozen;
    uint256 priceInEth;
  }

  struct UserNftData {
    address underlyingAsset;
    address uNftAddress;
    uint256 totalCollateral;
  }

  struct AggregatedLoanData {
    uint256 loanId;
    uint256 state;
    address reserveAsset;
    uint256 totalCollateralInReserve;
    uint256 totalDebtInReserve;
    uint256 availableBorrowsInReserve;
    uint256 healthFactor;
    uint256 liquidatePrice;
    address bidderAddress;
    uint256 bidPrice;
    uint256 bidBorrowAmount;
    uint256 bidFine;
  }

  /**
   * @dev Gets the list of reserves from the protocol
   * @param provider the addresses provider
   **/
  function getReservesList(ILendPoolAddressesProvider provider) external view returns (address[] memory);

  /**
   * @dev Gets aggregated data from the reserves
   * @param provider the addresses provider
   **/
  function getSimpleReservesData(ILendPoolAddressesProvider provider)
    external
    view
    returns (AggregatedReserveData[] memory);

  /**
   * @dev Gets reserve data for a specific user
   * @param provider the addresses provider
   * @param user the user to fetch the data
   **/
  function getUserReservesData(ILendPoolAddressesProvider provider, address user)
    external
    view
    returns (UserReserveData[] memory);

  /**
   * @dev Gets full (aggregated and user) data from the reserves
   * @param provider the addresses provider
   * @param user the user to fetch the data
   **/
  function getReservesData(ILendPoolAddressesProvider provider, address user)
    external
    view
    returns (AggregatedReserveData[] memory, UserReserveData[] memory);

  /**
   * @dev Gets the list of NFTs in the protocol
   * @param provider the addresses provider
   **/
  function getNftsList(ILendPoolAddressesProvider provider) external view returns (address[] memory);

  /**
   * @dev Gets aggregated data from the NFTs
   * @param provider the addresses provider
   **/
  function getSimpleNftsData(ILendPoolAddressesProvider provider) external view returns (AggregatedNftData[] memory);

  /**
   * @dev Gets NFTs data for a specific user
   * @param provider the addresses provider
   * @param user the user to fetch the data
   **/
  function getUserNftsData(ILendPoolAddressesProvider provider, address user)
    external
    view
    returns (UserNftData[] memory);

  /**
   * @dev Gets full (aggregated and user) data from the NFTs
   * @param provider the addresses provider
   * @param user the user to fetch the data
   **/
  function getNftsData(ILendPoolAddressesProvider provider, address user)
    external
    view
    returns (AggregatedNftData[] memory, UserNftData[] memory);

  /**
   * @dev Gets aggregated configuration of NFT assets
   * @param provider the addresses provider
   * @param nftAssets the array of NFT assets to check the loans from
   * @param nftTokenIds the array of token Ids
   **/
  function getSimpleNftsConfiguration(
    ILendPoolAddressesProvider provider,
    address[] memory nftAssets,
    uint256[] memory nftTokenIds
  ) external view returns (AggregatedNftConfiguration[] memory);

  /**
   * @dev Gets loans aggregated data
   * @param nftAssets the array of NFT assets to check the loans from
   * @param nftTokenIds the array of token Ids
   **/
  function getSimpleLoansData(
    ILendPoolAddressesProvider provider,
    address[] memory nftAssets,
    uint256[] memory nftTokenIds
  ) external view returns (AggregatedLoanData[] memory);
}
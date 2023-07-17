// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.8.4;

import {IERC20Detailed} from "../interfaces/IERC20Detailed.sol";
import {IERC721Detailed} from "../interfaces/IERC721Detailed.sol";
import {ILendPoolAddressesProvider} from "../interfaces/ILendPoolAddressesProvider.sol";
import {IUiPoolDataProvider} from "../interfaces/IUiPoolDataProvider.sol";
import {ILendPool} from "../interfaces/ILendPool.sol";
import {ILendPoolLoan} from "../interfaces/ILendPoolLoan.sol";
import {IReserveOracleGetter} from "../interfaces/IReserveOracleGetter.sol";
import {INFTOracleGetter} from "../interfaces/INFTOracleGetter.sol";
import {IUToken} from "../interfaces/IUToken.sol";
import {IDebtToken} from "../interfaces/IDebtToken.sol";
import {WadRayMath} from "../libraries/math/WadRayMath.sol";
import {ReserveConfiguration} from "../libraries/configuration/ReserveConfiguration.sol";
import {NftConfiguration} from "../libraries/configuration/NftConfiguration.sol";
import {DataTypes} from "../libraries/types/DataTypes.sol";
import {InterestRate} from "../protocol/InterestRate.sol";
import {Errors} from "../libraries/helpers/Errors.sol";

contract UiPoolDataProvider is IUiPoolDataProvider {
  using WadRayMath for uint256;
  using ReserveConfiguration for DataTypes.ReserveConfigurationMap;
  using NftConfiguration for DataTypes.NftConfigurationMap;

  IReserveOracleGetter public immutable reserveOracle;
  INFTOracleGetter public immutable nftOracle;

  constructor(IReserveOracleGetter _reserveOracle, INFTOracleGetter _nftOracle) {
    reserveOracle = _reserveOracle;
    nftOracle = _nftOracle;
  }

  /**
   * @dev Gets the strategy slopes for a specified interest rate
   * @param interestRate the interest rate to get the strategy slope from
   **/
  function getInterestRateStrategySlopes(InterestRate interestRate) internal view returns (uint256, uint256) {
    return (interestRate.variableRateSlope1(), interestRate.variableRateSlope2());
  }

  /**
   * @inheritdoc IUiPoolDataProvider
   */
  function getReservesList(ILendPoolAddressesProvider provider) public view override returns (address[] memory) {
    ILendPool lendPool = ILendPool(provider.getLendPool());
    return lendPool.getReservesList();
  }

  /**
   * @inheritdoc IUiPoolDataProvider
   */
  function getSimpleReservesData(
    ILendPoolAddressesProvider provider
  ) public view override returns (AggregatedReserveData[] memory) {
    ILendPool lendPool = ILendPool(provider.getLendPool());
    address[] memory reserves = lendPool.getReservesList();
    uint256 reservesLength = reserves.length;
    AggregatedReserveData[] memory reservesData = new AggregatedReserveData[](reservesLength);

    for (uint256 i; i < reservesLength; ) {
      AggregatedReserveData memory reserveData = reservesData[i];

      DataTypes.ReserveData memory baseData = lendPool.getReserveData(reserves[i]);

      _fillReserveData(reserveData, reserves[i], baseData);

      unchecked {
        ++i;
      }
    }

    return (reservesData);
  }

  /**
   * @inheritdoc IUiPoolDataProvider
   */
  function getUserReservesData(
    ILendPoolAddressesProvider provider,
    address user
  ) external view override returns (UserReserveData[] memory) {
    ILendPool lendPool = ILendPool(provider.getLendPool());
    address[] memory reserves = lendPool.getReservesList();

    uint256 reservesLength = reserves.length;
    UserReserveData[] memory userReservesData = new UserReserveData[](user != address(0) ? reservesLength : 0);

    for (uint256 i; i < reservesLength; ) {
      DataTypes.ReserveData memory baseData = lendPool.getReserveData(reserves[i]);

      _fillUserReserveData(userReservesData[i], user, reserves[i], baseData);

      unchecked {
        i = i + 1;
      }
    }

    return (userReservesData);
  }

  /**
   * @inheritdoc IUiPoolDataProvider
   */
  function getReservesData(
    ILendPoolAddressesProvider provider,
    address user
  ) external view override returns (AggregatedReserveData[] memory, UserReserveData[] memory) {
    ILendPool lendPool = ILendPool(provider.getLendPool());
    address[] memory reserves = lendPool.getReservesList();
    uint256 reservesLength = reserves.length;
    AggregatedReserveData[] memory reservesData = new AggregatedReserveData[](reservesLength);
    UserReserveData[] memory userReservesData = new UserReserveData[](user != address(0) ? reservesLength : 0);

    for (uint256 i; i < reservesLength; ) {
      AggregatedReserveData memory reserveData = reservesData[i];

      DataTypes.ReserveData memory baseData = lendPool.getReserveData(reserves[i]);
      _fillReserveData(reserveData, reserves[i], baseData);

      if (user != address(0)) {
        _fillUserReserveData(userReservesData[i], user, reserves[i], baseData);
      }

      unchecked {
        i = i + 1;
      }
    }

    return (reservesData, userReservesData);
  }

  /**
   * @dev fills the specified reserve data
   * @param reserveData the reserve data to be updated
   * @param reserveAsset the asset from the reserve
   * @param baseData the base data
   **/
  function _fillReserveData(
    AggregatedReserveData memory reserveData,
    address reserveAsset,
    DataTypes.ReserveData memory baseData
  ) internal view {
    reserveData.underlyingAsset = reserveAsset;

    // reserve current state
    reserveData.liquidityIndex = baseData.liquidityIndex;
    reserveData.variableBorrowIndex = baseData.variableBorrowIndex;
    reserveData.liquidityRate = baseData.currentLiquidityRate;
    reserveData.variableBorrowRate = baseData.currentVariableBorrowRate;
    reserveData.lastUpdateTimestamp = baseData.lastUpdateTimestamp;
    reserveData.uTokenAddress = baseData.uTokenAddress;
    reserveData.debtTokenAddress = baseData.debtTokenAddress;
    reserveData.interestRateAddress = baseData.interestRateAddress;
    reserveData.priceInEth = reserveOracle.getAssetPrice(reserveData.underlyingAsset);

    reserveData.availableLiquidity = IUToken(reserveData.uTokenAddress).getAvailableLiquidity();
    reserveData.totalVariableDebt = IDebtToken(reserveData.debtTokenAddress).totalSupply();

    // reserve configuration
    reserveData.symbol = IERC20Detailed(reserveData.underlyingAsset).symbol();
    reserveData.name = IERC20Detailed(reserveData.underlyingAsset).name();

    (, , , reserveData.decimals, reserveData.reserveFactor) = baseData.configuration.getParamsMemory();
    (reserveData.isActive, reserveData.isFrozen, reserveData.borrowingEnabled, ) = baseData
      .configuration
      .getFlagsMemory();
    (reserveData.variableRateSlope1, reserveData.variableRateSlope2) = getInterestRateStrategySlopes(
      InterestRate(reserveData.interestRateAddress)
    );
  }

  /**
   * @dev fills the specified user reserve data
   * @param userReserveData the reserve data to be updated
   * @param user the user related to the reserve
   * @param reserveAsset the asset from the reserve
   * @param baseData the base data
   **/
  function _fillUserReserveData(
    UserReserveData memory userReserveData,
    address user,
    address reserveAsset,
    DataTypes.ReserveData memory baseData
  ) internal view {
    // user reserve data
    userReserveData.underlyingAsset = reserveAsset;
    userReserveData.uTokenBalance = IUToken(baseData.uTokenAddress).balanceOf(user);
    userReserveData.variableDebt = IDebtToken(baseData.debtTokenAddress).balanceOf(user);
  }

  /**
   * @inheritdoc IUiPoolDataProvider
   */
  function getNftsList(ILendPoolAddressesProvider provider) external view override returns (address[] memory) {
    ILendPool lendPool = ILendPool(provider.getLendPool());
    return lendPool.getNftsList();
  }

  /**
   * @inheritdoc IUiPoolDataProvider
   */
  function getSimpleNftsData(
    ILendPoolAddressesProvider provider
  ) external view override returns (AggregatedNftData[] memory) {
    ILendPool lendPool = ILendPool(provider.getLendPool());
    ILendPoolLoan lendPoolLoan = ILendPoolLoan(provider.getLendPoolLoan());
    address[] memory nfts = lendPool.getNftsList();
    uint256 nftsLength = nfts.length;
    AggregatedNftData[] memory nftsData = new AggregatedNftData[](nftsLength);

    for (uint256 i; i < nftsLength; ) {
      AggregatedNftData memory nftData = nftsData[i];

      DataTypes.NftData memory baseData = lendPool.getNftData(nfts[i]);

      _fillNftData(nftData, nfts[i], baseData, lendPoolLoan);

      unchecked {
        i = i + 1;
      }
    }

    return (nftsData);
  }

  /**
   * @inheritdoc IUiPoolDataProvider
   */
  function getUserNftsData(
    ILendPoolAddressesProvider provider,
    address user
  ) external view override returns (UserNftData[] memory) {
    ILendPool lendPool = ILendPool(provider.getLendPool());
    ILendPoolLoan lendPoolLoan = ILendPoolLoan(provider.getLendPoolLoan());
    address[] memory nfts = lendPool.getNftsList();

    uint256 nftsLength = nfts.length;
    UserNftData[] memory userNftsData = new UserNftData[](user != address(0) ? nftsLength : 0);

    for (uint256 i; i < nftsLength; ) {
      UserNftData memory userNftData = userNftsData[i];

      DataTypes.NftData memory baseData = lendPool.getNftData(nfts[i]);

      _fillUserNftData(userNftData, user, nfts[i], baseData, lendPoolLoan);

      unchecked {
        i = i + 1;
      }
    }

    return (userNftsData);
  }

  /**
   * @inheritdoc IUiPoolDataProvider
   */
  function getNftsData(
    ILendPoolAddressesProvider provider,
    address user
  ) external view override returns (AggregatedNftData[] memory, UserNftData[] memory) {
    ILendPool lendPool = ILendPool(provider.getLendPool());
    ILendPoolLoan lendPoolLoan = ILendPoolLoan(provider.getLendPoolLoan());
    address[] memory nfts = lendPool.getNftsList();
    uint256 nftsLength = nfts.length;
    AggregatedNftData[] memory nftsData = new AggregatedNftData[](nftsLength);
    UserNftData[] memory userNftsData = new UserNftData[](user != address(0) ? nftsLength : 0);

    for (uint256 i; i < nftsLength; ) {
      AggregatedNftData memory nftData = nftsData[i];
      UserNftData memory userNftData = userNftsData[i];

      DataTypes.NftData memory baseData = lendPool.getNftData(nfts[i]);

      _fillNftData(nftData, nfts[i], baseData, lendPoolLoan);
      if (user != address(0)) {
        _fillUserNftData(userNftData, user, nfts[i], baseData, lendPoolLoan);
      }

      unchecked {
        i = i + 1;
      }
    }

    return (nftsData, userNftsData);
  }

  /**
   * @dev fills the specified  NFT data
   * @param nftData the NFT data to be updated
   * @param nftAsset the NFT to be updated
   * @param baseData the base data
   * @param lendPoolLoan the LendPoolLoan contract address
   **/
  function _fillNftData(
    AggregatedNftData memory nftData,
    address nftAsset,
    DataTypes.NftData memory baseData,
    ILendPoolLoan lendPoolLoan
  ) internal view {
    nftData.underlyingAsset = nftAsset;

    // nft current state
    nftData.uNftAddress = baseData.uNftAddress;

    nftData.totalCollateral = lendPoolLoan.getNftCollateralAmount(nftAsset);

    // nft configuration
    nftData.symbol = IERC721Detailed(nftData.underlyingAsset).symbol();
    nftData.name = IERC721Detailed(nftData.underlyingAsset).name();

    (nftData.isActive, nftData.isFrozen) = baseData.configuration.getFlagsMemory();
  }

  /**
   * @dev fills the specified user data for a specific user and NFT
   * @param userNftData the NFT data to be updated
   * @param user the NFT to be updated
   * @param nftAsset the NFT to be updated
   * @param baseData the data to fetch the uNFT
   * @param lendPoolLoan the LendPoolLoan contract address
   **/
  function _fillUserNftData(
    UserNftData memory userNftData,
    address user,
    address nftAsset,
    DataTypes.NftData memory baseData,
    ILendPoolLoan lendPoolLoan
  ) internal view {
    userNftData.underlyingAsset = nftAsset;

    // user nft data
    userNftData.uNftAddress = baseData.uNftAddress;

    userNftData.totalCollateral = lendPoolLoan.getUserNftCollateralAmount(user, nftAsset);
  }

  /**
   * @inheritdoc IUiPoolDataProvider
   */
  function getSimpleNftsConfiguration(
    ILendPoolAddressesProvider provider,
    address[] memory nftAssets,
    uint256[] memory nftTokenIds
  ) external view override returns (AggregatedNftConfiguration[] memory) {
    uint256 nftAssetsLength = nftAssets.length;
    require(nftAssetsLength == nftTokenIds.length, Errors.LP_INCONSISTENT_PARAMS);

    ILendPool lendPool = ILendPool(provider.getLendPool());
    AggregatedNftConfiguration[] memory nftConfigs = new AggregatedNftConfiguration[](nftAssetsLength);

    for (uint256 i; i < nftAssetsLength; ) {
      AggregatedNftConfiguration memory nftConfig = nftConfigs[i];

      DataTypes.NftConfigurationMap memory baseConfig = lendPool.getNftConfigByTokenId(nftAssets[i], nftTokenIds[i]);

      _fillNftConfiguration(nftConfig, nftAssets[i], nftTokenIds[i], baseConfig);

      unchecked {
        i = i + 1;
      }
    }

    return nftConfigs;
  }

  /**
   * @dev fills the specified  NFT config
   * @param nftConfig the NFT config to be updated
   * @param nftAsset the NFT to be updated
   * @param tokenId token id to be updated
   * @param baseConfig the base config
   **/
  function _fillNftConfiguration(
    AggregatedNftConfiguration memory nftConfig,
    address nftAsset,
    uint256 tokenId,
    DataTypes.NftConfigurationMap memory baseConfig
  ) internal view {
    nftConfig.underlyingAsset = nftAsset;
    nftConfig.tokenId = tokenId;

    nftConfig.priceInEth = nftOracle.getNFTPrice(nftConfig.underlyingAsset, nftConfig.tokenId);

    (nftConfig.ltv, nftConfig.liquidationThreshold, nftConfig.liquidationBonus) = baseConfig
      .getCollateralParamsMemory();
    (nftConfig.redeemDuration, nftConfig.auctionDuration, nftConfig.redeemFine, nftConfig.redeemThreshold) = baseConfig
      .getAuctionParamsMemory();
    (nftConfig.isActive, nftConfig.isFrozen) = baseConfig.getFlagsMemory();
    nftConfig.minBidFine = baseConfig.getMinBidFineMemory();
  }

  /**
   * @inheritdoc IUiPoolDataProvider
   */
  function getSimpleLoansData(
    ILendPoolAddressesProvider provider,
    address[] memory nftAssets,
    uint256[] memory nftTokenIds
  ) external view override returns (AggregatedLoanData[] memory) {
    uint256 nftsLength = nftAssets.length;

    require(nftsLength == nftTokenIds.length, Errors.LP_INCONSISTENT_PARAMS);

    ILendPool lendPool = ILendPool(provider.getLendPool());
    ILendPoolLoan poolLoan = ILendPoolLoan(provider.getLendPoolLoan());

    AggregatedLoanData[] memory loansData = new AggregatedLoanData[](nftsLength);

    for (uint256 i; i < nftsLength; ) {
      AggregatedLoanData memory loanData = loansData[i];

      // NFT debt data
      (
        loanData.loanId,
        loanData.reserveAsset,
        loanData.totalCollateralInReserve,
        loanData.totalDebtInReserve,
        loanData.availableBorrowsInReserve,
        loanData.healthFactor
      ) = lendPool.getNftDebtData(nftAssets[i], nftTokenIds[i]);

      DataTypes.LoanData memory loan = poolLoan.getLoan(loanData.loanId);
      loanData.state = uint256(loan.state);

      // NFT auction data
      (, loanData.bidderAddress, loanData.bidPrice, loanData.bidBorrowAmount, loanData.bidFine) = lendPool
        .getNftAuctionData(nftAssets[i], nftTokenIds[i]);

      unchecked {
        i = i + 1;
      }
    }

    return loansData;
  }
}
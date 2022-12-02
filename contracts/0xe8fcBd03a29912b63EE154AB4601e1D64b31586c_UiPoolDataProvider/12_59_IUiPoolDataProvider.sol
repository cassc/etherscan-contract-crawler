// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.8.10;

import {IPoolAddressesProvider} from "../../interfaces/IPoolAddressesProvider.sol";
import {DataTypes} from "../../protocol/libraries/types/DataTypes.sol";

interface IUiPoolDataProvider {
    struct InterestRates {
        uint256 variableRateSlope1;
        uint256 variableRateSlope2;
        uint256 baseVariableBorrowRate;
        uint256 optimalUsageRatio;
    }

    struct AggregatedReserveData {
        address underlyingAsset;
        string name;
        string symbol;
        uint256 decimals;
        uint256 baseLTVasCollateral;
        uint256 reserveLiquidationThreshold;
        uint256 reserveLiquidationBonus;
        uint256 reserveFactor;
        bool usageAsCollateralEnabled;
        bool borrowingEnabled;
        bool auctionEnabled;
        bool isActive;
        bool isFrozen;
        bool isPaused;
        bool isAtomicPricing;
        // base data
        uint128 liquidityIndex;
        uint128 variableBorrowIndex;
        uint128 liquidityRate;
        uint128 variableBorrowRate;
        uint40 lastUpdateTimestamp;
        address xTokenAddress;
        address variableDebtTokenAddress;
        address interestRateStrategyAddress;
        address auctionStrategyAddress;
        uint256 availableLiquidity;
        uint256 totalScaledVariableDebt;
        uint256 priceInMarketReferenceCurrency;
        address priceOracle;
        uint256 variableRateSlope1;
        uint256 variableRateSlope2;
        uint256 baseVariableBorrowRate;
        uint256 optimalUsageRatio;
        uint128 accruedToTreasury;
        uint256 borrowCap;
        uint256 supplyCap;
        //AssetType
        DataTypes.AssetType assetType;
    }

    struct UserReserveData {
        address underlyingAsset;
        uint256 currentXTokenBalance;
        uint256 scaledXTokenBalance;
        uint256 collateralizedBalance;
        bool usageAsCollateralEnabledOnUser;
        uint256 scaledVariableDebt;
    }

    struct BaseCurrencyInfo {
        uint256 marketReferenceCurrencyUnit;
        int256 marketReferenceCurrencyPriceInUsd;
        int256 networkBaseTokenPriceInUsd;
        uint8 networkBaseTokenPriceDecimals;
    }

    struct UniswapV3LpTokenInfo {
        address token0;
        address token1;
        uint24 feeRate;
        int24 positionTickLower;
        int24 positionTickUpper;
        int24 currentTick;
        uint128 liquidity;
        uint256 liquidityToken0Amount;
        uint256 liquidityToken1Amount;
        uint256 lpFeeToken0Amount;
        uint256 lpFeeToken1Amount;
        uint256 tokenPrice;
        uint256 baseLTVasCollateral;
        uint256 reserveLiquidationThreshold;
    }

    struct UserGlobalData {
        uint256 totalCollateralBase;
        uint256 totalDebtBase;
        uint256 availableBorrowsBase;
        uint256 currentLiquidationThreshold;
        uint256 ltv;
        uint256 healthFactor;
        uint256 erc721HealthFactor;
        uint256 auctionValidityTime;
    }

    struct TokenInLiquidationData {
        address asset;
        uint256 tokenId;
        bool isCollateralized;
        uint256 tokenPrice;
        bool isAuctioned;
        DataTypes.AuctionData auctionData;
    }

    function getReservesList(IPoolAddressesProvider provider)
        external
        view
        returns (address[] memory);

    function getReservesData(IPoolAddressesProvider provider)
        external
        view
        returns (AggregatedReserveData[] memory, BaseCurrencyInfo memory);

    function getUserReservesData(IPoolAddressesProvider provider, address user)
        external
        view
        returns (UserReserveData[] memory);

    function getNTokenData(
        address[] memory nTokenAddresses,
        uint256[][] memory tokenIds
    ) external view returns (DataTypes.NTokenData[][] memory);

    function getAuctionData(
        IPoolAddressesProvider provider,
        address[] memory nTokenAddresses,
        uint256[][] memory tokenIds
    ) external view returns (DataTypes.AuctionData[][] memory);

    function getUniswapV3LpTokenData(
        IPoolAddressesProvider provider,
        address lpTokenAddress,
        uint256 tokenId
    ) external view returns (UniswapV3LpTokenInfo memory);

    function getUserInLiquidationNFTData(
        IPoolAddressesProvider provider,
        address user,
        address[] memory asset,
        uint256[][] memory tokenIds
    )
        external
        view
        returns (UserGlobalData memory, TokenInLiquidationData[][] memory);
}
// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

import "../interfaces/ISwapAdapter.sol";
import "../interfaces/IPriceOracleGetter.sol";
import "../interfaces/IReinvestment.sol";
import "../interfaces/IBonusPool.sol";
import "../interfaces/IUserData.sol";

/// @dev This help resolves cyclic dependencies
library DataTypes {

    uint256 public constant VERSION = 2;

    address public constant LIQUIDATION_WALLET = 0x0000000000000000000000000000000000000001;

    enum AssetState {Uninitialized, Active, PausedTrading, Withdrawing, Inactive, LiquidatorOnly}

    enum PositionType {Long, Short}

    enum AssetMode {Uninitialized, Active, Withdrawing, Inactive}

    enum AssetKind {SingleStable, SingleVolatile, LP}

    struct AssetStorage {
        uint256 assetsCount;
        mapping(uint256 => address) assetsList;
        mapping(address => DataTypes.AssetConfig) assetConfigs;
    }

    struct ReserveStorage {
        uint256 reservesCount;
        mapping(address => uint256) reservesList;
        mapping(uint256 => DataTypes.ReserveData) reserves;
    }

    struct CollateralStorage {
        uint256 collateralsCount;
        mapping(address => mapping(address => uint256)) collateralsList;
        mapping(uint256 => DataTypes.CollateralData) collaterals;
    }

    struct ProtocolConfig {
        address treasury;
        address configuratorAddress;
        address userData;
        uint256 leverageFactor;
        uint256 tradeFeeMantissa;
        uint256 liquidationRatioMantissa;
        uint256 swapBufferLimitPercentage;
    }

    struct MappingStorage {
        mapping(address => bool) whitelistedCallers;
        mapping(address => uint256) userLastTradeBlock;
        mapping(address => uint256) liquidatedCollaterals;
    }

    // Shared property of reserve, collateral and portfolio
    struct AssetConfig {
        uint256 assetId;
        uint8 decimals;
        AssetKind kind;
        ISwapAdapter swapAdapter;
        IPriceOracleGetter oracle;
    }

    struct ReserveConfiguration {
        uint32 depositFeeMantissaGwei;
        uint32 protocolRateMantissaGwei;
        uint32 utilizationBaseRateMantissaGwei;
        uint32 kinkMantissaGwei;
        uint32 multiplierAnnualGwei;
        uint32 jumpMultiplierAnnualGwei;
        // --- 208 bits used ---
        AssetState state;
        // @dev obsolete but do not remove
        AssetMode _mode;
    }

    struct ReserveDataExtension {
        address reinvestment;
        address longReinvestment;
        address bonusPool;
    }

    struct ReserveData {
        ReserveConfiguration configuration;
        ReserveDataExtension ext;
        address asset;
        uint256 poolId;
        uint256 liquidSupply;
        // scaled utilized supply on reserve, changes whenever a deposit, withdraw, borrow and repay is executed
        uint256 scaledUtilizedSupplyRay;
        uint256 longSupply;
        uint256 reserveIndexRay;
        uint256 utilizationPercentageRay;
        uint256 protocolIndexRay;
        uint256 lastUpdatedTimestamp;
    }

    struct ReserveDataCache {
        address asset;
        address reinvestment;
        address longReinvestment;
        uint256 currReserveIndexRay;
        uint256 currProtocolIndexRay;
        uint256 currBorrowIndexRay;
    }

    struct CollateralConfiguration {
        uint32 depositFeeMantissaGwei;
        uint32 ltvGwei;
        uint128 minBalance;
        // --- 192 bits used ---
        AssetMode mode;
    }

    struct CollateralData {
        CollateralConfiguration configuration;
        address asset;
        address reinvestment;
        uint256 poolId;
        uint256 liquidSupply;
        uint256 totalShareSupplyRay;
    }

    struct UserConfiguration {
        uint256 reserve;
        uint256 collateral;
        uint256 position;
    }

    struct UserData {
        UserConfiguration configuration;
        mapping(uint256 => uint256) reserveShares; // in ray
        mapping(uint256 => uint256) collateralShares; // in ray
        mapping(uint256 => int256) positions; // in ray
    }

    struct InitReserveData {
        address reinvestment;
        address bonusPool;
        address longReinvestment;
        uint32 depositFeeMantissa;
        uint32 protocolRateMantissaRay;
        uint32 utilizationBaseRateMantissaRay;
        uint32 kinkMantissaRay;
        uint32 multiplierAnnualRay;
        uint32 jumpMultiplierAnnualRay;
        AssetState state;
        AssetMode mode;
    }


    struct ValidateTradeParams {
        address user;
        uint256 amountToTrade;
        uint256 currShortReserveAvailableSupply;
        uint256 maxAmountToTrade;
        uint256 userLastTradeBlock;
    }

    struct UserLiquidity {
        uint256 totalCollateralUsdPreLtv;
        uint256 totalCollateralUsdPostLtv;
        uint256 totalLongUsd;
        uint256 totalShortUsd;
        int256 pnlUsd;
        int256 totalLeverageUsd;
        int256 availableLeverageUsd;
        bool isLiquidatable;
    }

    struct UserLiquidityCachedData {
        int256 currShortingPosition;
        int256 currLongingPosition;
        uint256 shortingPrice;
        uint256 shortingPriceDecimals;
        uint256 longingPrice;
        uint256 longingPriceDecimals;
    }
}
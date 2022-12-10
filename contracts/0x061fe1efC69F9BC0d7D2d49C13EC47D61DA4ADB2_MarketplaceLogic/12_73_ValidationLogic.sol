// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.10;

import {IERC20} from "../../../dependencies/openzeppelin/contracts/IERC20.sol";
import {IERC721} from "../../../dependencies/openzeppelin/contracts/IERC721.sol";
import {Address} from "../../../dependencies/openzeppelin/contracts/Address.sol";
import {GPv2SafeERC20} from "../../../dependencies/gnosis/contracts/GPv2SafeERC20.sol";
import {IReserveInterestRateStrategy} from "../../../interfaces/IReserveInterestRateStrategy.sol";
import {IScaledBalanceToken} from "../../../interfaces/IScaledBalanceToken.sol";
import {IPriceOracleGetter} from "../../../interfaces/IPriceOracleGetter.sol";
import {IPToken} from "../../../interfaces/IPToken.sol";
import {ICollateralizableERC721} from "../../../interfaces/ICollateralizableERC721.sol";
import {IAuctionableERC721} from "../../../interfaces/IAuctionableERC721.sol";
import {INToken} from "../../../interfaces/INToken.sol";
import {SignatureChecker} from "../../../dependencies/looksrare/contracts/libraries/SignatureChecker.sol";
import {IPriceOracleSentinel} from "../../../interfaces/IPriceOracleSentinel.sol";
import {ReserveConfiguration} from "../configuration/ReserveConfiguration.sol";
import {UserConfiguration} from "../configuration/UserConfiguration.sol";
import {Errors} from "../helpers/Errors.sol";
import {WadRayMath} from "../math/WadRayMath.sol";
import {PercentageMath} from "../math/PercentageMath.sol";
import {DataTypes} from "../types/DataTypes.sol";
import {ReserveLogic} from "./ReserveLogic.sol";
import {GenericLogic} from "./GenericLogic.sol";
import {SafeCast} from "../../../dependencies/openzeppelin/contracts/SafeCast.sol";
import {IToken} from "../../../interfaces/IToken.sol";
import {XTokenType, IXTokenType} from "../../../interfaces/IXTokenType.sol";
import {Helpers} from "../helpers/Helpers.sol";
import {INonfungiblePositionManager} from "../../../dependencies/uniswap/INonfungiblePositionManager.sol";
import "../../../interfaces/INTokenApeStaking.sol";

/**
 * @title ReserveLogic library
 *
 * @notice Implements functions to validate the different actions of the protocol
 */
library ValidationLogic {
    using WadRayMath for uint256;
    using PercentageMath for uint256;
    using ReserveConfiguration for DataTypes.ReserveConfigurationMap;
    using UserConfiguration for DataTypes.UserConfigurationMap;

    // Factor to apply to "only-variable-debt" liquidity rate to get threshold for rebalancing, expressed in bps
    // A value of 0.9e4 results in 90%
    uint256 public constant REBALANCE_UP_LIQUIDITY_RATE_THRESHOLD = 0.9e4;

    // Minimum health factor allowed under any circumstance
    // A value of 0.95e18 results in 0.95
    uint256 public constant MINIMUM_HEALTH_FACTOR_LIQUIDATION_THRESHOLD =
        0.95e18;

    /**
     * @dev Minimum health factor to consider a user position healthy
     * A value of 1e18 results in 1
     */
    uint256 public constant HEALTH_FACTOR_LIQUIDATION_THRESHOLD = 1e18;

    /**
     * @notice Validates a supply action.
     * @param reserveCache The cached data of the reserve
     * @param amount The amount to be supplied
     */
    function validateSupply(
        DataTypes.ReserveCache memory reserveCache,
        uint256 amount,
        DataTypes.AssetType assetType
    ) internal view {
        require(amount != 0, Errors.INVALID_AMOUNT);

        IXTokenType xToken = IXTokenType(reserveCache.xTokenAddress);
        require(
            xToken.getXTokenType() != XTokenType.PTokenSApe,
            Errors.SAPE_NOT_ALLOWED
        );

        (
            bool isActive,
            bool isFrozen,
            ,
            bool isPaused,
            DataTypes.AssetType reserveAssetType
        ) = reserveCache.reserveConfiguration.getFlags();

        require(reserveAssetType == assetType, Errors.INVALID_ASSET_TYPE);
        require(isActive, Errors.RESERVE_INACTIVE);
        require(!isPaused, Errors.RESERVE_PAUSED);
        require(!isFrozen, Errors.RESERVE_FROZEN);

        uint256 supplyCap = reserveCache.reserveConfiguration.getSupplyCap();

        if (assetType == DataTypes.AssetType.ERC20) {
            require(
                supplyCap == 0 ||
                    (IPToken(reserveCache.xTokenAddress)
                        .scaledTotalSupply()
                        .rayMul(reserveCache.nextLiquidityIndex) + amount) <=
                    supplyCap *
                        (10**reserveCache.reserveConfiguration.getDecimals()),
                Errors.SUPPLY_CAP_EXCEEDED
            );
        } else if (assetType == DataTypes.AssetType.ERC721) {
            require(
                supplyCap == 0 ||
                    (INToken(reserveCache.xTokenAddress).totalSupply() +
                        amount <=
                        supplyCap),
                Errors.SUPPLY_CAP_EXCEEDED
            );
        }
    }

    /**
     * @notice Validates a supply action from NToken contract
     * @param reserveCache The cached data of the reserve
     * @param params The params of the supply
     * @param assetType the type of the asset supplied
     */
    function validateSupplyFromNToken(
        DataTypes.ReserveCache memory reserveCache,
        DataTypes.ExecuteSupplyERC721Params memory params,
        DataTypes.AssetType assetType
    ) internal view {
        require(
            msg.sender == reserveCache.xTokenAddress,
            Errors.CALLER_NOT_XTOKEN
        );

        uint256 amount = params.tokenData.length;
        validateSupply(reserveCache, amount, assetType);

        for (uint256 index = 0; index < amount; index++) {
            // validate that the owner of the underlying asset is the NToken  contract
            require(
                IERC721(params.asset).ownerOf(
                    params.tokenData[index].tokenId
                ) == reserveCache.xTokenAddress,
                Errors.NOT_THE_OWNER
            );
            // validate that the owner of the ntoken that has the same tokenId is the zero address
            require(
                IERC721(reserveCache.xTokenAddress).ownerOf(
                    params.tokenData[index].tokenId
                ) == address(0x0),
                Errors.NOT_THE_OWNER
            );
        }
    }

    /**
     * @notice Validates a withdraw action.
     * @param reserveCache The cached data of the reserve
     * @param amount The amount to be withdrawn
     * @param userBalance The balance of the user
     */
    function validateWithdraw(
        DataTypes.ReserveCache memory reserveCache,
        uint256 amount,
        uint256 userBalance
    ) internal pure {
        require(amount != 0, Errors.INVALID_AMOUNT);

        require(
            amount <= userBalance,
            Errors.NOT_ENOUGH_AVAILABLE_USER_BALANCE
        );

        IXTokenType xToken = IXTokenType(reserveCache.xTokenAddress);
        require(
            xToken.getXTokenType() != XTokenType.PTokenSApe,
            Errors.SAPE_NOT_ALLOWED
        );

        (
            bool isActive,
            ,
            ,
            bool isPaused,
            DataTypes.AssetType reserveAssetType
        ) = reserveCache.reserveConfiguration.getFlags();

        require(
            reserveAssetType == DataTypes.AssetType.ERC20,
            Errors.INVALID_ASSET_TYPE
        );
        require(isActive, Errors.RESERVE_INACTIVE);
        require(!isPaused, Errors.RESERVE_PAUSED);
    }

    function validateWithdrawERC721(
        mapping(address => DataTypes.ReserveData) storage reservesData,
        DataTypes.ReserveCache memory reserveCache,
        address asset,
        uint256[] memory tokenIds
    ) internal view {
        (
            bool isActive,
            ,
            ,
            bool isPaused,
            DataTypes.AssetType reserveAssetType
        ) = reserveCache.reserveConfiguration.getFlags();

        require(
            reserveAssetType == DataTypes.AssetType.ERC721,
            Errors.INVALID_ASSET_TYPE
        );
        require(isActive, Errors.RESERVE_INACTIVE);
        require(!isPaused, Errors.RESERVE_PAUSED);

        INToken nToken = INToken(reserveCache.xTokenAddress);
        if (nToken.getXTokenType() == XTokenType.NTokenUniswapV3) {
            for (uint256 index = 0; index < tokenIds.length; index++) {
                ValidationLogic.validateForUniswapV3(
                    reservesData,
                    asset,
                    tokenIds[index],
                    true,
                    true,
                    false
                );
            }
        }
    }

    struct ValidateBorrowLocalVars {
        uint256 currentLtv;
        uint256 collateralNeededInBaseCurrency;
        uint256 userCollateralInBaseCurrency;
        uint256 userDebtInBaseCurrency;
        uint256 availableLiquidity;
        uint256 healthFactor;
        uint256 totalDebt;
        uint256 totalSupplyVariableDebt;
        uint256 reserveDecimals;
        uint256 borrowCap;
        uint256 amountInBaseCurrency;
        uint256 assetUnit;
        address siloedBorrowingAddress;
        bool isActive;
        bool isFrozen;
        bool isPaused;
        bool borrowingEnabled;
        bool siloedBorrowingEnabled;
        DataTypes.AssetType assetType;
    }

    /**
     * @notice Validates a borrow action.
     * @param reservesData The state of all the reserves
     * @param reservesList The addresses of all the active reserves
     * @param params Additional params needed for the validation
     */
    function validateBorrow(
        mapping(address => DataTypes.ReserveData) storage reservesData,
        mapping(uint256 => address) storage reservesList,
        DataTypes.ValidateBorrowParams memory params
    ) internal view {
        require(params.amount != 0, Errors.INVALID_AMOUNT);
        ValidateBorrowLocalVars memory vars;

        (
            vars.isActive,
            vars.isFrozen,
            vars.borrowingEnabled,
            vars.isPaused,
            vars.assetType
        ) = params.reserveCache.reserveConfiguration.getFlags();

        require(
            vars.assetType == DataTypes.AssetType.ERC20,
            Errors.INVALID_ASSET_TYPE
        );
        require(vars.isActive, Errors.RESERVE_INACTIVE);
        require(!vars.isPaused, Errors.RESERVE_PAUSED);
        require(!vars.isFrozen, Errors.RESERVE_FROZEN);
        require(vars.borrowingEnabled, Errors.BORROWING_NOT_ENABLED);

        require(
            params.priceOracleSentinel == address(0) ||
                IPriceOracleSentinel(params.priceOracleSentinel)
                    .isBorrowAllowed(),
            Errors.PRICE_ORACLE_SENTINEL_CHECK_FAILED
        );

        vars.reserveDecimals = params
            .reserveCache
            .reserveConfiguration
            .getDecimals();
        vars.borrowCap = params
            .reserveCache
            .reserveConfiguration
            .getBorrowCap();
        unchecked {
            vars.assetUnit = 10**vars.reserveDecimals;
        }

        if (vars.borrowCap != 0) {
            vars.totalSupplyVariableDebt = params
                .reserveCache
                .currScaledVariableDebt
                .rayMul(params.reserveCache.nextVariableBorrowIndex);

            vars.totalDebt = vars.totalSupplyVariableDebt + params.amount;

            unchecked {
                require(
                    vars.totalDebt <= vars.borrowCap * vars.assetUnit,
                    Errors.BORROW_CAP_EXCEEDED
                );
            }
        }

        (
            vars.userCollateralInBaseCurrency,
            ,
            vars.userDebtInBaseCurrency,
            vars.currentLtv,
            ,
            ,
            ,
            vars.healthFactor,
            ,

        ) = GenericLogic.calculateUserAccountData(
            reservesData,
            reservesList,
            DataTypes.CalculateUserAccountDataParams({
                userConfig: params.userConfig,
                reservesCount: params.reservesCount,
                user: params.userAddress,
                oracle: params.oracle
            })
        );

        require(
            vars.userCollateralInBaseCurrency != 0,
            Errors.COLLATERAL_BALANCE_IS_ZERO
        );
        require(vars.currentLtv != 0, Errors.LTV_VALIDATION_FAILED);

        require(
            vars.healthFactor > HEALTH_FACTOR_LIQUIDATION_THRESHOLD,
            Errors.HEALTH_FACTOR_LOWER_THAN_LIQUIDATION_THRESHOLD
        );

        vars.amountInBaseCurrency =
            IPriceOracleGetter(params.oracle).getAssetPrice(params.asset) *
            params.amount;
        unchecked {
            vars.amountInBaseCurrency /= vars.assetUnit;
        }

        //add the current already borrowed amount to the amount requested to calculate the total collateral needed.
        vars.collateralNeededInBaseCurrency = (vars.userDebtInBaseCurrency +
            vars.amountInBaseCurrency).percentDiv(vars.currentLtv); //LTV is calculated in percentage

        require(
            vars.collateralNeededInBaseCurrency <=
                vars.userCollateralInBaseCurrency,
            Errors.COLLATERAL_CANNOT_COVER_NEW_BORROW
        );
    }

    /**
     * @notice Validates a repay action.
     * @param reserveCache The cached data of the reserve
     * @param amountSent The amount sent for the repayment. Can be an actual value or uint(-1)
     * @param onBehalfOf The address of the user msg.sender is repaying for
     * @param variableDebt The borrow balance of the user
     */
    function validateRepay(
        DataTypes.ReserveCache memory reserveCache,
        uint256 amountSent,
        address onBehalfOf,
        uint256 variableDebt
    ) internal view {
        require(amountSent != 0, Errors.INVALID_AMOUNT);
        require(
            amountSent != type(uint256).max || msg.sender == onBehalfOf,
            Errors.NO_EXPLICIT_AMOUNT_TO_REPAY_ON_BEHALF
        );

        (
            bool isActive,
            ,
            ,
            bool isPaused,
            DataTypes.AssetType assetType
        ) = reserveCache.reserveConfiguration.getFlags();
        require(isActive, Errors.RESERVE_INACTIVE);
        require(!isPaused, Errors.RESERVE_PAUSED);
        require(
            assetType == DataTypes.AssetType.ERC20,
            Errors.INVALID_ASSET_TYPE
        );

        uint256 variableDebtPreviousIndex = IScaledBalanceToken(
            reserveCache.variableDebtTokenAddress
        ).getPreviousIndex(onBehalfOf);

        require(
            (variableDebtPreviousIndex < reserveCache.nextVariableBorrowIndex),
            Errors.SAME_BLOCK_BORROW_REPAY
        );

        require((variableDebt != 0), Errors.NO_DEBT_OF_SELECTED_TYPE);
    }

    /**
     * @notice Validates the action of setting an asset as collateral.
     * @param reserveCache The cached data of the reserve
     * @param userBalance The balance of the user
     */
    function validateSetUseERC20AsCollateral(
        DataTypes.ReserveCache memory reserveCache,
        uint256 userBalance
    ) internal pure {
        require(userBalance != 0, Errors.UNDERLYING_BALANCE_ZERO);

        IXTokenType xToken = IXTokenType(reserveCache.xTokenAddress);
        require(
            xToken.getXTokenType() != XTokenType.PTokenSApe,
            Errors.SAPE_NOT_ALLOWED
        );

        (
            bool isActive,
            ,
            ,
            bool isPaused,
            DataTypes.AssetType reserveAssetType
        ) = reserveCache.reserveConfiguration.getFlags();

        require(
            reserveAssetType == DataTypes.AssetType.ERC20,
            Errors.INVALID_ASSET_TYPE
        );
        require(isActive, Errors.RESERVE_INACTIVE);
        require(!isPaused, Errors.RESERVE_PAUSED);
    }

    function validateSetUseERC721AsCollateral(
        mapping(address => DataTypes.ReserveData) storage reservesData,
        DataTypes.ReserveCache memory reserveCache,
        address asset,
        uint256[] calldata tokenIds
    ) internal view {
        (
            bool isActive,
            ,
            ,
            bool isPaused,
            DataTypes.AssetType reserveAssetType
        ) = reserveCache.reserveConfiguration.getFlags();

        require(
            reserveAssetType == DataTypes.AssetType.ERC721,
            Errors.INVALID_ASSET_TYPE
        );
        require(isActive, Errors.RESERVE_INACTIVE);
        require(!isPaused, Errors.RESERVE_PAUSED);

        INToken nToken = INToken(reserveCache.xTokenAddress);
        if (nToken.getXTokenType() == XTokenType.NTokenUniswapV3) {
            for (uint256 index = 0; index < tokenIds.length; index++) {
                ValidationLogic.validateForUniswapV3(
                    reservesData,
                    asset,
                    tokenIds[index],
                    true,
                    true,
                    false
                );
            }
        }
    }

    struct ValidateLiquidateLocalVars {
        bool collateralReserveActive;
        bool collateralReservePaused;
        bool principalReserveActive;
        bool principalReservePaused;
        bool isCollateralEnabled;
        DataTypes.AssetType collateralReserveAssetType;
    }

    struct ValidateAuctionLocalVars {
        bool collateralReserveActive;
        bool collateralReservePaused;
        bool isCollateralEnabled;
        DataTypes.AssetType collateralReserveAssetType;
    }

    /**
     * @notice Validates the liquidation action.
     * @param userConfig The user configuration mapping
     * @param collateralReserve The reserve data of the collateral
     * @param params Additional parameters needed for the validation
     */
    function validateLiquidateERC20(
        DataTypes.UserConfigurationMap storage userConfig,
        DataTypes.ReserveData storage collateralReserve,
        DataTypes.ValidateLiquidateERC20Params memory params
    ) internal view {
        ValidateLiquidateLocalVars memory vars;

        (
            vars.collateralReserveActive,
            ,
            ,
            vars.collateralReservePaused,
            vars.collateralReserveAssetType
        ) = collateralReserve.configuration.getFlags();

        require(
            vars.collateralReserveAssetType == DataTypes.AssetType.ERC20,
            Errors.INVALID_ASSET_TYPE
        );

        require(
            msg.value == 0 || params.liquidationAsset == params.weth,
            Errors.INVALID_LIQUIDATION_ASSET
        );

        require(
            msg.value == 0 || msg.value >= params.actualLiquidationAmount,
            Errors.LIQUIDATION_AMOUNT_NOT_ENOUGH
        );

        IXTokenType xToken = IXTokenType(
            params.liquidationAssetReserveCache.xTokenAddress
        );
        require(
            xToken.getXTokenType() != XTokenType.PTokenSApe,
            Errors.SAPE_NOT_ALLOWED
        );

        (
            vars.principalReserveActive,
            ,
            ,
            vars.principalReservePaused,

        ) = params.liquidationAssetReserveCache.reserveConfiguration.getFlags();

        require(
            vars.collateralReserveActive && vars.principalReserveActive,
            Errors.RESERVE_INACTIVE
        );
        require(
            !vars.collateralReservePaused && !vars.principalReservePaused,
            Errors.RESERVE_PAUSED
        );

        require(
            params.priceOracleSentinel == address(0) ||
                params.healthFactor <
                MINIMUM_HEALTH_FACTOR_LIQUIDATION_THRESHOLD ||
                IPriceOracleSentinel(params.priceOracleSentinel)
                    .isLiquidationAllowed(),
            Errors.PRICE_ORACLE_SENTINEL_CHECK_FAILED
        );

        require(
            params.healthFactor < HEALTH_FACTOR_LIQUIDATION_THRESHOLD,
            Errors.HEALTH_FACTOR_NOT_BELOW_THRESHOLD
        );

        vars.isCollateralEnabled =
            collateralReserve.configuration.getLiquidationThreshold() != 0 &&
            userConfig.isUsingAsCollateral(collateralReserve.id);

        //if collateral isn't enabled as collateral by user, it cannot be liquidated
        require(
            vars.isCollateralEnabled,
            Errors.COLLATERAL_CANNOT_BE_AUCTIONED_OR_LIQUIDATED
        );
        require(
            params.totalDebt != 0,
            Errors.SPECIFIED_CURRENCY_NOT_BORROWED_BY_USER
        );
    }

    /**
     * @notice Validates the liquidation action.
     * @param userConfig The user configuration mapping
     * @param collateralReserve The reserve data of the collateral
     * @param params Additional parameters needed for the validation
     */
    function validateLiquidateERC721(
        mapping(address => DataTypes.ReserveData) storage reservesData,
        DataTypes.UserConfigurationMap storage userConfig,
        DataTypes.ReserveData storage collateralReserve,
        DataTypes.ValidateLiquidateERC721Params memory params
    ) internal view {
        require(
            params.liquidator != params.borrower,
            Errors.LIQUIDATOR_CAN_NOT_BE_SELF
        );

        ValidateLiquidateLocalVars memory vars;

        (
            vars.collateralReserveActive,
            ,
            ,
            vars.collateralReservePaused,
            vars.collateralReserveAssetType
        ) = collateralReserve.configuration.getFlags();

        require(
            vars.collateralReserveAssetType == DataTypes.AssetType.ERC721,
            Errors.INVALID_ASSET_TYPE
        );

        INToken nToken = INToken(collateralReserve.xTokenAddress);
        if (nToken.getXTokenType() == XTokenType.NTokenUniswapV3) {
            ValidationLogic.validateForUniswapV3(
                reservesData,
                params.collateralAsset,
                params.tokenId,
                true,
                true,
                false
            );
        }

        (
            vars.principalReserveActive,
            ,
            ,
            vars.principalReservePaused,

        ) = params.liquidationAssetReserveCache.reserveConfiguration.getFlags();

        require(
            vars.collateralReserveActive && vars.principalReserveActive,
            Errors.RESERVE_INACTIVE
        );
        require(
            !vars.collateralReservePaused && !vars.principalReservePaused,
            Errors.RESERVE_PAUSED
        );

        require(
            params.priceOracleSentinel == address(0) ||
                params.healthFactor <
                MINIMUM_HEALTH_FACTOR_LIQUIDATION_THRESHOLD ||
                IPriceOracleSentinel(params.priceOracleSentinel)
                    .isLiquidationAllowed(),
            Errors.PRICE_ORACLE_SENTINEL_CHECK_FAILED
        );

        if (params.auctionEnabled) {
            require(
                params.healthFactor < params.auctionRecoveryHealthFactor,
                Errors.ERC721_HEALTH_FACTOR_NOT_BELOW_THRESHOLD
            );
            require(
                IAuctionableERC721(params.xTokenAddress).isAuctioned(
                    params.tokenId
                ),
                Errors.AUCTION_NOT_STARTED
            );
        } else {
            require(
                params.healthFactor < HEALTH_FACTOR_LIQUIDATION_THRESHOLD,
                Errors.ERC721_HEALTH_FACTOR_NOT_BELOW_THRESHOLD
            );
        }

        require(
            params.maxLiquidationAmount >= params.actualLiquidationAmount &&
                (msg.value == 0 || msg.value >= params.maxLiquidationAmount),
            Errors.LIQUIDATION_AMOUNT_NOT_ENOUGH
        );

        vars.isCollateralEnabled =
            collateralReserve.configuration.getLiquidationThreshold() != 0 &&
            userConfig.isUsingAsCollateral(collateralReserve.id) &&
            ICollateralizableERC721(params.xTokenAddress).isUsedAsCollateral(
                params.tokenId
            );

        //if collateral isn't enabled as collateral by user, it cannot be liquidated
        require(
            vars.isCollateralEnabled,
            Errors.COLLATERAL_CANNOT_BE_AUCTIONED_OR_LIQUIDATED
        );
        require(params.globalDebt != 0, Errors.GLOBAL_DEBT_IS_ZERO);
    }

    /**
     * @notice Validates the health factor of a user.
     * @param reservesData The state of all the reserves
     * @param reservesList The addresses of all the active reserves
     * @param userConfig The state of the user for the specific reserve
     * @param user The user to validate health factor of
     * @param reservesCount The number of available reserves
     * @param oracle The price oracle
     */
    function validateHealthFactor(
        mapping(address => DataTypes.ReserveData) storage reservesData,
        mapping(uint256 => address) storage reservesList,
        DataTypes.UserConfigurationMap memory userConfig,
        address user,
        uint256 reservesCount,
        address oracle
    ) internal view returns (uint256, bool) {
        (
            ,
            ,
            ,
            ,
            ,
            ,
            ,
            uint256 healthFactor,
            ,
            bool hasZeroLtvCollateral
        ) = GenericLogic.calculateUserAccountData(
                reservesData,
                reservesList,
                DataTypes.CalculateUserAccountDataParams({
                    userConfig: userConfig,
                    reservesCount: reservesCount,
                    user: user,
                    oracle: oracle
                })
            );

        require(
            healthFactor >= HEALTH_FACTOR_LIQUIDATION_THRESHOLD,
            Errors.HEALTH_FACTOR_LOWER_THAN_LIQUIDATION_THRESHOLD
        );

        return (healthFactor, hasZeroLtvCollateral);
    }

    function validateStartAuction(
        DataTypes.UserConfigurationMap storage userConfig,
        DataTypes.ReserveData storage collateralReserve,
        DataTypes.ValidateAuctionParams memory params
    ) internal view {
        ValidateAuctionLocalVars memory vars;

        DataTypes.ReserveConfigurationMap
            memory collateralConfiguration = collateralReserve.configuration;
        (
            vars.collateralReserveActive,
            ,
            ,
            vars.collateralReservePaused,
            vars.collateralReserveAssetType
        ) = collateralConfiguration.getFlags();

        require(
            vars.collateralReserveAssetType == DataTypes.AssetType.ERC721,
            Errors.INVALID_ASSET_TYPE
        );

        require(
            IERC721(params.xTokenAddress).ownerOf(params.tokenId) ==
                params.user,
            Errors.NOT_THE_OWNER
        );

        require(vars.collateralReserveActive, Errors.RESERVE_INACTIVE);
        require(!vars.collateralReservePaused, Errors.RESERVE_PAUSED);

        require(
            collateralReserve.auctionStrategyAddress != address(0),
            Errors.AUCTION_NOT_ENABLED
        );
        require(
            !IAuctionableERC721(params.xTokenAddress).isAuctioned(
                params.tokenId
            ),
            Errors.AUCTION_ALREADY_STARTED
        );

        require(
            params.erc721HealthFactor < HEALTH_FACTOR_LIQUIDATION_THRESHOLD,
            Errors.ERC721_HEALTH_FACTOR_NOT_BELOW_THRESHOLD
        );

        vars.isCollateralEnabled =
            collateralConfiguration.getLiquidationThreshold() != 0 &&
            userConfig.isUsingAsCollateral(collateralReserve.id) &&
            ICollateralizableERC721(params.xTokenAddress).isUsedAsCollateral(
                params.tokenId
            );

        //if collateral isn't enabled as collateral by user, it cannot be auctioned
        require(
            vars.isCollateralEnabled,
            Errors.COLLATERAL_CANNOT_BE_AUCTIONED_OR_LIQUIDATED
        );
    }

    function validateEndAuction(
        DataTypes.ReserveData storage collateralReserve,
        DataTypes.ValidateAuctionParams memory params
    ) internal view {
        ValidateAuctionLocalVars memory vars;

        (
            vars.collateralReserveActive,
            ,
            ,
            vars.collateralReservePaused,
            vars.collateralReserveAssetType
        ) = collateralReserve.configuration.getFlags();

        require(
            vars.collateralReserveAssetType == DataTypes.AssetType.ERC721,
            Errors.INVALID_ASSET_TYPE
        );
        require(
            IERC721(params.xTokenAddress).ownerOf(params.tokenId) ==
                params.user,
            Errors.NOT_THE_OWNER
        );
        require(vars.collateralReserveActive, Errors.RESERVE_INACTIVE);
        require(!vars.collateralReservePaused, Errors.RESERVE_PAUSED);
        require(
            IAuctionableERC721(params.xTokenAddress).isAuctioned(
                params.tokenId
            ),
            Errors.AUCTION_NOT_STARTED
        );

        require(
            params.erc721HealthFactor >= params.auctionRecoveryHealthFactor,
            Errors.ERC721_HEALTH_FACTOR_NOT_ABOVE_THRESHOLD
        );
    }

    /**
     * @notice Validates the health factor of a user and the ltv of the asset being withdrawn.
     * @param reservesData The state of all the reserves
     * @param reservesList The addresses of all the active reserves
     * @param userConfig The state of the user for the specific reserve
     * @param asset The asset for which the ltv will be validated
     * @param from The user from which the xTokens are being transferred
     * @param reservesCount The number of available reserves
     * @param oracle The price oracle
     */
    function validateHFAndLtvERC20(
        mapping(address => DataTypes.ReserveData) storage reservesData,
        mapping(uint256 => address) storage reservesList,
        DataTypes.UserConfigurationMap memory userConfig,
        address asset,
        address from,
        uint256 reservesCount,
        address oracle
    ) internal view {
        DataTypes.ReserveData storage reserve = reservesData[asset];

        (, bool hasZeroLtvCollateral) = validateHealthFactor(
            reservesData,
            reservesList,
            userConfig,
            from,
            reservesCount,
            oracle
        );

        require(
            !hasZeroLtvCollateral || reserve.configuration.getLtv() == 0,
            Errors.LTV_VALIDATION_FAILED
        );
    }

    /**
     * @notice Validates the health factor of a user and the ltv of the erc721 asset being withdrawn.
     * @param reservesData The state of all the reserves
     * @param reservesList The addresses of all the active reserves
     * @param userConfig The state of the user for the specific reserve
     * @param asset The asset for which the ltv will be validated
     * @param tokenIds The asset tokenIds for which the ltv will be validated
     * @param from The user from which the xTokens are being transferred
     * @param reservesCount The number of available reserves
     * @param oracle The price oracle
     */
    function validateHFAndLtvERC721(
        mapping(address => DataTypes.ReserveData) storage reservesData,
        mapping(uint256 => address) storage reservesList,
        DataTypes.UserConfigurationMap memory userConfig,
        address asset,
        uint256[] memory tokenIds,
        address from,
        uint256 reservesCount,
        address oracle
    ) internal view {
        DataTypes.ReserveData storage reserve = reservesData[asset];

        (, bool hasZeroLtvCollateral) = validateHealthFactor(
            reservesData,
            reservesList,
            userConfig,
            from,
            reservesCount,
            oracle
        );

        if (hasZeroLtvCollateral) {
            INToken nToken = INToken(reserve.xTokenAddress);
            if (nToken.getXTokenType() == XTokenType.NTokenUniswapV3) {
                for (uint256 index = 0; index < tokenIds.length; index++) {
                    (uint256 assetLTV, ) = GenericLogic.getLtvAndLTForUniswapV3(
                        reservesData,
                        asset,
                        tokenIds[index],
                        reserve.configuration.getLtv(),
                        0
                    );
                    require(assetLTV == 0, Errors.LTV_VALIDATION_FAILED);
                }
            } else {
                require(
                    reserve.configuration.getLtv() == 0,
                    Errors.LTV_VALIDATION_FAILED
                );
            }
        }
    }

    /**
     * @notice Validates a transfer action.
     * @param reserve The reserve object
     */
    function validateTransferERC20(DataTypes.ReserveData storage reserve)
        internal
        view
    {
        require(!reserve.configuration.getPaused(), Errors.RESERVE_PAUSED);
    }

    /**
     * @notice Validates a transfer action.
     * @param reserve The reserve object
     */
    function validateTransferERC721(
        mapping(address => DataTypes.ReserveData) storage reservesData,
        DataTypes.ReserveData storage reserve,
        address asset,
        uint256 tokenId
    ) internal view {
        require(!reserve.configuration.getPaused(), Errors.RESERVE_PAUSED);
        INToken nToken = INToken(reserve.xTokenAddress);
        if (nToken.getXTokenType() == XTokenType.NTokenUniswapV3) {
            ValidationLogic.validateForUniswapV3(
                reservesData,
                asset,
                tokenId,
                false,
                true,
                false
            );
        }
    }

    /**
     * @notice Validates a drop reserve action.
     * @param reservesList The addresses of all the active reserves
     * @param reserve The reserve object
     * @param asset The address of the reserve's underlying asset
     **/
    function validateDropReserve(
        mapping(uint256 => address) storage reservesList,
        DataTypes.ReserveData storage reserve,
        address asset
    ) internal view {
        require(asset != address(0), Errors.ZERO_ADDRESS_NOT_VALID);
        require(
            reserve.id != 0 || reservesList[0] == asset,
            Errors.ASSET_NOT_LISTED
        );
        require(
            IToken(reserve.variableDebtTokenAddress).totalSupply() == 0,
            Errors.VARIABLE_DEBT_SUPPLY_NOT_ZERO
        );
        require(
            IToken(reserve.xTokenAddress).totalSupply() == 0,
            Errors.XTOKEN_SUPPLY_NOT_ZERO
        );
    }

    /**
     * @notice Validates a flash claim.
     * @param ps The pool storage
     * @param params The flash claim params
     */
    function validateFlashClaim(
        DataTypes.PoolStorage storage ps,
        DataTypes.ExecuteFlashClaimParams memory params
    ) internal view {
        DataTypes.ReserveData storage reserve = ps._reserves[params.nftAsset];
        require(
            reserve.configuration.getAssetType() == DataTypes.AssetType.ERC721,
            Errors.INVALID_ASSET_TYPE
        );
        require(
            params.receiverAddress != address(0),
            Errors.ZERO_ADDRESS_NOT_VALID
        );

        INToken nToken = INToken(reserve.xTokenAddress);
        XTokenType tokenType = nToken.getXTokenType();
        require(
            tokenType != XTokenType.NTokenUniswapV3,
            Errors.UNIV3_NOT_ALLOWED
        );

        // need check sApe status when flash claim for bayc or mayc
        if (
            tokenType == XTokenType.NTokenBAYC ||
            tokenType == XTokenType.NTokenMAYC
        ) {
            DataTypes.ReserveData storage sApeReserve = ps._reserves[
                DataTypes.SApeAddress
            ];

            (bool isActive, , , bool isPaused, ) = sApeReserve
                .configuration
                .getFlags();

            require(isActive, Errors.RESERVE_INACTIVE);
            require(!isPaused, Errors.RESERVE_PAUSED);
        }

        // only token owner can do flash claim
        for (uint256 i = 0; i < params.nftTokenIds.length; i++) {
            require(
                nToken.ownerOf(params.nftTokenIds[i]) == msg.sender,
                Errors.NOT_THE_OWNER
            );
        }
    }

    /**
     * @notice Validates a flashloan action.
     * @param reserve The state of the reserve
     */
    function validateFlashloanSimple(DataTypes.ReserveData storage reserve)
        internal
        view
    {
        (
            bool isActive,
            ,
            ,
            bool isPaused,
            DataTypes.AssetType assetType
        ) = reserve.configuration.getFlags();
        require(isActive, Errors.RESERVE_INACTIVE);
        require(!isPaused, Errors.RESERVE_PAUSED);
        require(
            assetType == DataTypes.AssetType.ERC20,
            Errors.INVALID_ASSET_TYPE
        );
    }

    function validateBuyWithCredit(
        DataTypes.ExecuteMarketplaceParams memory params
    ) internal pure {
        require(!params.marketplace.paused, Errors.MARKETPLACE_PAUSED);
    }

    function validateAcceptBidWithCredit(
        DataTypes.ExecuteMarketplaceParams memory params
    ) internal view {
        require(!params.marketplace.paused, Errors.MARKETPLACE_PAUSED);
        require(
            keccak256(abi.encodePacked(params.orderInfo.id)) ==
                keccak256(abi.encodePacked(params.credit.orderId)),
            Errors.CREDIT_DOES_NOT_MATCH_ORDER
        );
        require(
            verifyCreditSignature(
                params.credit,
                params.orderInfo.maker,
                params.credit.v,
                params.credit.r,
                params.credit.s
            ),
            Errors.INVALID_CREDIT_SIGNATURE
        );
    }

    function verifyCreditSignature(
        DataTypes.Credit memory credit,
        address signer,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) private view returns (bool) {
        return
            SignatureChecker.verify(
                hashCredit(credit),
                signer,
                v,
                r,
                s,
                getDomainSeparator()
            );
    }

    function hashCredit(DataTypes.Credit memory credit)
        private
        pure
        returns (bytes32)
    {
        bytes32 typeHash = keccak256(
            abi.encodePacked(
                "Credit(address token,uint256 amount,bytes orderId)"
            )
        );

        // https://github.com/ethereum/EIPs/blob/master/EIPS/eip-712.md#definition-of-encodedata
        return
            keccak256(
                abi.encode(
                    typeHash,
                    credit.token,
                    credit.amount,
                    keccak256(abi.encodePacked(credit.orderId))
                )
            );
    }

    function getDomainSeparator() internal view returns (bytes32) {
        return
            keccak256(
                abi.encode(
                    0x8b73c3c69bb8fe3d512ecc4cf759cc79239f7b179b0ffacaa9a75d522b39400f, // keccak256("EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)")
                    0x88d989289235fb06c18e3c2f7ea914f41f773e86fb0073d632539f566f4df353, // keccak256("ParaSpace")
                    0x722c0e0c80487266e8c6a45e3a1a803aab23378a9c32e6ebe029d4fad7bfc965, // keccak256(bytes("1.1")),
                    block.chainid,
                    address(this)
                )
            );
    }

    struct ValidateForUniswapV3LocalVars {
        bool token0IsActive;
        bool token0IsFrozen;
        bool token0IsPaused;
        bool token1IsActive;
        bool token1IsFrozen;
        bool token1IsPaused;
    }

    function validateForUniswapV3(
        mapping(address => DataTypes.ReserveData) storage reservesData,
        address asset,
        uint256 tokenId,
        bool checkActive,
        bool checkNotPaused,
        bool checkNotFrozen
    ) internal view {
        (
            ,
            ,
            address token0,
            address token1,
            ,
            ,
            ,
            ,
            ,
            ,
            ,

        ) = INonfungiblePositionManager(asset).positions(tokenId);

        ValidateForUniswapV3LocalVars memory vars;
        (
            vars.token0IsActive,
            vars.token0IsFrozen,
            ,
            vars.token0IsPaused,

        ) = reservesData[token0].configuration.getFlags();

        (
            vars.token1IsActive,
            vars.token1IsFrozen,
            ,
            vars.token1IsPaused,

        ) = reservesData[token1].configuration.getFlags();

        if (checkActive) {
            require(
                vars.token0IsActive && vars.token1IsActive,
                Errors.RESERVE_INACTIVE
            );
        }
        if (checkNotPaused) {
            require(
                !vars.token0IsPaused && !vars.token1IsPaused,
                Errors.RESERVE_PAUSED
            );
        }
        if (checkNotFrozen) {
            require(
                !vars.token0IsFrozen && !vars.token1IsFrozen,
                Errors.RESERVE_FROZEN
            );
        }
    }
}
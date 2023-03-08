// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.10;

import {IERC20} from "../../../dependencies/openzeppelin/contracts/IERC20.sol";
import {GPv2SafeERC20} from "../../../dependencies/gnosis/contracts/GPv2SafeERC20.sol";
import {PercentageMath} from "../../libraries/math/PercentageMath.sol";
import {WadRayMath} from "../../libraries/math/WadRayMath.sol";
import {Math} from "../../../dependencies/openzeppelin/contracts/Math.sol";
import {Helpers} from "../../libraries/helpers/Helpers.sol";
import {DataTypes} from "../../libraries/types/DataTypes.sol";
import {ReserveLogic} from "./ReserveLogic.sol";
import {SupplyLogic} from "./SupplyLogic.sol";
import {ValidationLogic} from "./ValidationLogic.sol";
import {GenericLogic} from "./GenericLogic.sol";
import {UserConfiguration} from "../../libraries/configuration/UserConfiguration.sol";
import {ReserveConfiguration} from "../../libraries/configuration/ReserveConfiguration.sol";
import {Address} from "../../../dependencies/openzeppelin/contracts/Address.sol";
import {IPToken} from "../../../interfaces/IPToken.sol";
import {IWETH} from "../../../misc/interfaces/IWETH.sol";
import {ICollateralizableERC721} from "../../../interfaces/ICollateralizableERC721.sol";
import {IAtomicCollateralizableERC721} from "../../../interfaces/IAtomicCollateralizableERC721.sol";
import {IAuctionableERC721} from "../../../interfaces/IAuctionableERC721.sol";
import {IXTokenType, XTokenType} from "../../../interfaces/IXTokenType.sol";
import {INToken} from "../../../interfaces/INToken.sol";
import {PRBMath} from "../../../dependencies/math/PRBMath.sol";
import {PRBMathUD60x18} from "../../../dependencies/math/PRBMathUD60x18.sol";
import {IReserveAuctionStrategy} from "../../../interfaces/IReserveAuctionStrategy.sol";
import {IVariableDebtToken} from "../../../interfaces/IVariableDebtToken.sol";
import {IPriceOracleGetter} from "../../../interfaces/IPriceOracleGetter.sol";
import {IPoolAddressesProvider} from "../../../interfaces/IPoolAddressesProvider.sol";
import {Errors} from "../../libraries/helpers/Errors.sol";

/**
 * @title LiquidationLogic library
 *
 * @notice Implements actions involving management of collateral in the protocol, the main one being the liquidations
 **/
library LiquidationLogic {
    using PercentageMath for uint256;
    using ReserveLogic for DataTypes.ReserveCache;
    using ReserveLogic for DataTypes.ReserveData;
    using UserConfiguration for DataTypes.UserConfigurationMap;
    using ReserveConfiguration for DataTypes.ReserveConfigurationMap;
    using PRBMathUD60x18 for uint256;
    using WadRayMath for uint256;
    using GPv2SafeERC20 for IERC20;

    /**
     * @dev Default percentage of borrower's debt to be repaid in a liquidation.
     * @dev Percentage applied when the users health factor is above `CLOSE_FACTOR_HF_THRESHOLD`
     * Expressed in bps, a value of 0.5e4 results in 50.00%
     */
    uint256 internal constant DEFAULT_LIQUIDATION_CLOSE_FACTOR = 0.5e4;

    /**
     * @dev Maximum percentage of borrower's debt to be repaid in a liquidation
     * @dev Percentage applied when the users health factor is below `CLOSE_FACTOR_HF_THRESHOLD`
     * Expressed in bps, a value of 1e4 results in 100.00%
     */
    uint256 public constant MAX_LIQUIDATION_CLOSE_FACTOR = 1e4;

    /**
     * @dev This constant represents below which health factor value it is possible to liquidate
     * an amount of debt corresponding to `MAX_LIQUIDATION_CLOSE_FACTOR`.
     * A value of 0.95e18 results in 95%
     */
    uint256 public constant CLOSE_FACTOR_HF_THRESHOLD = 0.95e18;

    // See `IPool` for descriptions
    event ReserveUsedAsCollateralEnabled(
        address indexed reserve,
        address indexed user
    );
    event ReserveUsedAsCollateralDisabled(
        address indexed reserve,
        address indexed user
    );
    event LiquidateERC20(
        address indexed collateralAsset,
        address indexed liquidationAsset,
        address indexed borrower,
        uint256 liquidationAmount,
        uint256 liquidatedCollateralAmount,
        address liquidator,
        bool receivePToken
    );
    event LiquidateERC721(
        address indexed collateralAsset,
        address indexed liquidationAsset,
        address indexed borrower,
        uint256 liquidationAmount,
        uint256 liquidatedCollateralTokenId,
        address liquidator,
        bool receiveNToken
    );
    event AuctionEnded(
        address indexed user,
        address indexed collateralAsset,
        uint256 indexed collateralTokenId
    );

    struct ExecuteLiquidateLocalVars {
        //userCollateral from collateralReserve
        uint256 userCollateral;
        //userGlobalCollateral from all reserves
        uint256 userGlobalCollateral;
        //userDebt from liquadationReserve
        uint256 userDebt;
        //userGlobalDebt from all reserves
        uint256 userGlobalDebt;
        //actualLiquidationAmount to repay based on collateral
        uint256 actualLiquidationAmount;
        //actualCollateral allowed to liquidate
        uint256 actualCollateralToLiquidate;
        //liquidationBonusRate from reserve config
        uint256 liquidationBonus;
        //user health factor
        uint256 healthFactor;
        //liquidation protocol fee to be sent to treasury
        uint256 liquidationProtocolFee;
        //liquidation funds payer
        address payer;
        //collateral P|N Token
        address collateralXToken;
        //auction strategy
        address auctionStrategyAddress;
        //liquidation asset reserve id
        uint16 liquidationAssetReserveId;
        //whether auction is enabled
        bool auctionEnabled;
        //liquidation reserve cache
        DataTypes.ReserveCache liquidationAssetReserveCache;
    }

    struct LiquidateParametersLocalVars {
        uint256 userCollateral;
        uint256 collateralPrice;
        uint256 liquidationAssetPrice;
        uint256 liquidationAssetDecimals;
        uint256 collateralDecimals;
        uint256 collateralAssetUnit;
        uint256 liquidationAssetUnit;
        uint256 actualCollateralToLiquidate;
        uint256 actualLiquidationAmount;
        uint256 actualLiquidationBonus;
        uint256 liquidationProtocolFeePercentage;
        uint256 liquidationProtocolFee;
        // Auction related
        uint256 auctionMultiplier;
        uint256 auctionStartTime;
    }

    /**
     * @notice Function to liquidate a position if its Health Factor drops below 1. The caller (liquidator)
     * covers `liquidationAmount` amount of debt of the user getting liquidated, and receives
     * a proportional amount of the `collateralAsset` plus a bonus to cover market risk
     * @dev Emits the `LiquidateERC20()` event
     * @param reservesData The state of all the reserves
     * @param reservesList The addresses of all the active reserves
     * @param usersConfig The users configuration mapping that track the supplied/borrowed assets
     * @param params The additional parameters needed to execute the liquidation function
     * @return actualLiquidationAmount The actual debt that is getting liquidated.
     **/
    function executeLiquidateERC20(
        mapping(address => DataTypes.ReserveData) storage reservesData,
        mapping(uint256 => address) storage reservesList,
        mapping(address => DataTypes.UserConfigurationMap) storage usersConfig,
        DataTypes.ExecuteLiquidateParams memory params
    ) external returns (uint256) {
        ExecuteLiquidateLocalVars memory vars;

        DataTypes.ReserveData storage collateralReserve = reservesData[
            params.collateralAsset
        ];
        DataTypes.ReserveData storage liquidationAssetReserve = reservesData[
            params.liquidationAsset
        ];
        DataTypes.UserConfigurationMap storage userConfig = usersConfig[
            params.borrower
        ];
        vars.liquidationAssetReserveCache = liquidationAssetReserve.cache();
        liquidationAssetReserve.updateState(vars.liquidationAssetReserveCache);

        (, , , , , , , vars.healthFactor, , ) = GenericLogic
            .calculateUserAccountData(
                reservesData,
                reservesList,
                DataTypes.CalculateUserAccountDataParams({
                    userConfig: userConfig,
                    reservesCount: params.reservesCount,
                    user: params.borrower,
                    oracle: params.priceOracle
                })
            );

        (vars.userDebt, vars.actualLiquidationAmount) = _calculateDebt(
            params,
            vars
        );

        (vars.collateralXToken, vars.liquidationBonus) = _getConfigurationData(
            collateralReserve
        );

        (
            vars.userCollateral,
            vars.actualCollateralToLiquidate,
            vars.actualLiquidationAmount,
            vars.liquidationProtocolFee
        ) = _calculateERC20LiquidationParameters(
            collateralReserve,
            params,
            vars
        );

        ValidationLogic.validateLiquidateERC20(
            userConfig,
            collateralReserve,
            DataTypes.ValidateLiquidateERC20Params({
                liquidationAssetReserveCache: vars.liquidationAssetReserveCache,
                weth: params.weth,
                liquidationAmount: params.liquidationAmount,
                actualLiquidationAmount: vars.actualLiquidationAmount,
                liquidationAsset: params.liquidationAsset,
                totalDebt: vars.userDebt,
                healthFactor: vars.healthFactor,
                priceOracleSentinel: params.priceOracleSentinel
            })
        );

        if (vars.userDebt == vars.actualLiquidationAmount) {
            userConfig.setBorrowing(liquidationAssetReserve.id, false);
        }

        // If the collateral being liquidated is equal to the user balance,
        // we set the currency as not being used as collateral anymore
        if (
            vars.actualCollateralToLiquidate + vars.liquidationProtocolFee ==
            vars.userCollateral
        ) {
            userConfig.setUsingAsCollateral(collateralReserve.id, false);
            emit ReserveUsedAsCollateralDisabled(
                params.collateralAsset,
                params.borrower
            );
        }

        // Transfer fee to treasury if it is non-zero
        if (vars.liquidationProtocolFee != 0) {
            IPToken(vars.collateralXToken).transferOnLiquidation(
                params.borrower,
                IPToken(vars.collateralXToken).RESERVE_TREASURY_ADDRESS(),
                vars.liquidationProtocolFee
            );
        }

        _burnDebtTokens(liquidationAssetReserve, params, vars);

        if (params.receiveXToken) {
            _liquidatePTokens(usersConfig, collateralReserve, params, vars);
        } else {
            _burnCollateralPTokens(collateralReserve, params, vars);
        }

        emit LiquidateERC20(
            params.collateralAsset,
            params.liquidationAsset,
            params.borrower,
            vars.actualLiquidationAmount,
            vars.actualCollateralToLiquidate,
            params.liquidator,
            params.receiveXToken
        );

        return vars.actualLiquidationAmount;
    }

    /**
     * @notice Function to liquidate an ERC721 of a position if its Health Factor drops below 1. The caller (liquidator)
     * covers `liquidationAmount` amount of debt of the user getting liquidated, and receives
     * a proportional tokenId of the `collateralAsset` minus a bonus to cover market risk
     * @dev Emits the `LiquidateERC721()` event
     * @param reservesData The state of all the reserves
     * @param reservesList The addresses of all the active reserves
     * @param usersConfig The users configuration mapping that track the supplied/borrowed assets
     * @param params The additional parameters needed to execute the liquidation function
     * @return actualLiquidationAmount The actual liquidation amount.
     **/
    function executeLiquidateERC721(
        mapping(address => DataTypes.ReserveData) storage reservesData,
        mapping(uint256 => address) storage reservesList,
        mapping(address => DataTypes.UserConfigurationMap) storage usersConfig,
        DataTypes.ExecuteLiquidateParams memory params
    ) external returns (uint256) {
        ExecuteLiquidateLocalVars memory vars;

        DataTypes.ReserveData storage collateralReserve = reservesData[
            params.collateralAsset
        ];
        DataTypes.ReserveData storage liquidationAssetReserve = reservesData[
            params.liquidationAsset
        ];
        DataTypes.UserConfigurationMap storage userConfig = usersConfig[
            params.borrower
        ];

        vars.liquidationAssetReserveId = liquidationAssetReserve.id;
        vars.liquidationAssetReserveCache = liquidationAssetReserve.cache();
        // liquidationAssetReserve.updateState(vars.liquidationAssetReserveCache);

        vars.auctionStrategyAddress = collateralReserve.auctionStrategyAddress;
        vars.auctionEnabled = vars.auctionStrategyAddress != address(0);

        (
            vars.userGlobalCollateral,
            ,
            vars.userGlobalDebt, //in base currency
            ,
            ,
            ,
            ,
            ,
            vars.healthFactor,

        ) = GenericLogic.calculateUserAccountData(
            reservesData,
            reservesList,
            DataTypes.CalculateUserAccountDataParams({
                userConfig: userConfig,
                reservesCount: params.reservesCount,
                user: params.borrower,
                oracle: params.priceOracle
            })
        );

        (vars.collateralXToken, vars.liquidationBonus) = _getConfigurationData(
            collateralReserve
        );
        if (vars.auctionEnabled) {
            vars.liquidationBonus = PercentageMath.PERCENTAGE_FACTOR;
        }

        (
            vars.userCollateral,
            vars.actualLiquidationAmount,
            vars.liquidationProtocolFee,
            vars.userGlobalDebt
        ) = _calculateERC721LiquidationParameters(
            collateralReserve,
            params,
            vars
        );

        ValidationLogic.validateLiquidateERC721(
            reservesData,
            userConfig,
            collateralReserve,
            DataTypes.ValidateLiquidateERC721Params({
                liquidationAssetReserveCache: vars.liquidationAssetReserveCache,
                liquidationAsset: params.liquidationAsset,
                liquidator: params.liquidator,
                borrower: params.borrower,
                globalDebt: vars.userGlobalDebt,
                actualLiquidationAmount: vars.actualLiquidationAmount,
                maxLiquidationAmount: params.liquidationAmount,
                healthFactor: vars.healthFactor,
                weth: params.weth,
                priceOracleSentinel: params.priceOracleSentinel,
                collateralAsset: params.collateralAsset,
                tokenId: params.collateralTokenId,
                xTokenAddress: vars.collateralXToken,
                auctionEnabled: vars.auctionEnabled,
                auctionRecoveryHealthFactor: params.auctionRecoveryHealthFactor
            })
        );

        if (vars.auctionEnabled) {
            IAuctionableERC721(vars.collateralXToken).endAuction(
                params.collateralTokenId
            );
            emit AuctionEnded(
                params.borrower,
                params.collateralAsset,
                params.collateralTokenId
            );
        }

        _supplyNewCollateral(reservesData, userConfig, params, vars);

        // If the collateral being liquidated is equal to the user balance,
        // we set the currency as not being used as collateral anymore
        if (vars.userCollateral == 1) {
            userConfig.setUsingAsCollateral(collateralReserve.id, false);
            emit ReserveUsedAsCollateralDisabled(
                params.collateralAsset,
                params.borrower
            );
        }

        // Transfer fee to treasury if it is non-zero
        if (vars.liquidationProtocolFee != 0) {
            IERC20(params.liquidationAsset).safeTransferFrom(
                vars.payer,
                IPToken(vars.liquidationAssetReserveCache.xTokenAddress)
                    .RESERVE_TREASURY_ADDRESS(),
                vars.liquidationProtocolFee
            );
        }

        if (params.receiveXToken) {
            INToken(vars.collateralXToken).transferOnLiquidation(
                params.borrower,
                params.liquidator,
                params.collateralTokenId
            );
        } else {
            _burnCollateralNTokens(params, vars);
        }

        emit LiquidateERC721(
            params.collateralAsset,
            params.liquidationAsset,
            params.borrower,
            vars.actualLiquidationAmount,
            params.collateralTokenId,
            params.liquidator,
            params.receiveXToken
        );

        return vars.actualLiquidationAmount;
    }

    /**
     * @notice Burns the collateral xTokens and transfers the underlying to the liquidator.
     * @dev   The function also updates the state and the interest rate of the collateral reserve.
     * @param collateralReserve The data of the collateral reserve
     * @param params The additional parameters needed to execute the liquidation function
     * @param vars The executeLiquidateERC20() function local vars
     */
    function _burnCollateralPTokens(
        DataTypes.ReserveData storage collateralReserve,
        DataTypes.ExecuteLiquidateParams memory params,
        ExecuteLiquidateLocalVars memory vars
    ) internal {
        DataTypes.ReserveCache memory collateralReserveCache = collateralReserve
            .cache();
        collateralReserve.updateState(collateralReserveCache);
        collateralReserve.updateInterestRates(
            collateralReserveCache,
            params.collateralAsset,
            0,
            vars.actualCollateralToLiquidate
        );

        // Burn the equivalent amount of xToken, sending the underlying to the liquidator
        IPToken(vars.collateralXToken).burn(
            params.borrower,
            params.liquidator,
            vars.actualCollateralToLiquidate,
            collateralReserveCache.nextLiquidityIndex
        );
    }

    /**
     * @notice Burns the collateral xTokens and transfers the underlying to the liquidator.
     * @dev   The function also updates the state and the interest rate of the collateral reserve.
     * @param params The additional parameters needed to execute the liquidation function
     * @param vars The executeLiquidateERC20() function local vars
     */
    function _burnCollateralNTokens(
        DataTypes.ExecuteLiquidateParams memory params,
        ExecuteLiquidateLocalVars memory vars
    ) internal {
        // Burn the equivalent amount of xToken, sending the underlying to the liquidator
        uint256[] memory tokenIds = new uint256[](1);
        tokenIds[0] = params.collateralTokenId;
        INToken(vars.collateralXToken).burn(
            params.borrower,
            params.liquidator,
            tokenIds
        );
    }

    /**
     * @notice Liquidates the user xTokens by transferring them to the liquidator.
     * @dev   The function also checks the state of the liquidator and activates the xToken as collateral
     *        as in standard transfers if the isolation mode constraints are respected.
     * @param usersConfig The users configuration mapping that track the supplied/borrowed assets
     * @param collateralReserve The data of the collateral reserve
     * @param params The additional parameters needed to execute the liquidation function
     * @param vars The executeLiquidateERC20() function local vars
     */
    function _liquidatePTokens(
        mapping(address => DataTypes.UserConfigurationMap) storage usersConfig,
        DataTypes.ReserveData storage collateralReserve,
        DataTypes.ExecuteLiquidateParams memory params,
        ExecuteLiquidateLocalVars memory vars
    ) internal {
        IPToken pToken = IPToken(vars.collateralXToken);
        uint256 liquidatorPreviousPTokenBalance = pToken.balanceOf(
            params.liquidator
        );
        pToken.transferOnLiquidation(
            params.borrower,
            params.liquidator,
            vars.actualCollateralToLiquidate
        );

        if (liquidatorPreviousPTokenBalance == 0) {
            DataTypes.UserConfigurationMap
                storage liquidatorConfig = usersConfig[params.liquidator];

            liquidatorConfig.setUsingAsCollateral(collateralReserve.id, true);
            emit ReserveUsedAsCollateralEnabled(
                params.collateralAsset,
                params.liquidator
            );
        }
    }

    /**
     * @notice Burns the debt tokens of the user up to the amount being repaid by the liquidator.
     * @dev The function alters the `liquidationAssetReserveCache` state in `vars` to update the debt related data.
     * @param liquidationAssetReserve The data of the liquidation reserve
     * @param params The additional parameters needed to execute the liquidation function
     * @param vars the executeLiquidateERC20() function local vars
     */
    function _burnDebtTokens(
        DataTypes.ReserveData storage liquidationAssetReserve,
        DataTypes.ExecuteLiquidateParams memory params,
        ExecuteLiquidateLocalVars memory vars
    ) internal {
        _depositETH(params, vars);
        // Handle payment
        IPToken(vars.liquidationAssetReserveCache.xTokenAddress)
            .handleRepayment(params.liquidator, vars.actualLiquidationAmount);
        // Burn borrower's debt token
        vars
            .liquidationAssetReserveCache
            .nextScaledVariableDebt = IVariableDebtToken(
            vars.liquidationAssetReserveCache.variableDebtTokenAddress
        ).burn(
                params.borrower,
                vars.actualLiquidationAmount,
                vars.liquidationAssetReserveCache.nextVariableBorrowIndex
            );
        // Update borrow & supply rate
        liquidationAssetReserve.updateInterestRates(
            vars.liquidationAssetReserveCache,
            params.liquidationAsset,
            vars.actualLiquidationAmount,
            0
        );
        // Transfers the debt asset being repaid to the xToken, where the liquidity is kept
        IERC20(params.liquidationAsset).safeTransferFrom(
            vars.payer,
            vars.liquidationAssetReserveCache.xTokenAddress,
            vars.actualLiquidationAmount
        );
    }

    /**
     * @notice Supply new collateral for taking out of borrower's another collateral
     * @param userConfig The user configuration that track the supplied/borrowed assets
     * @param params The additional parameters needed to execute the liquidation function
     * @param vars the executeLiquidateERC20() function local vars
     */
    function _supplyNewCollateral(
        mapping(address => DataTypes.ReserveData) storage reservesData,
        DataTypes.UserConfigurationMap storage userConfig,
        DataTypes.ExecuteLiquidateParams memory params,
        ExecuteLiquidateLocalVars memory vars
    ) internal {
        _depositETH(params, vars);

        SupplyLogic.executeSupply(
            reservesData,
            userConfig,
            DataTypes.ExecuteSupplyParams({
                asset: params.liquidationAsset,
                amount: vars.actualLiquidationAmount -
                    vars.liquidationProtocolFee,
                onBehalfOf: params.borrower,
                payer: vars.payer,
                referralCode: 0
            })
        );

        if (!userConfig.isUsingAsCollateral(vars.liquidationAssetReserveId)) {
            userConfig.setUsingAsCollateral(
                vars.liquidationAssetReserveId,
                true
            );
            emit ReserveUsedAsCollateralEnabled(
                params.liquidationAsset,
                params.borrower
            );
        }
    }

    /**
     * @notice Calculates the total debt of the user and the actual amount to liquidate depending on the health factor
     * and corresponding close factor. we are always using max closing factor in this version
     * @param params The additional parameters needed to execute the liquidation function
     * @param vars the executeLiquidateERC20() function local vars
     * @return The total debt of the user
     * @return The actual debt that is getting liquidated. If liquidation amount passed in by the liquidator is greater then the total user debt, then use the user total debt as the actual debt getting liquidated. If the user total debt is greater than the liquidation amount getting passed in by the liquidator, then use the liquidation amount the user is passing in.
     */
    function _calculateDebt(
        DataTypes.ExecuteLiquidateParams memory params,
        ExecuteLiquidateLocalVars memory vars
    ) internal view returns (uint256, uint256) {
        // userDebt = debt of the borrowed position needed for liquidation
        uint256 userDebt = Helpers.getUserCurrentDebt(
            params.borrower,
            vars.liquidationAssetReserveCache.variableDebtTokenAddress
        );

        uint256 closeFactor = vars.healthFactor > CLOSE_FACTOR_HF_THRESHOLD
            ? DEFAULT_LIQUIDATION_CLOSE_FACTOR
            : MAX_LIQUIDATION_CLOSE_FACTOR;

        uint256 maxLiquidatableDebt = userDebt.percentMul(closeFactor);

        uint256 actualLiquidationAmount = Math.min(
            params.liquidationAmount,
            maxLiquidatableDebt
        );

        return (userDebt, actualLiquidationAmount);
    }

    /**
     * @notice Returns the configuration data for the debt and the collateral reserves.
     * @param collateralReserve The data of the collateral reserve
     * @return The collateral xToken
     * @return The liquidation bonus to apply to the collateral
     */
    function _getConfigurationData(
        DataTypes.ReserveData storage collateralReserve
    ) internal view returns (address, uint256) {
        address collateralXToken = collateralReserve.xTokenAddress;
        uint256 liquidationBonus = collateralReserve
            .configuration
            .getLiquidationBonus();

        return (collateralXToken, liquidationBonus);
    }

    /**
     * @notice Calculates how much of a specific collateral can be liquidated, given
     * a certain amount of debt asset.
     * @dev This function needs to be called after all the checks to validate the liquidation have been performed,
     *   otherwise it might fail.
     * @param collateralReserve The data of the collateral reserve
     * @param params The additional parameters needed to execute the liquidation function
     * @param superVars the executeLiquidateERC20() function local vars
     * @return The user collateral balance
     * @return The maximum amount that is possible to liquidate given all the liquidation constraints (user balance, close factor)
     * @return The amount to repay with the liquidation
     * @return The fee taken from the liquidation bonus amount to be paid to the protocol
     **/
    function _calculateERC20LiquidationParameters(
        DataTypes.ReserveData storage collateralReserve,
        DataTypes.ExecuteLiquidateParams memory params,
        ExecuteLiquidateLocalVars memory superVars
    )
        internal
        view
        returns (
            uint256,
            uint256,
            uint256,
            uint256
        )
    {
        LiquidateParametersLocalVars memory vars;

        vars.userCollateral = IPToken(superVars.collateralXToken).balanceOf(
            params.borrower
        );
        vars.collateralPrice = IPriceOracleGetter(params.priceOracle)
            .getAssetPrice(params.collateralAsset);
        vars.liquidationAssetPrice = IPriceOracleGetter(params.priceOracle)
            .getAssetPrice(params.liquidationAsset);

        vars.collateralDecimals = collateralReserve.configuration.getDecimals();
        vars.liquidationAssetDecimals = superVars
            .liquidationAssetReserveCache
            .reserveConfiguration
            .getDecimals();

        unchecked {
            vars.collateralAssetUnit = 10**vars.collateralDecimals;
            vars.liquidationAssetUnit = 10**vars.liquidationAssetDecimals;
        }

        vars.liquidationProtocolFeePercentage = collateralReserve
            .configuration
            .getLiquidationProtocolFee();

        uint256 maxCollateralToLiquidate = ((vars.liquidationAssetPrice *
            superVars.actualLiquidationAmount *
            vars.collateralAssetUnit) /
            (vars.collateralPrice * vars.liquidationAssetUnit)).percentMul(
                superVars.liquidationBonus
            );

        if (maxCollateralToLiquidate > vars.userCollateral) {
            vars.actualCollateralToLiquidate = vars.userCollateral;
            vars.actualLiquidationAmount = (
                ((vars.collateralPrice *
                    vars.actualCollateralToLiquidate *
                    vars.liquidationAssetUnit) /
                    (vars.liquidationAssetPrice * vars.collateralAssetUnit))
            ).percentDiv(superVars.liquidationBonus);
        } else {
            vars.actualCollateralToLiquidate = maxCollateralToLiquidate;
            vars.actualLiquidationAmount = superVars.actualLiquidationAmount;
        }

        if (vars.liquidationProtocolFeePercentage != 0) {
            uint256 bonusCollateral = vars.actualCollateralToLiquidate -
                vars.actualCollateralToLiquidate.percentDiv(
                    superVars.liquidationBonus
                );

            vars.liquidationProtocolFee = bonusCollateral.percentMul(
                vars.liquidationProtocolFeePercentage
            );

            return (
                vars.userCollateral,
                vars.actualCollateralToLiquidate - vars.liquidationProtocolFee,
                vars.actualLiquidationAmount,
                vars.liquidationProtocolFee
            );
        } else {
            return (
                vars.userCollateral,
                vars.actualCollateralToLiquidate,
                vars.actualLiquidationAmount,
                0
            );
        }
    }

    /**
     * @notice Calculates how much of a specific collateral can be liquidated, given
     * a certain amount of debt asset.
     * @dev This function needs to be called after all the checks to validate the liquidation have been performed,
     *   otherwise it might fail.
     * @param collateralReserve The data of the collateral reserve
     * @param params The additional parameters needed to execute the liquidation function
     * @param superVars the executeLiquidateERC20() function local vars
     * @return The user collateral balance
     * @return The discounted nft price + the liquidationProtocolFee
     * @return The liquidationProtocolFee
     * @return The debt price you are paying in (for example, USD or ETH)
     **/
    function _calculateERC721LiquidationParameters(
        DataTypes.ReserveData storage collateralReserve,
        DataTypes.ExecuteLiquidateParams memory params,
        ExecuteLiquidateLocalVars memory superVars
    )
        internal
        view
        returns (
            uint256,
            uint256,
            uint256,
            uint256
        )
    {
        LiquidateParametersLocalVars memory vars;

        vars.userCollateral = ICollateralizableERC721(
            superVars.collateralXToken
        ).collateralizedBalanceOf(params.borrower);

        // price of the asset that is used as collateral
        if (
            IXTokenType(superVars.collateralXToken).getXTokenType() ==
            XTokenType.NTokenUniswapV3
        ) {
            vars.collateralPrice = IPriceOracleGetter(params.priceOracle)
                .getTokenPrice(
                    params.collateralAsset,
                    params.collateralTokenId
                );
        } else {
            uint256 assetPrice = IPriceOracleGetter(params.priceOracle)
                .getAssetPrice(params.collateralAsset);

            vars.collateralPrice = Helpers.getTraitBoostedTokenPrice(
                superVars.collateralXToken,
                assetPrice,
                params.collateralTokenId
            );
        }

        if (
            superVars.auctionEnabled &&
            IAuctionableERC721(superVars.collateralXToken).isAuctioned(
                params.collateralTokenId
            )
        ) {
            vars.auctionStartTime = IAuctionableERC721(
                superVars.collateralXToken
            ).getAuctionData(params.collateralTokenId).startTime;
            vars.auctionMultiplier = IReserveAuctionStrategy(
                superVars.auctionStrategyAddress
            ).calculateAuctionPriceMultiplier(
                    vars.auctionStartTime,
                    block.timestamp
                );
            vars.collateralPrice = vars.collateralPrice.mul(
                vars.auctionMultiplier
            );
        }

        // price of the asset the liquidator is liquidating with
        vars.liquidationAssetPrice = IPriceOracleGetter(params.priceOracle)
            .getAssetPrice(params.liquidationAsset);
        vars.liquidationAssetDecimals = superVars
            .liquidationAssetReserveCache
            .reserveConfiguration
            .getDecimals();

        unchecked {
            vars.liquidationAssetUnit = 10**vars.liquidationAssetDecimals;
        }

        vars.liquidationProtocolFeePercentage = collateralReserve
            .configuration
            .getLiquidationProtocolFee();

        uint256 collateralToLiquidate = (vars.collateralPrice *
            vars.liquidationAssetUnit) / vars.liquidationAssetPrice;

        // base currency to convert to liquidation asset unit.
        uint256 globalDebtAmount = (superVars.userGlobalDebt *
            vars.liquidationAssetUnit) / vars.liquidationAssetPrice;

        vars.actualLiquidationAmount = collateralToLiquidate.percentDiv(
            superVars.liquidationBonus
        );

        if (vars.liquidationProtocolFeePercentage != 0) {
            uint256 bonusCollateral = collateralToLiquidate -
                vars.actualLiquidationAmount;

            vars.liquidationProtocolFee = bonusCollateral.percentMul(
                vars.liquidationProtocolFeePercentage
            );

            return (
                vars.userCollateral,
                vars.actualLiquidationAmount + vars.liquidationProtocolFee,
                vars.liquidationProtocolFee,
                globalDebtAmount
            );
        } else {
            return (
                vars.userCollateral,
                vars.actualLiquidationAmount,
                0,
                globalDebtAmount
            );
        }
    }

    /**
     * @notice Convert msg.value to WETH and check if liquidationAsset is WETH (if msg.value > 0)
     * @param params The additional parameters needed to execute the liquidation function
     * @param vars the executeLiquidateERC20() function local vars
     */
    function _depositETH(
        DataTypes.ExecuteLiquidateParams memory params,
        ExecuteLiquidateLocalVars memory vars
    ) internal {
        if (msg.value == 0) {
            vars.payer = msg.sender;
        } else {
            vars.payer = address(this);
            IWETH(params.weth).deposit{value: vars.actualLiquidationAmount}();
            if (msg.value > vars.actualLiquidationAmount) {
                Address.sendValue(
                    payable(msg.sender),
                    msg.value - vars.actualLiquidationAmount
                );
            }
        }
    }
}
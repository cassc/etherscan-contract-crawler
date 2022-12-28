// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.10;

import {IERC20} from "../../../dependencies/openzeppelin/contracts/IERC20.sol";
import {IERC721Enumerable} from "../../../dependencies/openzeppelin/contracts/IERC721Enumerable.sol";
import {Math} from "../../../dependencies/openzeppelin/contracts/Math.sol";
import {IScaledBalanceToken} from "../../../interfaces/IScaledBalanceToken.sol";
import {INToken} from "../../../interfaces/INToken.sol";
import {ICollateralizableERC721} from "../../../interfaces/ICollateralizableERC721.sol";
import {IPriceOracleGetter} from "../../../interfaces/IPriceOracleGetter.sol";
import {ReserveConfiguration} from "../configuration/ReserveConfiguration.sol";
import {UserConfiguration} from "../configuration/UserConfiguration.sol";
import {PercentageMath} from "../math/PercentageMath.sol";
import {WadRayMath} from "../math/WadRayMath.sol";
import {DataTypes} from "../types/DataTypes.sol";
import {ReserveLogic} from "./ReserveLogic.sol";
import {INonfungiblePositionManager} from "../../../dependencies/uniswap/INonfungiblePositionManager.sol";
import {XTokenType} from "../../../interfaces/IXTokenType.sol";

/**
 * @title GenericLogic library
 *
 * @notice Implements protocol-level logic to calculate and validate the state of a user
 */
library GenericLogic {
    using ReserveLogic for DataTypes.ReserveData;
    using WadRayMath for uint256;
    using PercentageMath for uint256;
    using ReserveConfiguration for DataTypes.ReserveConfigurationMap;
    using UserConfiguration for DataTypes.UserConfigurationMap;

    struct CalculateUserAccountDataVars {
        uint256 assetPrice;
        uint256 assetUnit;
        DataTypes.ReserveConfigurationMap reserveConfiguration;
        uint256 userBalanceInBaseCurrency;
        uint256 decimals;
        uint256 ltv;
        uint256 liquidationThreshold;
        uint256 liquidationBonus;
        uint256 i;
        uint256 healthFactor;
        uint256 erc721HealthFactor;
        uint256 totalERC721CollateralInBaseCurrency;
        uint256 payableDebtByERC20Assets;
        uint256 totalCollateralInBaseCurrency;
        uint256 totalDebtInBaseCurrency;
        uint256 avgLtv;
        uint256 avgLiquidationThreshold;
        uint256 avgERC721LiquidationThreshold;
        address currentReserveAddress;
        bool hasZeroLtvCollateral;
        address xTokenAddress;
        XTokenType xTokenType;
    }

    /**
     * @notice Calculates the user data across the reserves.
     * @dev It includes the total liquidity/collateral/borrow balances in the base currency used by the price feed,
     * the average Loan To Value, the average Liquidation Ratio, and the Health factor.
     * @param reservesData The state of all the reserves
     * @param reservesList The addresses of all the active reserves
     * @param params Additional parameters needed for the calculation
     * @return The total collateral of the user in the base currency used by the price feed
     * @return The total ERC721 collateral of the user in the base currency used by the price feed
     * @return The total debt of the user in the base currency used by the price feed
     * @return The average ltv of the user
     * @return The average liquidation threshold of the user
     * @return The payable debt by ERC20 assets
     * @return The health factor of the user
     * @return The ERC721 health factor of the user
     * @return True if the ltv is zero, false otherwise
     **/
    function calculateUserAccountData(
        mapping(address => DataTypes.ReserveData) storage reservesData,
        mapping(uint256 => address) storage reservesList,
        DataTypes.CalculateUserAccountDataParams memory params
    )
        internal
        view
        returns (
            uint256,
            uint256,
            uint256,
            uint256,
            uint256,
            uint256,
            uint256,
            uint256,
            uint256,
            bool
        )
    {
        if (params.userConfig.isEmpty()) {
            return (
                0,
                0,
                0,
                0,
                0,
                0,
                0,
                type(uint256).max,
                type(uint256).max,
                false
            );
        }

        CalculateUserAccountDataVars memory vars;

        while (vars.i < params.reservesCount) {
            if (!params.userConfig.isUsingAsCollateralOrBorrowing(vars.i)) {
                unchecked {
                    ++vars.i;
                }
                continue;
            }

            vars.currentReserveAddress = reservesList[vars.i];

            if (vars.currentReserveAddress == address(0)) {
                unchecked {
                    ++vars.i;
                }
                continue;
            }

            DataTypes.ReserveData storage currentReserve = reservesData[
                vars.currentReserveAddress
            ];

            vars.reserveConfiguration = currentReserve.configuration;

            (
                vars.ltv,
                vars.liquidationThreshold,
                vars.liquidationBonus,
                vars.decimals,

            ) = vars.reserveConfiguration.getParams();

            unchecked {
                vars.assetUnit = 10**vars.decimals;
            }

            vars.xTokenAddress = currentReserve.xTokenAddress;

            if (
                vars.reserveConfiguration.getAssetType() ==
                DataTypes.AssetType.ERC20
            ) {
                vars.assetPrice = _getAssetPrice(
                    params.oracle,
                    vars.currentReserveAddress
                );

                if (
                    (vars.liquidationThreshold != 0) &&
                    params.userConfig.isUsingAsCollateral(vars.i)
                ) {
                    vars.userBalanceInBaseCurrency = _getUserBalanceForERC20(
                        params.user,
                        currentReserve,
                        vars.xTokenAddress,
                        vars.assetUnit,
                        vars.assetPrice
                    );

                    vars.payableDebtByERC20Assets += vars
                        .userBalanceInBaseCurrency
                        .percentDiv(vars.liquidationBonus);

                    vars.liquidationThreshold =
                        vars.userBalanceInBaseCurrency *
                        (vars.liquidationThreshold);
                    vars.avgLtv += vars.userBalanceInBaseCurrency * vars.ltv;

                    vars.totalCollateralInBaseCurrency += vars
                        .userBalanceInBaseCurrency;

                    if (vars.ltv == 0) {
                        vars.hasZeroLtvCollateral = true;
                    }

                    vars.avgLiquidationThreshold += vars.liquidationThreshold;
                }

                if (params.userConfig.isBorrowing(vars.i)) {
                    vars.totalDebtInBaseCurrency += _getUserDebtInBaseCurrency(
                        params.user,
                        currentReserve,
                        vars.assetPrice,
                        vars.assetUnit
                    );
                }
            } else {
                if (
                    (vars.liquidationThreshold != 0) &&
                    params.userConfig.isUsingAsCollateral(vars.i)
                ) {
                    vars.xTokenType = INToken(vars.xTokenAddress)
                        .getXTokenType();
                    if (vars.xTokenType == XTokenType.NTokenUniswapV3) {
                        (
                            vars.userBalanceInBaseCurrency,
                            vars.ltv,
                            vars.liquidationThreshold
                        ) = _getUserBalanceForUniswapV3(
                            reservesData,
                            params,
                            vars
                        );
                    } else {
                        vars
                            .userBalanceInBaseCurrency = _getUserBalanceForERC721(
                            params,
                            vars
                        );

                        vars.liquidationThreshold =
                            vars.userBalanceInBaseCurrency *
                            vars.liquidationThreshold;

                        if (vars.ltv == 0) {
                            vars.hasZeroLtvCollateral = true;
                        }

                        vars.ltv = vars.userBalanceInBaseCurrency * vars.ltv;
                    }

                    vars.avgERC721LiquidationThreshold += vars
                        .liquidationThreshold;
                    vars.totalERC721CollateralInBaseCurrency += vars
                        .userBalanceInBaseCurrency;
                    vars.totalCollateralInBaseCurrency += vars
                        .userBalanceInBaseCurrency;
                    vars.avgLtv += vars.ltv;
                    vars.avgLiquidationThreshold += vars.liquidationThreshold;
                }
            }

            unchecked {
                ++vars.i;
            }
        }

        unchecked {
            vars.avgLtv = vars.totalCollateralInBaseCurrency != 0
                ? vars.avgLtv / vars.totalCollateralInBaseCurrency
                : 0;
            vars.avgLiquidationThreshold = vars.totalCollateralInBaseCurrency !=
                0
                ? vars.avgLiquidationThreshold /
                    vars.totalCollateralInBaseCurrency
                : 0;

            vars.avgERC721LiquidationThreshold = vars
                .totalERC721CollateralInBaseCurrency != 0
                ? vars.avgERC721LiquidationThreshold /
                    vars.totalERC721CollateralInBaseCurrency
                : 0;
        }

        vars.healthFactor = (vars.totalDebtInBaseCurrency == 0)
            ? type(uint256).max
            : (
                vars.totalCollateralInBaseCurrency.percentMul(
                    vars.avgLiquidationThreshold
                )
            ).wadDiv(vars.totalDebtInBaseCurrency);

        vars.erc721HealthFactor = (vars.totalDebtInBaseCurrency == 0 ||
            vars.payableDebtByERC20Assets >= vars.totalDebtInBaseCurrency)
            ? type(uint256).max
            : (
                vars.totalERC721CollateralInBaseCurrency.percentMul(
                    vars.avgERC721LiquidationThreshold
                )
            ).wadDiv(
                    vars.totalDebtInBaseCurrency - vars.payableDebtByERC20Assets
                );

        return (
            vars.totalCollateralInBaseCurrency,
            vars.totalERC721CollateralInBaseCurrency,
            vars.totalDebtInBaseCurrency,
            vars.avgLtv,
            vars.avgLiquidationThreshold,
            vars.avgERC721LiquidationThreshold,
            vars.payableDebtByERC20Assets,
            vars.healthFactor,
            vars.erc721HealthFactor,
            vars.hasZeroLtvCollateral
        );
    }

    /**
     * @notice Calculates the maximum amount that can be borrowed depending on the available collateral, the total debt
     * and the average Loan To Value
     * @param totalCollateralInBaseCurrency The total collateral in the base currency used by the price feed
     * @param totalDebtInBaseCurrency The total borrow balance in the base currency used by the price feed
     * @param ltv The average loan to value
     * @return The amount available to borrow in the base currency of the used by the price feed
     **/
    function calculateAvailableBorrows(
        uint256 totalCollateralInBaseCurrency,
        uint256 totalDebtInBaseCurrency,
        uint256 ltv
    ) internal pure returns (uint256) {
        uint256 availableBorrowsInBaseCurrency = totalCollateralInBaseCurrency
            .percentMul(ltv);

        if (availableBorrowsInBaseCurrency < totalDebtInBaseCurrency) {
            return 0;
        }

        availableBorrowsInBaseCurrency =
            availableBorrowsInBaseCurrency -
            totalDebtInBaseCurrency;
        return availableBorrowsInBaseCurrency;
    }

    /**
     * @notice Calculates total debt of the user in the based currency used to normalize the values of the assets
     * @dev This fetches the `balanceOf` of the stable and variable debt tokens for the user. For gas reasons, the
     * variable debt balance is calculated by fetching `scaledBalancesOf` normalized debt, which is cheaper than
     * fetching `balanceOf`
     * @param user The address of the user
     * @param reserve The data of the reserve for which the total debt of the user is being calculated
     * @param assetPrice The price of the asset for which the total debt of the user is being calculated
     * @param assetUnit The value representing one full unit of the asset (10^decimals)
     * @return The total debt of the user normalized to the base currency
     **/
    function _getUserDebtInBaseCurrency(
        address user,
        DataTypes.ReserveData storage reserve,
        uint256 assetPrice,
        uint256 assetUnit
    ) private view returns (uint256) {
        // fetching variable debt
        uint256 userTotalDebt = IScaledBalanceToken(
            reserve.variableDebtTokenAddress
        ).scaledBalanceOf(user);
        if (userTotalDebt != 0) {
            userTotalDebt = userTotalDebt.rayMul(reserve.getNormalizedDebt());
            userTotalDebt = assetPrice * userTotalDebt;

            unchecked {
                return userTotalDebt / assetUnit;
            }
        } else {
            return 0;
        }
    }

    /**
     * @notice Calculates total xToken balance of the user in the based currency used by the price oracle
     * @dev For gas reasons, the xToken balance is calculated by fetching `scaledBalancesOf` normalized debt, which
     * is cheaper than fetching `balanceOf`
     * @return totalValue The total xToken balance of the user normalized to the base currency of the price oracle
     **/
    function _getUserBalanceForERC721(
        DataTypes.CalculateUserAccountDataParams memory params,
        CalculateUserAccountDataVars memory vars
    ) private view returns (uint256 totalValue) {
        INToken nToken = INToken(vars.xTokenAddress);
        bool isAtomicPrice = nToken.getAtomicPricingConfig();
        if (isAtomicPrice) {
            uint256 totalBalance = nToken.balanceOf(params.user);

            for (uint256 index = 0; index < totalBalance; index++) {
                uint256 tokenId = nToken.tokenOfOwnerByIndex(
                    params.user,
                    index
                );
                if (
                    ICollateralizableERC721(vars.xTokenAddress)
                        .isUsedAsCollateral(tokenId)
                ) {
                    totalValue += _getTokenPrice(
                        params.oracle,
                        vars.currentReserveAddress,
                        tokenId
                    );
                }
            }
        } else {
            uint256 assetPrice = _getAssetPrice(
                params.oracle,
                vars.currentReserveAddress
            );
            totalValue =
                ICollateralizableERC721(vars.xTokenAddress)
                    .collateralizedBalanceOf(params.user) *
                assetPrice;
        }
    }

    function getLtvAndLTForUniswapV3(
        mapping(address => DataTypes.ReserveData) storage reservesData,
        address uniswapV3Manager,
        uint256 tokenId,
        uint256 collectionLTV,
        uint256 collectionLiquidationThreshold
    ) internal view returns (uint256 ltv, uint256 liquidationThreshold) {
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

        ) = INonfungiblePositionManager(uniswapV3Manager).positions(tokenId);

        DataTypes.ReserveConfigurationMap memory token0Configs = reservesData[
            token0
        ].configuration;
        DataTypes.ReserveConfigurationMap memory token1Configs = reservesData[
            token1
        ].configuration;

        (
            uint256 token0Ltv,
            uint256 token0LiquidationThreshold,
            ,
            ,

        ) = token0Configs.getParams();
        (
            uint256 token1Ltv,
            uint256 token1LiquidationThreshold,
            ,
            ,

        ) = token1Configs.getParams();

        ltv = Math.min(Math.min(token0Ltv, token1Ltv), collectionLTV);
        liquidationThreshold = Math.min(
            Math.min(token0LiquidationThreshold, token1LiquidationThreshold),
            collectionLiquidationThreshold
        );
    }

    function _getUserBalanceForUniswapV3(
        mapping(address => DataTypes.ReserveData) storage reservesData,
        DataTypes.CalculateUserAccountDataParams memory params,
        CalculateUserAccountDataVars memory vars
    )
        private
        view
        returns (
            uint256 totalValue,
            uint256 totalLTV,
            uint256 totalLiquidationThreshold
        )
    {
        uint256 totalBalance = INToken(vars.xTokenAddress).balanceOf(
            params.user
        );
        for (uint256 index = 0; index < totalBalance; index++) {
            uint256 tokenId = IERC721Enumerable(vars.xTokenAddress)
                .tokenOfOwnerByIndex(params.user, index);
            if (
                ICollateralizableERC721(vars.xTokenAddress).isUsedAsCollateral(
                    tokenId
                )
            ) {
                uint256 tokenPrice = _getTokenPrice(
                    params.oracle,
                    vars.currentReserveAddress,
                    tokenId
                );
                totalValue += tokenPrice;

                (
                    uint256 tmpLTV,
                    uint256 tmpLiquidationThreshold
                ) = getLtvAndLTForUniswapV3(
                        reservesData,
                        vars.currentReserveAddress,
                        tokenId,
                        vars.ltv,
                        vars.liquidationThreshold
                    );

                if (tmpLTV == 0) {
                    vars.hasZeroLtvCollateral = true;
                }

                totalLTV += tmpLTV * tokenPrice;
                totalLiquidationThreshold +=
                    tmpLiquidationThreshold *
                    tokenPrice;
            }
        }
    }

    /**
     * @notice Calculates total xToken balance of the user in the based currency used by the price oracle
     * @dev For gas reasons, the xToken balance is calculated by fetching `scaledBalancesOf` normalized debt, which
     * is cheaper than fetching `balanceOf`
     * @param user The address of the user
     * @param assetUnit The value representing one full unit of the asset (10^decimals)
     * @return The total xToken balance of the user normalized to the base currency of the price oracle
     **/
    function _getUserBalanceForERC20(
        address user,
        DataTypes.ReserveData storage reserve,
        address xTokenAddress,
        uint256 assetUnit,
        uint256 assetPrice
    ) private view returns (uint256) {
        uint256 balance;

        uint256 normalizedIncome = reserve.getNormalizedIncome();
        balance =
            (
                IScaledBalanceToken(xTokenAddress).scaledBalanceOf(user).rayMul(
                    normalizedIncome
                )
            ) *
            assetPrice;

        unchecked {
            return (balance / assetUnit);
        }
    }

    function _getAssetPrice(address oracle, address currentReserveAddress)
        internal
        view
        returns (uint256)
    {
        return IPriceOracleGetter(oracle).getAssetPrice(currentReserveAddress);
    }

    function _getTokenPrice(
        address oracle,
        address currentReserveAddress,
        uint256 tokenId
    ) internal view returns (uint256) {
        return
            IPriceOracleGetter(oracle).getTokenPrice(
                currentReserveAddress,
                tokenId
            );
    }
}
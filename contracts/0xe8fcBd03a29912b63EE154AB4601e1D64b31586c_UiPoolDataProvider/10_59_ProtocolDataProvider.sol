// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.10;

import {IERC20Detailed} from "../dependencies/openzeppelin/contracts/IERC20Detailed.sol";
import {IERC721Metadata} from "../dependencies/openzeppelin/contracts/IERC721Metadata.sol";
import {ReserveConfiguration} from "../protocol/libraries/configuration/ReserveConfiguration.sol";
import {UserConfiguration} from "../protocol/libraries/configuration/UserConfiguration.sol";
import {DataTypes} from "../protocol/libraries/types/DataTypes.sol";
import {WadRayMath} from "../protocol/libraries/math/WadRayMath.sol";
import {IPoolAddressesProvider} from "../interfaces/IPoolAddressesProvider.sol";
import {IVariableDebtToken} from "../interfaces/IVariableDebtToken.sol";
import {ICollateralizableERC721} from "../interfaces/ICollateralizableERC721.sol";
import {IScaledBalanceToken} from "../interfaces/IScaledBalanceToken.sol";
import {INToken} from "../interfaces/INToken.sol";
import {IPToken} from "../interfaces/IPToken.sol";
import {IPool} from "../interfaces/IPool.sol";
import {IProtocolDataProvider} from "../interfaces/IProtocolDataProvider.sol";

/**
 * @title ProtocolDataProvider
 *
 * @notice Peripheral contract to collect and pre-process information from the Pool.
 */
contract ProtocolDataProvider is IProtocolDataProvider {
    using ReserveConfiguration for DataTypes.ReserveConfigurationMap;
    using UserConfiguration for DataTypes.UserConfigurationMap;
    using WadRayMath for uint256;

    address constant MKR = 0x9f8F72aA9304c8B593d555F12eF6589cC3A579A2;
    address constant ETH = 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;
    address constant SAPE = address(0x1);

    IPoolAddressesProvider public immutable ADDRESSES_PROVIDER;

    constructor(IPoolAddressesProvider addressesProvider) {
        ADDRESSES_PROVIDER = addressesProvider;
    }

    /// @inheritdoc IProtocolDataProvider
    function getAllReservesTokens()
        external
        view
        returns (DataTypes.TokenData[] memory)
    {
        IPool pool = IPool(ADDRESSES_PROVIDER.getPool());
        address[] memory reserves = pool.getReservesList();
        DataTypes.TokenData[] memory reservesTokens = new DataTypes.TokenData[](
            reserves.length
        );
        for (uint256 i = 0; i < reserves.length; i++) {
            if (reserves[i] == MKR) {
                reservesTokens[i] = DataTypes.TokenData({
                    symbol: "MKR",
                    tokenAddress: reserves[i]
                });
                continue;
            }
            if (reserves[i] == ETH) {
                reservesTokens[i] = DataTypes.TokenData({
                    symbol: "ETH",
                    tokenAddress: reserves[i]
                });
                continue;
            }
            if (reserves[i] == SAPE) {
                reservesTokens[i] = DataTypes.TokenData({
                    symbol: "SApe",
                    tokenAddress: reserves[i]
                });
                continue;
            }
            reservesTokens[i] = DataTypes.TokenData({
                symbol: IERC20Detailed(reserves[i]).symbol(),
                tokenAddress: reserves[i]
            });
        }
        return reservesTokens;
    }

    /// @inheritdoc IProtocolDataProvider
    function getAllXTokens()
        external
        view
        returns (DataTypes.TokenData[] memory)
    {
        IPool pool = IPool(ADDRESSES_PROVIDER.getPool());
        address[] memory reserves = pool.getReservesList();
        DataTypes.TokenData[] memory xTokens = new DataTypes.TokenData[](
            reserves.length
        );
        for (uint256 i = 0; i < reserves.length; i++) {
            DataTypes.ReserveData memory reserveData = pool.getReserveData(
                reserves[i]
            );
            if (
                reserveData.configuration.getAssetType() ==
                DataTypes.AssetType.ERC20
            ) {
                xTokens[i] = DataTypes.TokenData({
                    symbol: IERC20Detailed(reserveData.xTokenAddress).symbol(),
                    tokenAddress: reserveData.xTokenAddress
                });
            } else {
                xTokens[i] = DataTypes.TokenData({
                    symbol: IERC721Metadata(reserveData.xTokenAddress).symbol(),
                    tokenAddress: reserveData.xTokenAddress
                });
            }
        }
        return xTokens;
    }

    /// @inheritdoc IProtocolDataProvider
    function getReserveConfigurationData(address asset)
        external
        view
        returns (DataTypes.ReserveConfigData memory reserveData)
    {
        DataTypes.ReserveConfigurationMap memory configuration = IPool(
            ADDRESSES_PROVIDER.getPool()
        ).getConfiguration(asset);

        (
            reserveData.ltv,
            reserveData.liquidationThreshold,
            reserveData.liquidationBonus,
            reserveData.decimals,
            reserveData.reserveFactor
        ) = configuration.getParams();

        (
            reserveData.isActive,
            reserveData.isFrozen,
            reserveData.borrowingEnabled,
            reserveData.isPaused,

        ) = configuration.getFlags();

        reserveData.usageAsCollateralEnabled =
            reserveData.liquidationThreshold != 0;
    }

    /// @inheritdoc IProtocolDataProvider
    function getReserveCaps(address asset)
        external
        view
        returns (uint256 borrowCap, uint256 supplyCap)
    {
        (borrowCap, supplyCap) = IPool(ADDRESSES_PROVIDER.getPool())
            .getConfiguration(asset)
            .getCaps();
    }

    /// @inheritdoc IProtocolDataProvider
    function getSiloedBorrowing(address asset) external view returns (bool) {
        return
            IPool(ADDRESSES_PROVIDER.getPool())
                .getConfiguration(asset)
                .getSiloedBorrowing();
    }

    /// @inheritdoc IProtocolDataProvider
    function getLiquidationProtocolFee(address asset)
        external
        view
        returns (uint256)
    {
        return
            IPool(ADDRESSES_PROVIDER.getPool())
                .getConfiguration(asset)
                .getLiquidationProtocolFee();
    }

    /// @inheritdoc IProtocolDataProvider
    function getReserveData(address asset)
        external
        view
        override
        returns (
            uint256 accruedToTreasuryScaled,
            uint256 totalPToken,
            uint256 totalVariableDebt,
            uint256 liquidityRate,
            uint256 variableBorrowRate,
            uint256 liquidityIndex,
            uint256 variableBorrowIndex,
            uint40 lastUpdateTimestamp
        )
    {
        DataTypes.ReserveData memory reserve = IPool(
            ADDRESSES_PROVIDER.getPool()
        ).getReserveData(asset);

        return (
            reserve.accruedToTreasury,
            IERC20Detailed(reserve.xTokenAddress).totalSupply(),
            IERC20Detailed(reserve.variableDebtTokenAddress).totalSupply(),
            reserve.currentLiquidityRate,
            reserve.currentVariableBorrowRate,
            reserve.liquidityIndex,
            reserve.variableBorrowIndex,
            reserve.lastUpdateTimestamp
        );
    }

    /// @inheritdoc IProtocolDataProvider
    function getXTokenTotalSupply(address asset)
        external
        view
        override
        returns (uint256)
    {
        DataTypes.ReserveData memory reserve = IPool(
            ADDRESSES_PROVIDER.getPool()
        ).getReserveData(asset);
        if (reserve.configuration.getAssetType() == DataTypes.AssetType.ERC20) {
            return IPToken(reserve.xTokenAddress).totalSupply();
        } else {
            return INToken(reserve.xTokenAddress).totalSupply();
        }
    }

    /// @inheritdoc IProtocolDataProvider
    function getTotalDebt(address asset)
        external
        view
        override
        returns (uint256)
    {
        DataTypes.ReserveData memory reserve = IPool(
            ADDRESSES_PROVIDER.getPool()
        ).getReserveData(asset);
        return IERC20Detailed(reserve.variableDebtTokenAddress).totalSupply();
    }

    /// @inheritdoc IProtocolDataProvider
    function getUserReserveData(address asset, address user)
        external
        view
        returns (
            uint256 currentXTokenBalance,
            uint256 scaledXTokenBalance,
            uint256 collateralizedBalance,
            uint256 currentVariableDebt,
            uint256 scaledVariableDebt,
            uint256 liquidityRate,
            bool usageAsCollateralEnabled
        )
    {
        DataTypes.ReserveData memory reserve = IPool(
            ADDRESSES_PROVIDER.getPool()
        ).getReserveData(asset);

        DataTypes.UserConfigurationMap memory userConfig = IPool(
            ADDRESSES_PROVIDER.getPool()
        ).getUserConfiguration(user);

        liquidityRate = reserve.currentLiquidityRate;
        usageAsCollateralEnabled = userConfig.isUsingAsCollateral(reserve.id);

        if (reserve.configuration.getAssetType() == DataTypes.AssetType.ERC20) {
            currentXTokenBalance = IPToken(reserve.xTokenAddress).balanceOf(
                user
            );
            scaledXTokenBalance = IPToken(reserve.xTokenAddress)
                .scaledBalanceOf(user);
        } else {
            currentXTokenBalance = INToken(reserve.xTokenAddress).balanceOf(
                user
            );
            scaledXTokenBalance = INToken(reserve.xTokenAddress).balanceOf(
                user
            );
            collateralizedBalance = ICollateralizableERC721(
                reserve.xTokenAddress
            ).collateralizedBalanceOf(user);
        }

        currentVariableDebt = IERC20Detailed(reserve.variableDebtTokenAddress)
            .balanceOf(user);
        scaledVariableDebt = IVariableDebtToken(
            reserve.variableDebtTokenAddress
        ).scaledBalanceOf(user);
    }

    /// @inheritdoc IProtocolDataProvider
    function getReserveTokensAddresses(address asset)
        external
        view
        returns (address xTokenAddress, address variableDebtTokenAddress)
    {
        DataTypes.ReserveData memory reserve = IPool(
            ADDRESSES_PROVIDER.getPool()
        ).getReserveData(asset);

        return (reserve.xTokenAddress, reserve.variableDebtTokenAddress);
    }

    /// @inheritdoc IProtocolDataProvider
    function getStrategyAddresses(address asset)
        external
        view
        returns (
            address interestRateStrategyAddress,
            address auctionStrategyAddress
        )
    {
        DataTypes.ReserveData memory reserve = IPool(
            ADDRESSES_PROVIDER.getPool()
        ).getReserveData(asset);

        return (
            reserve.interestRateStrategyAddress,
            reserve.auctionStrategyAddress
        );
    }
}
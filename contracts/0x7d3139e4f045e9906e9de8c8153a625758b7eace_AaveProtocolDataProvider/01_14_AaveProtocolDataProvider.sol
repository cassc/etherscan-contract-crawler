// SPDX-License-Identifier: AGPL-3.0
pragma solidity 0.8.12;
pragma experimental ABIEncoderV2;

import "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import {ILendingPoolAddressesProvider} from "../interfaces/ILendingPoolAddressesProvider.sol";
import {ILendingPool} from "../interfaces/ILendingPool.sol";
import {IStableDebtToken} from "../interfaces/IStableDebtToken.sol";
import {IVariableDebtToken} from "../interfaces/IVariableDebtToken.sol";
import {ReserveConfiguration} from "./libraries/configuration/ReserveConfiguration.sol";
import {UserConfiguration} from "./libraries/configuration/UserConfiguration.sol";
import {DataTypes} from "./libraries/types/DataTypes.sol";

contract AaveProtocolDataProvider {
	using ReserveConfiguration for DataTypes.ReserveConfigurationMap;
	using UserConfiguration for DataTypes.UserConfigurationMap;

	address constant MKR = 0x9f8F72aA9304c8B593d555F12eF6589cC3A579A2;
	address constant ETH = 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;

	struct TokenData {
		string symbol;
		address tokenAddress;
	}

	ILendingPoolAddressesProvider public immutable ADDRESSES_PROVIDER;

	constructor(ILendingPoolAddressesProvider addressesProvider) {
		ADDRESSES_PROVIDER = addressesProvider;
	}

	function getAllReservesTokens() external view returns (TokenData[] memory) {
		ILendingPool pool = ILendingPool(ADDRESSES_PROVIDER.getLendingPool());
		address[] memory reserves = pool.getReservesList();
		TokenData[] memory reservesTokens = new TokenData[](reserves.length);
		for (uint256 i = 0; i < reserves.length; ) {
			if (reserves[i] == MKR) {
				reservesTokens[i] = TokenData({symbol: "MKR", tokenAddress: reserves[i]});
				continue;
			}
			if (reserves[i] == ETH) {
				reservesTokens[i] = TokenData({symbol: "ETH", tokenAddress: reserves[i]});
				continue;
			}
			reservesTokens[i] = TokenData({symbol: IERC20Metadata(reserves[i]).symbol(), tokenAddress: reserves[i]});
			unchecked {
				i++;
			}
		}
		return reservesTokens;
	}

	function getAllATokens() external view returns (TokenData[] memory) {
		ILendingPool pool = ILendingPool(ADDRESSES_PROVIDER.getLendingPool());
		address[] memory reserves = pool.getReservesList();
		TokenData[] memory aTokens = new TokenData[](reserves.length);
		for (uint256 i = 0; i < reserves.length; ) {
			DataTypes.ReserveData memory reserveData = pool.getReserveData(reserves[i]);
			aTokens[i] = TokenData({
				symbol: IERC20Metadata(reserveData.aTokenAddress).symbol(),
				tokenAddress: reserveData.aTokenAddress
			});
			unchecked {
				i++;
			}
		}
		return aTokens;
	}

	function getReserveConfigurationData(
		address asset
	)
		external
		view
		returns (
			uint256 decimals,
			uint256 ltv,
			uint256 liquidationThreshold,
			uint256 liquidationBonus,
			uint256 reserveFactor,
			bool usageAsCollateralEnabled,
			bool borrowingEnabled,
			bool stableBorrowRateEnabled,
			bool isActive,
			bool isFrozen
		)
	{
		DataTypes.ReserveConfigurationMap memory configuration = ILendingPool(ADDRESSES_PROVIDER.getLendingPool())
			.getConfiguration(asset);

		(ltv, liquidationThreshold, liquidationBonus, decimals, reserveFactor) = configuration.getParamsMemory();

		(isActive, isFrozen, borrowingEnabled, stableBorrowRateEnabled) = configuration.getFlagsMemory();

		usageAsCollateralEnabled = liquidationThreshold > 0;
	}

	function getReserveData(
		address asset
	)
		external
		view
		returns (
			uint256 availableLiquidity,
			uint256 totalStableDebt,
			uint256 totalVariableDebt,
			uint256 liquidityRate,
			uint256 variableBorrowRate,
			uint256 stableBorrowRate,
			uint256 averageStableBorrowRate,
			uint256 liquidityIndex,
			uint256 variableBorrowIndex,
			uint40 lastUpdateTimestamp
		)
	{
		DataTypes.ReserveData memory reserve = ILendingPool(ADDRESSES_PROVIDER.getLendingPool()).getReserveData(asset);

		return (
			IERC20Metadata(asset).balanceOf(reserve.aTokenAddress),
			IERC20Metadata(reserve.stableDebtTokenAddress).totalSupply(),
			IERC20Metadata(reserve.variableDebtTokenAddress).totalSupply(),
			reserve.currentLiquidityRate,
			reserve.currentVariableBorrowRate,
			reserve.currentStableBorrowRate,
			IStableDebtToken(reserve.stableDebtTokenAddress).getAverageStableRate(),
			reserve.liquidityIndex,
			reserve.variableBorrowIndex,
			reserve.lastUpdateTimestamp
		);
	}

	function getUserReserveData(
		address asset,
		address user
	)
		external
		view
		returns (
			uint256 currentATokenBalance,
			uint256 currentStableDebt,
			uint256 currentVariableDebt,
			uint256 principalStableDebt,
			uint256 scaledVariableDebt,
			uint256 stableBorrowRate,
			uint256 liquidityRate,
			uint40 stableRateLastUpdated,
			bool usageAsCollateralEnabled
		)
	{
		DataTypes.ReserveData memory reserve = ILendingPool(ADDRESSES_PROVIDER.getLendingPool()).getReserveData(asset);

		DataTypes.UserConfigurationMap memory userConfig = ILendingPool(ADDRESSES_PROVIDER.getLendingPool())
			.getUserConfiguration(user);

		currentATokenBalance = IERC20Metadata(reserve.aTokenAddress).balanceOf(user);
		currentVariableDebt = IERC20Metadata(reserve.variableDebtTokenAddress).balanceOf(user);
		currentStableDebt = IERC20Metadata(reserve.stableDebtTokenAddress).balanceOf(user);
		principalStableDebt = IStableDebtToken(reserve.stableDebtTokenAddress).principalBalanceOf(user);
		scaledVariableDebt = IVariableDebtToken(reserve.variableDebtTokenAddress).scaledBalanceOf(user);
		liquidityRate = reserve.currentLiquidityRate;
		stableBorrowRate = IStableDebtToken(reserve.stableDebtTokenAddress).getUserStableRate(user);
		stableRateLastUpdated = IStableDebtToken(reserve.stableDebtTokenAddress).getUserLastUpdated(user);
		usageAsCollateralEnabled = userConfig.isUsingAsCollateral(reserve.id);
	}

	function getReserveTokensAddresses(
		address asset
	) external view returns (address aTokenAddress, address stableDebtTokenAddress, address variableDebtTokenAddress) {
		DataTypes.ReserveData memory reserve = ILendingPool(ADDRESSES_PROVIDER.getLendingPool()).getReserveData(asset);

		return (reserve.aTokenAddress, reserve.stableDebtTokenAddress, reserve.variableDebtTokenAddress);
	}
}
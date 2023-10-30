// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.15;
pragma experimental ABIEncoderV2;
import "../PriceOracleInterface.sol";

library MarginalFunctionality {
	// We have the following approach: when liability is created we store
	// timestamp and size of liability. If the subsequent trade will deepen
	// this liability or won't fully cover it timestamp will not change.
	// However once outstandingAmount is covered we check whether balance on
	// that asset is positive or not. If not, liability still in the place but
	// time counter is dropped and timestamp set to `now`.
	struct Liability {
		address asset;
		uint64 timestamp;
		uint192 outstandingAmount;
	}

	enum PositionState {
		POSITIVE,
		NEGATIVE, // weighted position below 0
		OVERDUE, // liability is not returned for too long
		NOPRICE, // some assets has no price or expired
		INCORRECT // some of the basic requirements are not met: too many liabilities, no locked stake, etc
	}

	struct Position {
		PositionState state;
		int256 weightedPosition; // sum of weighted collateral minus liabilities
		int256 totalPosition; // sum of unweighted (total) collateral minus liabilities
		int256 totalLiabilities; // total liabilities value
	}

	// Constants from Exchange contract used for calculations
	struct UsedConstants {
		address user;
		address _oracleAddress;
		address _orionTokenAddress;
		uint64 positionOverdue;
		uint64 priceOverdue;
		uint8 stakeRisk;
		uint8 liquidationPremium;
	}

	/**
	 * @dev method to multiply numbers with uint8 based percent numbers
	 */
	function uint8Percent(int192 _a, uint8 _b) internal pure returns (int192 c) {
		int a = int256(_a);
		int b = int256(uint256(_b));
		int d = 255;
		c = int192((a > 65536) ? (a / d) * b : (a * b) / d);
	}

	/**
	 * @dev method to fetch asset prices in ORN tokens
	 */
	function getAssetPrice(address asset, address oracle) internal view returns (uint64 price, uint64 timestamp) {
		PriceOracleInterface.PriceDataOut memory assetPriceData = PriceOracleInterface(oracle).assetPrices(asset);
		(price, timestamp) = (assetPriceData.price, assetPriceData.timestamp);
	}

	/**
     * @dev method to calc weighted and absolute collateral value
     * @notice it only count for assets in collateralAssets list, all other
               assets will add 0 to position.
     * @return outdated whether any price is outdated
     * @return weightedPosition in ORN
     * @return totalPosition in ORN
     */
	function calcAssets(
		address[] storage collateralAssets,
		mapping(address => mapping(address => int192)) storage assetBalances,
		mapping(address => uint8) storage assetRisks,
		address user,
		address orionTokenAddress,
		address oracleAddress,
		uint64 priceOverdue
	) internal view returns (bool outdated, int192 weightedPosition, int192 totalPosition) {
		uint256 collateralAssetsLength = collateralAssets.length;
		for (uint256 i = 0; i < collateralAssetsLength; i++) {
			address asset = collateralAssets[i];
			if (assetBalances[user][asset] < 0) continue; // will be calculated in calcLiabilities
			(uint64 price, uint64 timestamp) = (1e8, 0xfffffff000000000);

			if (asset != orionTokenAddress) {
				(price, timestamp) = getAssetPrice(asset, oracleAddress);
			}

			// balance: i192, price u64 => balance*price fits i256
			// since generally balance <= N*maxInt112 (where N is number operations with it),
			// assetValue <= N*maxInt112*maxUInt64/1e8.
			// That is if N<= 2**17 *1e8 = 1.3e13  we can neglect overflows here

			uint8 specificRisk = assetRisks[asset];
			int192 balance = assetBalances[user][asset];
			int256 _assetValue = (int256(balance) * int256(uint256(price))) / 1e8;
			int192 assetValue = int192(_assetValue);

			// Overflows logic holds here as well, except that N is the number of
			// operations for all assets

			if (assetValue > 0) {
				weightedPosition += uint8Percent(assetValue, specificRisk);
				totalPosition += assetValue;
				outdated = outdated || ((timestamp + priceOverdue) < block.timestamp);
			}
		}

		return (outdated, weightedPosition, totalPosition);
	}

	/**
	 * @dev method to calc liabilities
	 * @return outdated whether any price is outdated
	 * @return overdue whether any liability is overdue
	 * @return weightedPosition weightedLiability == totalLiability in ORN
	 * @return totalPosition totalLiability in ORN
	 */
	function calcLiabilities(
		mapping(address => Liability[]) storage liabilities,
		mapping(address => mapping(address => int192)) storage assetBalances,
		address user,
		address oracleAddress,
		uint64 positionOverdue,
		uint64 priceOverdue
	) internal view returns (bool outdated, bool overdue, int192 weightedPosition, int192 totalPosition) {
		uint256 liabilitiesLength = liabilities[user].length;

		for (uint256 i = 0; i < liabilitiesLength; i++) {
			Liability storage liability = liabilities[user][i];
			int192 balance = assetBalances[user][liability.asset];
			(uint64 price, uint64 timestamp) = getAssetPrice(liability.asset, oracleAddress);
			// balance: i192, price u64 => balance*price fits i256
			// since generally balance <= N*maxInt112 (where N is number operations with it),
			// assetValue <= N*maxInt112*maxUInt64/1e8.
			// That is if N<= 2**17 *1e8 = 1.3e13  we can neglect overflows here

			int192 liabilityValue = int192((int256(balance) * int256(uint256(price))) / 1e8);
			weightedPosition += liabilityValue; //already negative since balance is negative
			totalPosition += liabilityValue;
			overdue = overdue || ((liability.timestamp + positionOverdue) < block.timestamp);
			outdated = outdated || ((timestamp + priceOverdue) < block.timestamp);
		}

		return (outdated, overdue, weightedPosition, totalPosition);
	}

	/**
	 * @dev method to calc Position
	 * @return result position structure
	 */
	function calcPosition(
		address[] storage collateralAssets,
		mapping(address => Liability[]) storage liabilities,
		mapping(address => mapping(address => int192)) storage assetBalances,
		mapping(address => uint8) storage assetRisks,
		UsedConstants memory constants
	) public view returns (Position memory result) {
		(bool outdatedPrice, int192 weightedPosition, int192 totalPosition) = calcAssets(
			collateralAssets,
			assetBalances,
			assetRisks,
			constants.user,
			constants._orionTokenAddress,
			constants._oracleAddress,
			constants.priceOverdue
		);

		(bool _outdatedPrice, bool overdue, int192 _weightedPosition, int192 _totalPosition) = calcLiabilities(
			liabilities,
			assetBalances,
			constants.user,
			constants._oracleAddress,
			constants.positionOverdue,
			constants.priceOverdue
		);

		weightedPosition += _weightedPosition;
		totalPosition += _totalPosition;
		outdatedPrice = outdatedPrice || _outdatedPrice;
		if (_totalPosition < 0) {
			result.totalLiabilities = _totalPosition;
		}
		if (weightedPosition < 0) {
			result.state = PositionState.NEGATIVE;
		}
		if (outdatedPrice) {
			result.state = PositionState.NOPRICE;
		}
		if (overdue) {
			result.state = PositionState.OVERDUE;
		}
		result.weightedPosition = weightedPosition;
		result.totalPosition = totalPosition;
	}

	/**
	 * @dev method removes liability
	 */
	function removeLiability(address user, address asset, mapping(address => Liability[]) storage liabilities) public {
		uint256 length = liabilities[user].length;

		for (uint256 i = 0; i < length; i++) {
			if (liabilities[user][i].asset == asset) {
				if (length > 1) {
					liabilities[user][i] = liabilities[user][length - 1];
				}
				liabilities[user].pop();
				break;
			}
		}
	}

	/**
	 * @dev method update liability
	 * @notice implement logic for outstandingAmount (see Liability description)
	 */
	function updateLiability(
		address user,
		address asset,
		mapping(address => Liability[]) storage liabilities,
		uint112 depositAmount,
		int192 currentBalance
	) internal {
		if (currentBalance >= 0) {
			removeLiability(user, asset, liabilities);
		} else {
			uint256 i;
			uint256 liabilitiesLength = liabilities[user].length;
			for (; i < liabilitiesLength - 1; i++) {
				if (liabilities[user][i].asset == asset) break;
			}
			Liability storage liability = liabilities[user][i];
			if (depositAmount >= liability.outstandingAmount) {
				liability.outstandingAmount = uint192(-currentBalance);
				liability.timestamp = uint64(block.timestamp);
			} else {
				liability.outstandingAmount -= depositAmount;
			}
		}
	}

	/**
     * @dev partially liquidate, that is cover some asset liability to get
            ORN from misbehavior broker
     */
	function partiallyLiquidate(
		address[] storage collateralAssets,
		mapping(address => Liability[]) storage liabilities,
		mapping(address => mapping(address => int192)) storage assetBalances,
		mapping(address => uint8) storage assetRisks,
		UsedConstants memory constants,
		address redeemedAsset,
		uint112 amount
	) public {
		//Note: constants.user - is broker who will be liquidated
		Position memory initialPosition = calcPosition(
			collateralAssets,
			liabilities,
			assetBalances,
			assetRisks,
			constants
		);
		require(
			initialPosition.state == PositionState.NEGATIVE || initialPosition.state == PositionState.OVERDUE,
			"E7"
		);
		address liquidator = msg.sender;
		require(assetBalances[liquidator][redeemedAsset] >= int192(uint192(amount)), "E8");
		require(assetBalances[constants.user][redeemedAsset] < 0, "E15");
		assetBalances[liquidator][redeemedAsset] -= int192(uint192(amount));
		assetBalances[constants.user][redeemedAsset] += int192(uint192(amount));

		if (assetBalances[constants.user][redeemedAsset] >= 0)
			removeLiability(constants.user, redeemedAsset, liabilities);

		(uint64 price, uint64 timestamp) = getAssetPrice(redeemedAsset, constants._oracleAddress);
		require((timestamp + constants.priceOverdue) > block.timestamp, "E9"); //Price is outdated

		reimburseLiquidator(
			amount,
			price,
			liquidator,
			assetBalances,
			constants.liquidationPremium,
			constants.user,
			constants._orionTokenAddress
		);

		Position memory finalPosition = calcPosition(
			collateralAssets,
			liabilities,
			assetBalances,
			assetRisks,
			constants
		);
		require(
			uint(finalPosition.state) < 3 && //POSITIVE,NEGATIVE or OVERDUE
				(finalPosition.weightedPosition > initialPosition.weightedPosition),
			"E10"
		); //Incorrect state position after liquidation
		if (finalPosition.state == PositionState.POSITIVE)
			require(finalPosition.weightedPosition < 10e8, "Can not liquidate to very positive state");
	}

	/**
	 * @dev reimburse liquidator with ORN: first from stake, than from broker balance
	 */
	function reimburseLiquidator(
		uint112 amount,
		uint64 price,
		address liquidator,
		mapping(address => mapping(address => int192)) storage assetBalances,
		uint8 liquidationPremium,
		address user,
		address orionTokenAddress
	) internal {
		int192 _orionAmount = int192((int256(uint256(amount)) * int256(uint256(price))) / 1e8);
		_orionAmount += uint8Percent(_orionAmount, liquidationPremium); //Liquidation premium
		// There is only 100m Orion tokens, fits i64
		require(_orionAmount == int64(_orionAmount), "E11");
		int192 onBalanceOrion = assetBalances[user][orionTokenAddress];

		require(onBalanceOrion >= _orionAmount, "E10");
		assetBalances[user][orionTokenAddress] -= _orionAmount;
		assetBalances[liquidator][orionTokenAddress] += _orionAmount;
	}
}
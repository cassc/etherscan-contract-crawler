// SPDX-License-Identifier: MIT

pragma solidity ^0.8.14;
import "./IDfrancBase.sol";
import "./IStabilityPool.sol";
import "./IDCHFToken.sol";
import "./IMONStaking.sol";
import "./ICollSurplusPool.sol";
import "./ISortedTroves.sol";
import "./IActivePool.sol";
import "./IDefaultPool.sol";
import "./IStabilityPoolManager.sol";

// Common interface for the Trove Manager.
interface ITroveManagerHelpers is IDfrancBase {
	enum Status {
		nonExistent,
		active,
		closedByOwner,
		closedByLiquidation,
		closedByRedemption
	}

	// Store the necessary data for a trove
	struct Trove {
		address asset;
		uint256 debt;
		uint256 coll;
		uint256 stake;
		Status status;
		uint128 arrayIndex;
	}

	/*
	 * --- Variable container structs for liquidations ---
	 *
	 * These structs are used to hold, return and assign variables inside the liquidation functions,
	 * in order to avoid the error: "CompilerError: Stack too deep".
	 **/

	struct LocalVariables_OuterLiquidationFunction {
		uint256 price;
		uint256 DCHFInStabPool;
		bool recoveryModeAtStart;
		uint256 liquidatedDebt;
		uint256 liquidatedColl;
	}

	struct LocalVariables_InnerSingleLiquidateFunction {
		uint256 collToLiquidate;
		uint256 pendingDebtReward;
		uint256 pendingCollReward;
	}

	struct LocalVariables_LiquidationSequence {
		uint256 remainingDCHFInStabPool;
		uint256 i;
		uint256 ICR;
		address user;
		bool backToNormalMode;
		uint256 entireSystemDebt;
		uint256 entireSystemColl;
	}

	struct LocalVariables_AssetBorrowerPrice {
		address _asset;
		address _borrower;
		uint256 _price;
	}

	struct LiquidationValues {
		uint256 entireTroveDebt;
		uint256 entireTroveColl;
		uint256 collGasCompensation;
		uint256 DCHFGasCompensation;
		uint256 debtToOffset;
		uint256 collToSendToSP;
		uint256 debtToRedistribute;
		uint256 collToRedistribute;
		uint256 collSurplus;
	}

	struct LiquidationTotals {
		uint256 totalCollInSequence;
		uint256 totalDebtInSequence;
		uint256 totalCollGasCompensation;
		uint256 totalDCHFGasCompensation;
		uint256 totalDebtToOffset;
		uint256 totalCollToSendToSP;
		uint256 totalDebtToRedistribute;
		uint256 totalCollToRedistribute;
		uint256 totalCollSurplus;
	}

	struct ContractsCache {
		IActivePool activePool;
		IDefaultPool defaultPool;
		IDCHFToken dchfToken;
		IMONStaking monStaking;
		ISortedTroves sortedTroves;
		ICollSurplusPool collSurplusPool;
		address gasPoolAddress;
	}
	// --- Variable container structs for redemptions ---

	struct RedemptionTotals {
		uint256 remainingDCHF;
		uint256 totalDCHFToRedeem;
		uint256 totalAssetDrawn;
		uint256 ETHFee;
		uint256 ETHToSendToRedeemer;
		uint256 decayedBaseRate;
		uint256 price;
		uint256 totalDCHFSupplyAtStart;
	}

	struct SingleRedemptionValues {
		uint256 DCHFLot;
		uint256 ETHLot;
		bool cancelledPartial;
	}

	// Object containing the ETH and DCHF snapshots for a given active trove
	struct RewardSnapshot {
		uint256 asset;
		uint256 DCHFDebt;
	}

	// --- Events ---

	event Liquidation(
		address indexed _asset,
		uint256 _liquidatedDebt,
		uint256 _liquidatedColl,
		uint256 _collGasCompensation,
		uint256 _DCHFGasCompensation
	);
	event Redemption(
		address indexed _asset,
		uint256 _attemptedDCHFAmount,
		uint256 _actualDCHFAmount,
		uint256 _AssetSent,
		uint256 _AssetFee
	);
	event TroveUpdated(
		address indexed _asset,
		address indexed _borrower,
		uint256 _debt,
		uint256 _coll,
		uint256 stake,
		uint8 operation
	);
	event TroveLiquidated(
		address indexed _asset,
		address indexed _borrower,
		uint256 _debt,
		uint256 _coll,
		uint8 operation
	);
	event BaseRateUpdated(address indexed _asset, uint256 _baseRate);
	event LastFeeOpTimeUpdated(address indexed _asset, uint256 _lastFeeOpTime);
	event TotalStakesUpdated(address indexed _asset, uint256 _newTotalStakes);
	event SystemSnapshotsUpdated(
		address indexed _asset,
		uint256 _totalStakesSnapshot,
		uint256 _totalCollateralSnapshot
	);
	event LTermsUpdated(address indexed _asset, uint256 _L_ETH, uint256 _L_DCHFDebt);
	event TroveSnapshotsUpdated(address indexed _asset, uint256 _L_ETH, uint256 _L_DCHFDebt);
	event TroveIndexUpdated(address indexed _asset, address _borrower, uint256 _newIndex);

	event TroveUpdated(
		address indexed _asset,
		address indexed _borrower,
		uint256 _debt,
		uint256 _coll,
		uint256 _stake,
		TroveManagerOperation _operation
	);
	event TroveLiquidated(
		address indexed _asset,
		address indexed _borrower,
		uint256 _debt,
		uint256 _coll,
		TroveManagerOperation _operation
	);

	enum TroveManagerOperation {
		applyPendingRewards,
		liquidateInNormalMode,
		liquidateInRecoveryMode,
		redeemCollateral
	}

	// Functions

	function addTroveOwnerToArray(address _asset, address _borrower)
		external
		returns (uint256 index);

	function applyPendingRewards(address _asset, address _borrower) external;

	function checkRecoveryMode(address _asset, uint256 _price) external returns (bool);

	function closeTrove(address _asset, address _borrower) external;

	function decayBaseRateFromBorrowing(address _asset) external;

	function decreaseTroveColl(
		address _asset,
		address _borrower,
		uint256 _collDecrease
	) external returns (uint256);

	function decreaseTroveDebt(
		address _asset,
		address _borrower,
		uint256 _collDecrease
	) external returns (uint256);

	function getBorrowingFee(address _asset, uint256 DCHFDebt) external view returns (uint256);

	function getBorrowingRateWithDecay(address _asset) external view returns (uint256);

	function getBorrowingRate(address _asset) external view returns (uint256);

	function getCurrentICR(
		address _asset,
		address _borrower,
		uint256 _price
	) external view returns (uint256);

	function getEntireDebtAndColl(address _asset, address _borrower)
		external
		view
		returns (
			uint256 debt,
			uint256 coll,
			uint256 pendingDCHFDebtReward,
			uint256 pendingAssetReward
		);

	function getNominalICR(address _asset, address _borrower) external view returns (uint256);

	function getPendingAssetReward(address _asset, address _borrower)
		external
		view
		returns (uint256);

	function getPendingDCHFDebtReward(address _asset, address _borrower)
		external
		view
		returns (uint256);

	function getRedemptionFeeWithDecay(address _asset, uint256 _assetDraw)
		external
		view
		returns (uint256);

	function getRedemptionRate(address _asset) external view returns (uint256);

	function getRedemptionRateWithDecay(address _asset) external view returns (uint256);

	function getTCR(address _asset, uint256 _price) external view returns (uint256);

	function getTroveColl(address _asset, address _borrower) external view returns (uint256);

	function getTroveDebt(address _asset, address _borrower) external view returns (uint256);

	function getTroveStake(address _asset, address _borrower) external view returns (uint256);

	function getTroveStatus(address _asset, address _borrower) external view returns (uint256);

	function hasPendingRewards(address _asset, address _borrower) external view returns (bool);

	function increaseTroveColl(
		address _asset,
		address _borrower,
		uint256 _collIncrease
	) external returns (uint256);

	function increaseTroveDebt(
		address _asset,
		address _borrower,
		uint256 _debtIncrease
	) external returns (uint256);

	function setTroveStatus(
		address _asset,
		address _borrower,
		uint256 num
	) external;

	function updateTroveRewardSnapshots(address _asset, address _borrower) external;

	function getBorrowingFeeWithDecay(address _asset, uint256 _DCHFDebt)
		external
		view
		returns (uint256);

	function getTroveOwnersCount(address _asset) external view returns (uint256);

	function getTroveFromTroveOwnersArray(address _asset, uint256 _index)
		external
		view
		returns (address);

	function setTroveDeptAndColl(
		address _asset,
		address _borrower,
		uint256 _debt,
		uint256 _coll
	) external;

	function isTroveActive(address _asset, address _borrower) external view returns (bool);

	function movePendingTroveRewardsToActivePool(
		address _asset,
		IActivePool _activePool,
		IDefaultPool _defaultPool,
		uint256 _DCHF,
		uint256 _amount
	) external;

	function removeStake(address _asset, address _borrower) external;

	function closeTrove(
		// access control
		address _asset,
		address _borrower,
		Status closedStatus
	) external;

	function redistributeDebtAndColl(
		address _asset,
		IActivePool _activePool,
		IDefaultPool _defaultPool,
		uint256 _debt,
		uint256 _coll
	) external;

	function updateSystemSnapshots_excludeCollRemainder(
		// access control
		address _asset,
		IActivePool _activePool,
		uint256 _collRemainder
	) external;

	function _checkPotentialRecoveryMode(
		// access control
		address _asset,
		uint256 _entireSystemColl,
		uint256 _entireSystemDebt,
		uint256 _price
	) external view returns (bool);

	function updateBaseRateFromRedemption(
		address _asset,
		uint256 _ETHDrawn,
		uint256 _price,
		uint256 _totalDCHFSupply
	) external returns (uint256);

	function updateStakeAndTotalStakes(address _asset, address _borrower)
		external
		returns (uint256);

	function _requireValidMaxFeePercentage(address _asset, uint256 _maxFeePercentage)
		external
		view;

	function _requireTCRoverMCR(address _asset, uint256 _price) external view;

	function _requireAmountGreaterThanZero(uint256 _amount) external pure;

	function _requireDCHFBalanceCoversRedemption(
		IDCHFToken _dchfToken,
		address _redeemer,
		uint256 _amount
	) external view;

	function applyPendingRewards(
		address _asset,
		IActivePool _activePool,
		IDefaultPool _defaultPool,
		address _borrower
	) external;

	function _getRedemptionFee(address _asset, uint256 _assetDraw)
		external
		view
		returns (uint256);

	function getTrove(address _asset, address _borrower)
		external
		view
		returns (
			address,
			uint256,
			uint256,
			uint256,
			Status,
			uint128
		);

	function getRewardSnapshots(address _asset, address _troveOwner)
		external
		view
		returns (uint256 asset, uint256 DCHFDebt);
}
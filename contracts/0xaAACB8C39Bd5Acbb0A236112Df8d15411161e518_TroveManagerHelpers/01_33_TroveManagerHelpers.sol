//SPDX-License-Identifier: MIT

pragma solidity ^0.8.14;

import "@openzeppelin/contracts/access/Ownable.sol";
import "./Interfaces/ITroveManagerHelpers.sol";
import "./Dependencies/DfrancBase.sol";
import "./Dependencies/CheckContract.sol";
import "./Dependencies/Initializable.sol";
import "./TroveManager.sol";

contract TroveManagerHelpers is
	DfrancBase,
	CheckContract,
	Initializable,
	ITroveManagerHelpers
{
	using SafeMath for uint256;
	string public constant NAME = "TroveManagerHelpers";

	// --- Connected contract declarations ---

	address public borrowerOperationsAddress;
	address public troveManagerAddress;

	IDCHFToken public dchfToken;

	// A doubly linked list of Troves, sorted by their sorted by their collateral ratios
	ISortedTroves public sortedTroves;

	// --- Data structures ---

	uint256 public constant SECONDS_IN_ONE_MINUTE = 60;
	/*
	 * Half-life of 12h. 12h = 720 min
	 * (1/2) = d^720 => d = (1/2)^(1/720)
	 */
	uint256 public constant MINUTE_DECAY_FACTOR = 999037758833783000;

	/*
	 * BETA: 18 digit decimal. Parameter by which to divide the redeemed fraction, in order to calc the new base rate from a redemption.
	 * Corresponds to (1 / ALPHA) in the white paper.
	 */
	uint256 public constant BETA = 2;

	mapping(address => uint256) public baseRate;

	// The timestamp of the latest fee operation (redemption or new DCHF issuance)
	mapping(address => uint256) public lastFeeOperationTime;

	mapping(address => mapping(address => Trove)) public Troves;

	mapping(address => uint256) public totalStakes;

	// Snapshot of the value of totalStakes, taken immediately after the latest liquidation
	mapping(address => uint256) public totalStakesSnapshot;

	// Snapshot of the total collateral across the ActivePool and DefaultPool, immediately after the latest liquidation.
	mapping(address => uint256) public totalCollateralSnapshot;

	/*
	 * L_ETH and L_DCHFDebt track the sums of accumulated liquidation rewards per unit staked. During its lifetime, each stake earns:
	 *
	 * An ETH gain of ( stake * [L_ETH - L_ETH(0)] )
	 * A DCHFDebt increase  of ( stake * [L_DCHFDebt - L_DCHFDebt(0)] )
	 *
	 * Where L_ETH(0) and L_DCHFDebt(0) are snapshots of L_ETH and L_DCHFDebt for the active Trove taken at the instant the stake was made
	 */
	mapping(address => uint256) public L_ASSETS;
	mapping(address => uint256) public L_DCHFDebts;

	// Map addresses with active troves to their RewardSnapshot
	mapping(address => mapping(address => RewardSnapshot)) private rewardSnapshots;

	// Array of all active trove addresses - used to to compute an approximate hint off-chain, for the sorted list insertion
	mapping(address => address[]) public TroveOwners;

	// Error trackers for the trove redistribution calculation
	mapping(address => uint256) public lastETHError_Redistribution;
	mapping(address => uint256) public lastDCHFDebtError_Redistribution;

	bool public isInitialized;

	// Internal Function and Modifier onlyBorrowerOperations
	// @dev This workaround was needed in order to reduce bytecode size

	function _onlyBOorTM() private view {
		require(
			msg.sender == borrowerOperationsAddress || msg.sender == troveManagerAddress,
			"WA"
		);
	}

	modifier onlyBOorTM() {
		_onlyBOorTM();
		_;
	}

	function _onlyBorrowerOperations() private view {
		require(msg.sender == borrowerOperationsAddress, "WA");
	}

	modifier onlyBorrowerOperations() {
		_onlyBorrowerOperations();
		_;
	}

	function _onlyTroveManager() private view {
		require(msg.sender == troveManagerAddress, "WA");
	}

	modifier onlyTroveManager() {
		_onlyTroveManager();
		_;
	}

	modifier troveIsActive(address _asset, address _borrower) {
		require(isTroveActive(_asset, _borrower), "IT");
		_;
	}

	// --- Dependency setter ---

	function setAddresses(
		address _borrowerOperationsAddress,
		address _dchfTokenAddress,
		address _sortedTrovesAddress,
		address _dfrancParamsAddress,
		address _troveManagerAddress
	) external initializer {
		require(!isInitialized, "AI");
		checkContract(_borrowerOperationsAddress);
		checkContract(_dchfTokenAddress);
		checkContract(_sortedTrovesAddress);
		checkContract(_dfrancParamsAddress);
		checkContract(_troveManagerAddress);
		isInitialized = true;

		borrowerOperationsAddress = _borrowerOperationsAddress;
		dchfToken = IDCHFToken(_dchfTokenAddress);
		sortedTroves = ISortedTroves(_sortedTrovesAddress);
		troveManagerAddress = _troveManagerAddress;

		setDfrancParameters(_dfrancParamsAddress);
	}

	// --- Helper functions ---

	// Return the nominal collateral ratio (ICR) of a given Trove, without the price. Takes a trove's pending coll and debt rewards from redistributions into account.
	function getNominalICR(address _asset, address _borrower)
		public
		view
		override
		returns (uint256)
	{
		(uint256 currentAsset, uint256 currentDCHFDebt) = _getCurrentTroveAmounts(
			_asset,
			_borrower
		);

		uint256 NICR = DfrancMath._computeNominalCR(currentAsset, currentDCHFDebt);
		return NICR;
	}

	// Return the current collateral ratio (ICR) of a given Trove. Takes a trove's pending coll and debt rewards from redistributions into account.
	function getCurrentICR(
		address _asset,
		address _borrower,
		uint256 _price
	) public view override returns (uint256) {
		(uint256 currentAsset, uint256 currentDCHFDebt) = _getCurrentTroveAmounts(
			_asset,
			_borrower
		);

		uint256 ICR = DfrancMath._computeCR(currentAsset, currentDCHFDebt, _price);
		return ICR;
	}

	function _getCurrentTroveAmounts(address _asset, address _borrower)
		internal
		view
		returns (uint256, uint256)
	{
		uint256 pendingAssetReward = getPendingAssetReward(_asset, _borrower);
		uint256 pendingDCHFDebtReward = getPendingDCHFDebtReward(_asset, _borrower);

		uint256 currentAsset = Troves[_borrower][_asset].coll.add(pendingAssetReward);
		uint256 currentDCHFDebt = Troves[_borrower][_asset].debt.add(pendingDCHFDebtReward);

		return (currentAsset, currentDCHFDebt);
	}

	function applyPendingRewards(address _asset, address _borrower)
		external
		override
		onlyBorrowerOperations
	{
		return
			_applyPendingRewards(
				_asset,
				dfrancParams.activePool(),
				dfrancParams.defaultPool(),
				_borrower
			);
	}

	function applyPendingRewards(
		address _asset,
		IActivePool _activePool,
		IDefaultPool _defaultPool,
		address _borrower
	) external override onlyTroveManager {
		_applyPendingRewards(_asset, _activePool, _defaultPool, _borrower);
	}

	// Add the borrowers's coll and debt rewards earned from redistributions, to their Trove
	function _applyPendingRewards(
		address _asset,
		IActivePool _activePool,
		IDefaultPool _defaultPool,
		address _borrower
	) internal {
		if (!hasPendingRewards(_asset, _borrower)) {
			return;
		}

		assert(isTroveActive(_asset, _borrower));

		// Compute pending rewards
		uint256 pendingAssetReward = getPendingAssetReward(_asset, _borrower);
		uint256 pendingDCHFDebtReward = getPendingDCHFDebtReward(_asset, _borrower);

		// Apply pending rewards to trove's state
		Troves[_borrower][_asset].coll = Troves[_borrower][_asset].coll.add(pendingAssetReward);
		Troves[_borrower][_asset].debt = Troves[_borrower][_asset].debt.add(pendingDCHFDebtReward);

		_updateTroveRewardSnapshots(_asset, _borrower);

		// Transfer from DefaultPool to ActivePool
		_movePendingTroveRewardsToActivePool(
			_asset,
			_activePool,
			_defaultPool,
			pendingDCHFDebtReward,
			pendingAssetReward
		);

		emit TroveUpdated(
			_asset,
			_borrower,
			Troves[_borrower][_asset].debt,
			Troves[_borrower][_asset].coll,
			Troves[_borrower][_asset].stake,
			TroveManagerOperation.applyPendingRewards
		);
	}

	// Update borrower's snapshots of L_ETH and L_DCHFDebt to reflect the current values
	function updateTroveRewardSnapshots(address _asset, address _borrower)
		external
		override
		onlyBorrowerOperations
	{
		return _updateTroveRewardSnapshots(_asset, _borrower);
	}

	function _updateTroveRewardSnapshots(address _asset, address _borrower) internal {
		rewardSnapshots[_borrower][_asset].asset = L_ASSETS[_asset];
		rewardSnapshots[_borrower][_asset].DCHFDebt = L_DCHFDebts[_asset];
		emit TroveSnapshotsUpdated(_asset, L_ASSETS[_asset], L_DCHFDebts[_asset]);
	}

	// Get the borrower's pending accumulated ETH reward, earned by their stake
	function getPendingAssetReward(address _asset, address _borrower)
		public
		view
		override
		returns (uint256)
	{
		uint256 snapshotAsset = rewardSnapshots[_borrower][_asset].asset;
		uint256 rewardPerUnitStaked = L_ASSETS[_asset].sub(snapshotAsset);

		if (rewardPerUnitStaked == 0 || !isTroveActive(_asset, _borrower)) {
			return 0;
		}

		uint256 stake = Troves[_borrower][_asset].stake;

		uint256 pendingAssetReward = stake.mul(rewardPerUnitStaked).div(DECIMAL_PRECISION);

		return pendingAssetReward;
	}

	// Get the borrower's pending accumulated DCHF reward, earned by their stake
	function getPendingDCHFDebtReward(address _asset, address _borrower)
		public
		view
		override
		returns (uint256)
	{
		uint256 snapshotDCHFDebt = rewardSnapshots[_borrower][_asset].DCHFDebt;
		uint256 rewardPerUnitStaked = L_DCHFDebts[_asset].sub(snapshotDCHFDebt);

		if (rewardPerUnitStaked == 0 || !isTroveActive(_asset, _borrower)) {
			return 0;
		}

		uint256 stake = Troves[_borrower][_asset].stake;

		uint256 pendingDCHFDebtReward = stake.mul(rewardPerUnitStaked).div(DECIMAL_PRECISION);

		return pendingDCHFDebtReward;
	}

	function hasPendingRewards(address _asset, address _borrower)
		public
		view
		override
		returns (bool)
	{
		if (!isTroveActive(_asset, _borrower)) {
			return false;
		}

		return (rewardSnapshots[_borrower][_asset].asset < L_ASSETS[_asset]);
	}

	function getEntireDebtAndColl(address _asset, address _borrower)
		public
		view
		override
		returns (
			uint256 debt,
			uint256 coll,
			uint256 pendingDCHFDebtReward,
			uint256 pendingAssetReward
		)
	{
		debt = Troves[_borrower][_asset].debt;
		coll = Troves[_borrower][_asset].coll;

		pendingDCHFDebtReward = getPendingDCHFDebtReward(_asset, _borrower);
		pendingAssetReward = getPendingAssetReward(_asset, _borrower);

		debt = debt.add(pendingDCHFDebtReward);
		coll = coll.add(pendingAssetReward);
	}

	function removeStake(address _asset, address _borrower) external override onlyBOorTM {
		return _removeStake(_asset, _borrower);
	}

	function _removeStake(address _asset, address _borrower) internal {
		//add access control
		uint256 stake = Troves[_borrower][_asset].stake;
		totalStakes[_asset] = totalStakes[_asset].sub(stake);
		Troves[_borrower][_asset].stake = 0;
	}

	function updateStakeAndTotalStakes(address _asset, address _borrower)
		external
		override
		onlyBOorTM
		returns (uint256)
	{
		return _updateStakeAndTotalStakes(_asset, _borrower);
	}

	// Update borrower's stake based on their latest collateral value
	function _updateStakeAndTotalStakes(address _asset, address _borrower)
		internal
		returns (uint256)
	{
		uint256 newStake = _computeNewStake(_asset, Troves[_borrower][_asset].coll);
		uint256 oldStake = Troves[_borrower][_asset].stake;
		Troves[_borrower][_asset].stake = newStake;

		totalStakes[_asset] = totalStakes[_asset].sub(oldStake).add(newStake);
		emit TotalStakesUpdated(_asset, totalStakes[_asset]);

		return newStake;
	}

	// Calculate a new stake based on the snapshots of the totalStakes and totalCollateral taken at the last liquidation
	function _computeNewStake(address _asset, uint256 _coll) internal view returns (uint256) {
		uint256 stake;
		if (totalCollateralSnapshot[_asset] == 0) {
			stake = _coll;
		} else {
			/*
			 * The following assert() holds true because:
			 * - The system always contains >= 1 trove
			 * - When we close or liquidate a trove, we redistribute the pending rewards, so if all troves were closed/liquidated,
			 * rewards would’ve been emptied and totalCollateralSnapshot would be zero too.
			 */
			assert(totalStakesSnapshot[_asset] > 0);
			stake = _coll.mul(totalStakesSnapshot[_asset]).div(totalCollateralSnapshot[_asset]);
		}
		return stake;
	}

	function redistributeDebtAndColl(
		address _asset,
		IActivePool _activePool,
		IDefaultPool _defaultPool,
		uint256 _debt,
		uint256 _coll
	) external override onlyTroveManager {
		_redistributeDebtAndColl(_asset, _activePool, _defaultPool, _debt, _coll);
	}

	function _redistributeDebtAndColl(
		address _asset,
		IActivePool _activePool,
		IDefaultPool _defaultPool,
		uint256 _debt,
		uint256 _coll
	) internal {
		if (_debt == 0) {
			return;
		}

		/*
		 * Add distributed coll and debt rewards-per-unit-staked to the running totals. Division uses a "feedback"
		 * error correction, to keep the cumulative error low in the running totals L_ETH and L_DCHFDebt:
		 *
		 * 1) Form numerators which compensate for the floor division errors that occurred the last time this
		 * function was called.
		 * 2) Calculate "per-unit-staked" ratios.
		 * 3) Multiply each ratio back by its denominator, to reveal the current floor division error.
		 * 4) Store these errors for use in the next correction when this function is called.
		 * 5) Note: static analysis tools complain about this "division before multiplication", however, it is intended.
		 */
		uint256 ETHNumerator = _coll.mul(DECIMAL_PRECISION).add(
			lastETHError_Redistribution[_asset]
		);
		uint256 DCHFDebtNumerator = _debt.mul(DECIMAL_PRECISION).add(
			lastDCHFDebtError_Redistribution[_asset]
		);

		// Get the per-unit-staked terms
		uint256 ETHRewardPerUnitStaked = ETHNumerator.div(totalStakes[_asset]);
		uint256 DCHFDebtRewardPerUnitStaked = DCHFDebtNumerator.div(totalStakes[_asset]);

		lastETHError_Redistribution[_asset] = ETHNumerator.sub(
			ETHRewardPerUnitStaked.mul(totalStakes[_asset])
		);
		lastDCHFDebtError_Redistribution[_asset] = DCHFDebtNumerator.sub(
			DCHFDebtRewardPerUnitStaked.mul(totalStakes[_asset])
		);

		// Add per-unit-staked terms to the running totals
		L_ASSETS[_asset] = L_ASSETS[_asset].add(ETHRewardPerUnitStaked);
		L_DCHFDebts[_asset] = L_DCHFDebts[_asset].add(DCHFDebtRewardPerUnitStaked);

		emit LTermsUpdated(_asset, L_ASSETS[_asset], L_DCHFDebts[_asset]);

		_activePool.decreaseDCHFDebt(_asset, _debt);
		_defaultPool.increaseDCHFDebt(_asset, _debt);
		_activePool.sendAsset(_asset, address(_defaultPool), _coll);
	}

	function closeTrove(address _asset, address _borrower)
		external
		override
		onlyBorrowerOperations
	{
		return _closeTrove(_asset, _borrower, Status.closedByOwner);
	}

	function closeTrove(
		address _asset,
		address _borrower,
		Status closedStatus
	) external override onlyTroveManager {
		_closeTrove(_asset, _borrower, closedStatus);
	}

	function _closeTrove(
		// access control
		address _asset,
		address _borrower,
		Status closedStatus
	) internal {
		assert(closedStatus != Status.nonExistent && closedStatus != Status.active);

		uint256 TroveOwnersArrayLength = TroveOwners[_asset].length;
		_requireMoreThanOneTroveInSystem(_asset, TroveOwnersArrayLength);

		Troves[_borrower][_asset].status = closedStatus;
		Troves[_borrower][_asset].coll = 0;
		Troves[_borrower][_asset].debt = 0;

		rewardSnapshots[_borrower][_asset].asset = 0;
		rewardSnapshots[_borrower][_asset].DCHFDebt = 0;

		_removeTroveOwner(_asset, _borrower, TroveOwnersArrayLength);
		sortedTroves.remove(_asset, _borrower);
	}

	function updateSystemSnapshots_excludeCollRemainder(
		address _asset,
		IActivePool _activePool,
		uint256 _collRemainder
	) external override onlyTroveManager {
		_updateSystemSnapshots_excludeCollRemainder(_asset, _activePool, _collRemainder);
	}

	function _updateSystemSnapshots_excludeCollRemainder(
		address _asset,
		IActivePool _activePool,
		uint256 _collRemainder
	) internal {
		totalStakesSnapshot[_asset] = totalStakes[_asset];

		uint256 activeColl = _activePool.getAssetBalance(_asset);
		uint256 liquidatedColl = dfrancParams.defaultPool().getAssetBalance(_asset);
		totalCollateralSnapshot[_asset] = activeColl.sub(_collRemainder).add(liquidatedColl);

		emit SystemSnapshotsUpdated(
			_asset,
			totalStakesSnapshot[_asset],
			totalCollateralSnapshot[_asset]
		);
	}

	function addTroveOwnerToArray(address _asset, address _borrower)
		external
		override
		onlyBorrowerOperations
		returns (uint256 index)
	{
		return _addTroveOwnerToArray(_asset, _borrower);
	}

	function _addTroveOwnerToArray(address _asset, address _borrower)
		internal
		returns (uint128 index)
	{
		TroveOwners[_asset].push(_borrower);

		index = uint128(TroveOwners[_asset].length.sub(1));
		Troves[_borrower][_asset].arrayIndex = index;

		return index;
	}

	function _removeTroveOwner(
		address _asset,
		address _borrower,
		uint256 TroveOwnersArrayLength
	) internal {
		Status troveStatus = Troves[_borrower][_asset].status;
		assert(troveStatus != Status.nonExistent && troveStatus != Status.active);

		uint128 index = Troves[_borrower][_asset].arrayIndex;
		uint256 length = TroveOwnersArrayLength;
		uint256 idxLast = length.sub(1);

		assert(index <= idxLast);

		address addressToMove = TroveOwners[_asset][idxLast];

		TroveOwners[_asset][index] = addressToMove;
		Troves[addressToMove][_asset].arrayIndex = index;
		emit TroveIndexUpdated(_asset, addressToMove, index);

		TroveOwners[_asset].pop();
	}

	function getTCR(address _asset, uint256 _price) external view override returns (uint256) {
		return _getTCR(_asset, _price);
	}

	function checkRecoveryMode(address _asset, uint256 _price)
		external
		view
		override
		returns (bool)
	{
		return _checkRecoveryMode(_asset, _price);
	}

	function _checkPotentialRecoveryMode(
		address _asset,
		uint256 _entireSystemColl,
		uint256 _entireSystemDebt,
		uint256 _price
	) public view override returns (bool) {
		uint256 TCR = DfrancMath._computeCR(_entireSystemColl, _entireSystemDebt, _price);

		return TCR < dfrancParams.CCR(_asset);
	}

	function updateBaseRateFromRedemption(
		address _asset,
		uint256 _ETHDrawn,
		uint256 _price,
		uint256 _totalDCHFSupply
	) external override onlyTroveManager returns (uint256) {
		return _updateBaseRateFromRedemption(_asset, _ETHDrawn, _price, _totalDCHFSupply);
	}

	function _updateBaseRateFromRedemption(
		address _asset,
		uint256 _ETHDrawn,
		uint256 _price,
		uint256 _totalDCHFSupply
	) internal returns (uint256) {
		uint256 decayedBaseRate = _calcDecayedBaseRate(_asset);

		uint256 redeemedDCHFFraction = _ETHDrawn.mul(_price).div(_totalDCHFSupply);

		uint256 newBaseRate = decayedBaseRate.add(redeemedDCHFFraction.div(BETA));
		newBaseRate = DfrancMath._min(newBaseRate, DECIMAL_PRECISION);
		assert(newBaseRate > 0);

		baseRate[_asset] = newBaseRate;
		emit BaseRateUpdated(_asset, newBaseRate);

		_updateLastFeeOpTime(_asset);

		return newBaseRate;
	}

	function getRedemptionRate(address _asset) public view override returns (uint256) {
		return _calcRedemptionRate(_asset, baseRate[_asset]);
	}

	function getRedemptionRateWithDecay(address _asset) public view override returns (uint256) {
		return _calcRedemptionRate(_asset, _calcDecayedBaseRate(_asset));
	}

	function _calcRedemptionRate(address _asset, uint256 _baseRate)
		internal
		view
		returns (uint256)
	{
		return
			DfrancMath._min(
				dfrancParams.REDEMPTION_FEE_FLOOR(_asset).add(_baseRate),
				DECIMAL_PRECISION
			);
	}

	function _getRedemptionFee(address _asset, uint256 _assetDraw)
		public
		view
		override
		returns (uint256)
	{
		return _calcRedemptionFee(getRedemptionRate(_asset), _assetDraw);
	}

	function getRedemptionFeeWithDecay(address _asset, uint256 _assetDraw)
		external
		view
		override
		returns (uint256)
	{
		return _calcRedemptionFee(getRedemptionRateWithDecay(_asset), _assetDraw);
	}

	function _calcRedemptionFee(uint256 _redemptionRate, uint256 _assetDraw)
		internal
		pure
		returns (uint256)
	{
		uint256 redemptionFee = _redemptionRate.mul(_assetDraw).div(DECIMAL_PRECISION);
		require(redemptionFee < _assetDraw, "FE");
		return redemptionFee;
	}

	function getBorrowingRate(address _asset) public view override returns (uint256) {
		return _calcBorrowingRate(_asset, baseRate[_asset]);
	}

	function getBorrowingRateWithDecay(address _asset) public view override returns (uint256) {
		return _calcBorrowingRate(_asset, _calcDecayedBaseRate(_asset));
	}

	function _calcBorrowingRate(address _asset, uint256 _baseRate)
		internal
		view
		returns (uint256)
	{
		return
			DfrancMath._min(
				dfrancParams.BORROWING_FEE_FLOOR(_asset).add(_baseRate),
				dfrancParams.MAX_BORROWING_FEE(_asset)
			);
	}

	function getBorrowingFee(address _asset, uint256 _DCHFDebt)
		external
		view
		override
		returns (uint256)
	{
		return _calcBorrowingFee(getBorrowingRate(_asset), _DCHFDebt);
	}

	function getBorrowingFeeWithDecay(address _asset, uint256 _DCHFDebt)
		external
		view
		returns (uint256)
	{
		return _calcBorrowingFee(getBorrowingRateWithDecay(_asset), _DCHFDebt);
	}

	function _calcBorrowingFee(uint256 _borrowingRate, uint256 _DCHFDebt)
		internal
		pure
		returns (uint256)
	{
		return _borrowingRate.mul(_DCHFDebt).div(DECIMAL_PRECISION);
	}

	function decayBaseRateFromBorrowing(address _asset)
		external
		override
		onlyBorrowerOperations
	{
		uint256 decayedBaseRate = _calcDecayedBaseRate(_asset);
		assert(decayedBaseRate <= DECIMAL_PRECISION);

		baseRate[_asset] = decayedBaseRate;
		emit BaseRateUpdated(_asset, decayedBaseRate);

		_updateLastFeeOpTime(_asset);
	}

	// Update the last fee operation time only if time passed >= decay interval. This prevents base rate griefing.
	function _updateLastFeeOpTime(address _asset) internal {
		uint256 timePassed = block.timestamp.sub(lastFeeOperationTime[_asset]);

		if (timePassed >= SECONDS_IN_ONE_MINUTE) {
			lastFeeOperationTime[_asset] = block.timestamp;
			emit LastFeeOpTimeUpdated(_asset, block.timestamp);
		}
	}

	function _calcDecayedBaseRate(address _asset) public view returns (uint256) {
		uint256 minutesPassed = _minutesPassedSinceLastFeeOp(_asset);
		uint256 decayFactor = DfrancMath._decPow(MINUTE_DECAY_FACTOR, minutesPassed);

		return baseRate[_asset].mul(decayFactor).div(DECIMAL_PRECISION);
	}

	function _minutesPassedSinceLastFeeOp(address _asset) internal view returns (uint256) {
		return (block.timestamp.sub(lastFeeOperationTime[_asset])).div(SECONDS_IN_ONE_MINUTE);
	}

	function _requireDCHFBalanceCoversRedemption(
		IDCHFToken _dchfToken,
		address _redeemer,
		uint256 _amount
	) public view override {
		require(_dchfToken.balanceOf(_redeemer) >= _amount, "RR");
	}

	function _requireMoreThanOneTroveInSystem(address _asset, uint256 TroveOwnersArrayLength)
		internal
		view
	{
		require(TroveOwnersArrayLength > 1 && sortedTroves.getSize(_asset) > 1, "OO");
	}

	function _requireAmountGreaterThanZero(uint256 _amount) public pure override {
		require(_amount > 0, "AG");
	}

	function _requireTCRoverMCR(address _asset, uint256 _price) external view override {
		require(_getTCR(_asset, _price) >= dfrancParams.MCR(_asset), "CR");
	}

	function _requireValidMaxFeePercentage(address _asset, uint256 _maxFeePercentage)
		public
		view
		override
	{
		require(
			_maxFeePercentage >= dfrancParams.REDEMPTION_FEE_FLOOR(_asset) &&
				_maxFeePercentage <= DECIMAL_PRECISION,
			"MF"
		);
	}

	function isTroveActive(address _asset, address _borrower)
		public
		view
		override
		returns (bool)
	{
		return this.getTroveStatus(_asset, _borrower) == uint256(Status.active);
	}

	// --- Trove owners getters ---

	function getTroveOwnersCount(address _asset) external view override returns (uint256) {
		return TroveOwners[_asset].length;
	}

	function getTroveFromTroveOwnersArray(address _asset, uint256 _index)
		external
		view
		override
		returns (address)
	{
		return TroveOwners[_asset][_index];
	}

	// --- Trove property getters ---

	function getTrove(address _asset, address _borrower)
		external
		view
		override
		returns (
			address,
			uint256,
			uint256,
			uint256,
			Status,
			uint128
		)
	{
		Trove memory _trove = Troves[_borrower][_asset];
		return (
			_trove.asset,
			_trove.debt,
			_trove.coll,
			_trove.stake,
			_trove.status,
			_trove.arrayIndex
		);
	}

	function getTroveStatus(address _asset, address _borrower)
		external
		view
		override
		returns (uint256)
	{
		return uint256(Troves[_borrower][_asset].status);
	}

	function getTroveStake(address _asset, address _borrower)
		external
		view
		override
		returns (uint256)
	{
		return Troves[_borrower][_asset].stake;
	}

	function getTroveDebt(address _asset, address _borrower)
		external
		view
		override
		returns (uint256)
	{
		return Troves[_borrower][_asset].debt;
	}

	function getTroveColl(address _asset, address _borrower)
		external
		view
		override
		returns (uint256)
	{
		return Troves[_borrower][_asset].coll;
	}

	// --- Trove property setters, called by TroveManager ---
	function setTroveDeptAndColl(
		address _asset,
		address _borrower,
		uint256 _debt,
		uint256 _coll
	) external override onlyTroveManager {
		Troves[_borrower][_asset].debt = _debt;
		Troves[_borrower][_asset].coll = _coll;
	}

	// --- Trove property setters, called by BorrowerOperations ---

	function setTroveStatus(
		address _asset,
		address _borrower,
		uint256 _num
	) external override onlyBorrowerOperations {
		Troves[_borrower][_asset].asset = _asset;
		Troves[_borrower][_asset].status = Status(_num);
	}

	function decreaseTroveColl(
		address _asset,
		address _borrower,
		uint256 _collDecrease
	) external override onlyBorrowerOperations returns (uint256) {
		uint256 newColl = Troves[_borrower][_asset].coll.sub(_collDecrease);
		Troves[_borrower][_asset].coll = newColl;
		return newColl;
	}

	function increaseTroveDebt(
		address _asset,
		address _borrower,
		uint256 _debtIncrease
	) external override onlyBorrowerOperations returns (uint256) {
		uint256 newDebt = Troves[_borrower][_asset].debt.add(_debtIncrease);
		Troves[_borrower][_asset].debt = newDebt;
		return newDebt;
	}

	function decreaseTroveDebt(
		address _asset,
		address _borrower,
		uint256 _debtDecrease
	) external override onlyBorrowerOperations returns (uint256) {
		uint256 newDebt = Troves[_borrower][_asset].debt.sub(_debtDecrease);
		Troves[_borrower][_asset].debt = newDebt;
		return newDebt;
	}

	function increaseTroveColl(
		address _asset,
		address _borrower,
		uint256 _collIncrease
	) external override onlyBorrowerOperations returns (uint256) {
		uint256 newColl = Troves[_borrower][_asset].coll.add(_collIncrease);
		Troves[_borrower][_asset].coll = newColl;
		return newColl;
	}

	function movePendingTroveRewardsToActivePool(
		address _asset,
		IActivePool _activePool,
		IDefaultPool _defaultPool,
		uint256 _DCHF,
		uint256 _amount
	) external override onlyTroveManager {
		_movePendingTroveRewardsToActivePool(_asset, _activePool, _defaultPool, _DCHF, _amount);
	}

	// Move a Trove's pending debt and collateral rewards from distributions, from the Default Pool to the Active Pool
	function _movePendingTroveRewardsToActivePool(
		address _asset,
		IActivePool _activePool,
		IDefaultPool _defaultPool,
		uint256 _DCHF,
		uint256 _amount
	) internal {
		_defaultPool.decreaseDCHFDebt(_asset, _DCHF);
		_activePool.increaseDCHFDebt(_asset, _DCHF);
		_defaultPool.sendAssetToActivePool(_asset, _amount);
	}

	function getRewardSnapshots(address _asset, address _troveOwner)
		external
		view
		override
		returns (uint256 asset, uint256 DCHFDebt)
	{
		RewardSnapshot memory _rewardSnapshot = rewardSnapshots[_asset][_troveOwner];
		return (_rewardSnapshot.asset, _rewardSnapshot.DCHFDebt);
	}
}
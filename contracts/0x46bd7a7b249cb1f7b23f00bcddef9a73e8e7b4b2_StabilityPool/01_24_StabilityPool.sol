// SPDX-License-Identifier: MIT

pragma solidity ^0.8.17;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import './Interfaces/IBorrowerOperations.sol';
import './Interfaces/IStabilityPool.sol';
import './Interfaces/IBorrowerOperations.sol';
import './Interfaces/ITroveManager.sol';
import './Interfaces/ITHUSDToken.sol';
import './Interfaces/ISortedTroves.sol';
import "./Dependencies/LiquityBase.sol";
import "./Dependencies/Ownable.sol";
import "./Dependencies/CheckContract.sol";
import "./Dependencies/SendCollateral.sol";

/*
 * The Stability Pool holds THUSD tokens deposited by Stability Pool depositors.
 *
 * When a trove is liquidated, then depending on system conditions, some of its THUSD debt gets offset with
 * THUSD in the Stability Pool:  that is, the offset debt evaporates, and an equal amount of THUSD tokens in the Stability Pool is burned.
 *
 * Thus, a liquidation causes each depositor to receive a THUSD loss, in proportion to their deposit as a share of total deposits.
 * They also receive a collateral gain, as the collateral of the liquidated trove is distributed among Stability depositors,
 * in the same proportion.
 *
 * When a liquidation occurs, it depletes every deposit by the same fraction: for example, a liquidation that depletes 40%
 * of the total THUSD in the Stability Pool, depletes 40% of each deposit.
 *
 * A deposit that has experienced a series of liquidations is termed a "compounded deposit": each liquidation depletes the deposit,
 * multiplying it by some factor in range ]0,1[
 *
 *
 * --- IMPLEMENTATION ---
 *
 * We use a highly scalable method of tracking deposits and collateral gains that has O(1) complexity.
 *
 * When a liquidation occurs, rather than updating each depositor's deposit and collateral gain, we simply update two state variables:
 * a product P, and a sum S.
 *
 * A mathematical manipulation allows us to factor out the initial deposit, and accurately track all depositors' compounded deposits
 * and accumulated collateral gains over time, as liquidations occur, using just these two variables P and S. When depositors join the
 * Stability Pool, they get a snapshot of the latest P and S: P_t and S_t, respectively.
 *
 * The formula for a depositor's accumulated collateral gain is derived here:
 * https://github.com/liquity/dev/blob/main/packages/contracts/mathProofs/Scalable%20Compounding%20Stability%20Pool%20Deposits.pdf
 *
 * For a given deposit d_t, the ratio P/P_t tells us the factor by which a deposit has decreased since it joined the Stability Pool,
 * and the term d_t * (S - S_t)/P_t gives us the deposit's total accumulated collateral gain.
 *
 * Each liquidation updates the product P and sum S. After a series of liquidations, a compounded deposit and corresponding collateral gain
 * can be calculated using the initial deposit, the depositor’s snapshots of P and S, and the latest values of P and S.
 *
 * Any time a depositor updates their deposit (withdrawal, top-up) their accumulated collateral gain is paid out, their new deposit is recorded
 * (based on their latest compounded deposit and modified by the withdrawal/top-up), and they receive new snapshots of the latest P and S.
 * Essentially, they make a fresh deposit that overwrites the old one.
 *
 *
 * --- SCALE FACTOR ---
 *
 * Since P is a running product in range ]0,1] that is always-decreasing, it should never reach 0 when multiplied by a number in range ]0,1[.
 * Unfortunately, Solidity floor division always reaches 0, sooner or later.
 *
 * A series of liquidations that nearly empty the Pool (and thus each multiply P by a very small number in range ]0,1[ ) may push P
 * to its 18 digit decimal limit, and round it to 0, when in fact the Pool hasn't been emptied: this would break deposit tracking.
 *
 * So, to track P accurately, we use a scale factor: if a liquidation would cause P to decrease to <1e-9 (and be rounded to 0 by Solidity),
 * we first multiply P by 1e9, and increment a currentScale factor by 1.
 *
 * The added benefit of using 1e9 for the scale factor (rather than 1e18) is that it ensures negligible precision loss close to the
 * scale boundary: when P is at its minimum value of 1e9, the relative precision loss in P due to floor division is only on the
 * order of 1e-9.
 *
 * --- EPOCHS ---
 *
 * Whenever a liquidation fully empties the Stability Pool, all deposits should become 0. However, setting P to 0 would make P be 0
 * forever, and break all future reward calculations.
 *
 * So, every time the Stability Pool is emptied by a liquidation, we reset P = 1 and currentScale = 0, and increment the currentEpoch by 1.
 *
 * --- TRACKING DEPOSIT OVER SCALE CHANGES AND EPOCHS ---
 *
 * When a deposit is made, it gets snapshots of the currentEpoch and the currentScale.
 *
 * When calculating a compounded deposit, we compare the current epoch to the deposit's epoch snapshot. If the current epoch is newer,
 * then the deposit was present during a pool-emptying liquidation, and necessarily has been depleted to 0.
 *
 * Otherwise, we then compare the current scale to the deposit's scale snapshot. If they're equal, the compounded deposit is given by d_t * P/P_t.
 * If it spans one scale change, it is given by d_t * P/(P_t * 1e9). If it spans more than one scale change, we define the compounded deposit
 * as 0, since it is now less than 1e-9'th of its initial value (e.g. a deposit of 1 billion THUSD has depleted to < 1 THUSD).
 *
 *
 *  --- TRACKING DEPOSITOR'S collateral GAIN OVER SCALE CHANGES AND EPOCHS ---
 *
 * In the current epoch, the latest value of S is stored upon each scale change, and the mapping (scale -> S) is stored for each epoch.
 *
 * This allows us to calculate a deposit's accumulated collateral gain, during the epoch in which the deposit was non-zero and earned collateral.
 *
 * We calculate the depositor's accumulated collateral gain for the scale at which they made the deposit, using the collateral gain formula:
 * e_1 = d_t * (S - S_t) / P_t
 *
 * and also for scale after, taking care to divide the latter by a factor of 1e9:
 * e_2 = d_t * S / (P_t * 1e9)
 *
 * The gain in the second scale will be full, as the starting point was in the previous scale, thus no need to subtract anything.
 * The deposit therefore was present for reward events from the beginning of that second scale.
 *
 *        S_i-S_t + S_{i+1}
 *      .<--------.------------>
 *      .         .
 *      . S_i     .   S_{i+1}
 *   <--.-------->.<----------->
 *   S_t.         .
 *   <->.         .
 *      t         .
 *  |---+---------|-------------|-----...
 *         i            i+1
 *
 * The sum of (e_1 + e_2) captures the depositor's total accumulated collateral gain, handling the case where their
 * deposit spanned one scale change. We only care about gains across one scale change, since the compounded
 * deposit is defined as being 0 once it has spanned more than one scale change.
 *
 *
 * --- UPDATING P WHEN A LIQUIDATION OCCURS ---
 *
 * Please see the implementation spec in the proof document, which closely follows on from the compounded deposit / collateral gain derivations:
 * https://github.com/liquity/liquity/blob/master/papers/Scalable_Reward_Distribution_with_Compounding_Stakes.pdf
 *
 */
contract StabilityPool is LiquityBase, Ownable, CheckContract, SendCollateral, IStabilityPool {

    string constant public NAME = "StabilityPool";

    address public collateralAddress;

    IBorrowerOperations public borrowerOperations;

    ITroveManager public troveManager;

    ITHUSDToken public thusdToken;

    // Needed to check if there are pending liquidations
    ISortedTroves public sortedTroves;

    uint256 internal collateral;  // deposited collateral tracker

    // Tracker for THUSD held in the pool. Changes when users deposit/withdraw, and when Trove debt is offset.
    uint256 internal totalTHUSDDeposits;

   // --- Data structures ---

    struct Snapshots {
        uint256 S;
        uint256 P;
        uint128 scale;
        uint128 epoch;
    }

    mapping (address => uint256) public deposits;  // depositor address -> initial value
    mapping (address => Snapshots) public depositSnapshots;  // depositor address -> snapshots struct

    /*  Product 'P': Running product by which to multiply an initial deposit, in order to find the current compounded deposit,
    * after a series of liquidations have occurred, each of which cancel some THUSD debt with the deposit.
    *
    * During its lifetime, a deposit's value evolves from d_t to d_t * P / P_t , where P_t
    * is the snapshot of P taken at the instant the deposit was made. 18-digit decimal.
    */
    uint256 public P = DECIMAL_PRECISION;

    uint256 public constant SCALE_FACTOR = 1e9;

    // Each time the scale of P shifts by SCALE_FACTOR, the scale is incremented by 1
    uint128 public currentScale;

    // With each offset that fully empties the Pool, the epoch is incremented by 1
    uint128 public currentEpoch;

    /* collateral Gain sum 'S': During its lifetime, each deposit d_t earns an collateral gain of ( d_t * [S - S_t] )/P_t, where S_t
    * is the depositor's snapshot of S taken at the time t when the deposit was made.
    *
    * The 'S' sums are stored in a nested mapping (epoch => scale => sum):
    *
    * - The inner mapping records the sum S at different scales
    * - The outer mapping records the (scale => sum) mappings, for different epochs.
    */
    mapping (uint128 => mapping(uint128 => uint)) public epochToScaleToSum;

    // Error trackers for the error correction in the offset calculation
    uint256 public lastCollateralError_Offset;
    uint256 public lastTHUSDLossError_Offset;

    // --- Contract setters ---

    function setAddresses(
        address _borrowerOperationsAddress,
        address _troveManagerAddress,
        address _activePoolAddress,
        address _thusdTokenAddress,
        address _sortedTrovesAddress,
        address _priceFeedAddress,
        address _collateralAddress
    )
        external
        override
        onlyOwner
    {
        checkContract(_borrowerOperationsAddress);
        checkContract(_troveManagerAddress);
        checkContract(_activePoolAddress);
        checkContract(_thusdTokenAddress);
        checkContract(_sortedTrovesAddress);
        checkContract(_priceFeedAddress);
        if (_collateralAddress != address(0)) {
            checkContract(_collateralAddress);
        }

        borrowerOperations = IBorrowerOperations(_borrowerOperationsAddress);
        troveManager = ITroveManager(_troveManagerAddress);
        activePool = IActivePool(_activePoolAddress);
        thusdToken = ITHUSDToken(_thusdTokenAddress);
        sortedTroves = ISortedTroves(_sortedTrovesAddress);
        priceFeed = IPriceFeed(_priceFeedAddress);
        collateralAddress = _collateralAddress;
        
        require(
            (Ownable(_borrowerOperationsAddress).owner() != address(0) || 
            borrowerOperations.collateralAddress() == _collateralAddress) &&
            (Ownable(_activePoolAddress).owner() != address(0) || 
            activePool.collateralAddress() == _collateralAddress),
            "The same collateral address must be used for the entire set of contracts"
        );

        emit BorrowerOperationsAddressChanged(_borrowerOperationsAddress);
        emit TroveManagerAddressChanged(_troveManagerAddress);
        emit ActivePoolAddressChanged(_activePoolAddress);
        emit THUSDTokenAddressChanged(_thusdTokenAddress);
        emit SortedTrovesAddressChanged(_sortedTrovesAddress);
        emit PriceFeedAddressChanged(_priceFeedAddress);
        emit CollateralAddressChanged(_collateralAddress);

        _renounceOwnership();
    }

    // --- Getters for public variables. Required by IPool interface ---

    function getCollateralBalance() external view override returns (uint) {
        return collateral;
    }

    function getTotalTHUSDDeposits() external view override returns (uint) {
        return totalTHUSDDeposits;
    }

    // --- External Depositor Functions ---

    /*  provideToSP():
     *
     * - Sends depositor's accumulated gains (collateral) to depositor
     */
    function provideToSP(uint256 _amount) external override {
        _requireNonZeroAmount(_amount);

        uint256 initialDeposit = deposits[msg.sender];

        uint256 depositorCollateralGain = getDepositorCollateralGain(msg.sender);
        uint256 compoundedTHUSDDeposit = getCompoundedTHUSDDeposit(msg.sender);
        uint256 THUSDLoss = initialDeposit - compoundedTHUSDDeposit; // Needed only for event log

        _sendTHUSDtoStabilityPool(msg.sender, _amount);

        uint256 newDeposit = compoundedTHUSDDeposit + _amount;
        _updateDepositAndSnapshots(msg.sender, newDeposit);
        emit UserDepositChanged(msg.sender, newDeposit);

        emit CollateralGainWithdrawn(msg.sender, depositorCollateralGain, THUSDLoss); // THUSD Loss required for event log

        _sendCollateralGainToDepositor(depositorCollateralGain);
     }

    /*  withdrawFromSP():
    *
    * - Sends all depositor's accumulated gains (collateral) to depositor
    *
    * If _amount > userDeposit, the user withdraws all of their compounded deposit.
    */
    function withdrawFromSP(uint256 _amount) external override {
        if (_amount !=0) {_requireNoUnderCollateralizedTroves();}
        uint256 initialDeposit = deposits[msg.sender];
        _requireUserHasDeposit(initialDeposit);

        uint256 depositorCollateralGain = getDepositorCollateralGain(msg.sender);

        uint256 compoundedTHUSDDeposit = getCompoundedTHUSDDeposit(msg.sender);
        uint256 THUSDtoWithdraw = LiquityMath._min(_amount, compoundedTHUSDDeposit);
        uint256 THUSDLoss = initialDeposit - compoundedTHUSDDeposit; // Needed only for event log

        _sendTHUSDToDepositor(msg.sender, THUSDtoWithdraw);

        // Update deposit
        uint256 newDeposit = compoundedTHUSDDeposit - THUSDtoWithdraw;
        _updateDepositAndSnapshots(msg.sender, newDeposit);
        emit UserDepositChanged(msg.sender, newDeposit);

        emit CollateralGainWithdrawn(msg.sender, depositorCollateralGain, THUSDLoss);  // THUSD Loss required for event log

        _sendCollateralGainToDepositor(depositorCollateralGain);
    }

    /* withdrawCollateralGainToTrove:
    * - Transfers the depositor's entire collateral gain from the Stability Pool to the caller's trove
    * - Leaves their compounded deposit in the Stability Pool
    * - Updates snapshots for deposit */
    function withdrawCollateralGainToTrove(address _upperHint, address _lowerHint) external override {
        uint256 initialDeposit = deposits[msg.sender];
        _requireUserHasDeposit(initialDeposit);
        _requireUserHasTrove(msg.sender);
        _requireUserHasCollateralGain(msg.sender);

        uint256 depositorCollateralGain = getDepositorCollateralGain(msg.sender);

        uint256 compoundedTHUSDDeposit = getCompoundedTHUSDDeposit(msg.sender);
        uint256 THUSDLoss = initialDeposit - compoundedTHUSDDeposit; // Needed only for event log

        _updateDepositAndSnapshots(msg.sender, compoundedTHUSDDeposit);

        /* Emit events before transferring collateral gain to Trove.
         This lets the event log make more sense (i.e. so it appears that first the collateral gain is withdrawn
        and then it is deposited into the Trove, not the other way around). */
        emit CollateralGainWithdrawn(msg.sender, depositorCollateralGain, THUSDLoss);
        emit UserDepositChanged(msg.sender, compoundedTHUSDDeposit);

        collateral -= depositorCollateralGain;
        emit StabilityPoolCollateralBalanceUpdated(collateral);
        emit CollateralSent(msg.sender, depositorCollateralGain);

        if (collateralAddress == address(0)) {
          borrowerOperations.moveCollateralGainToTrove{ value: depositorCollateralGain }(msg.sender, 0, _upperHint, _lowerHint);
        } else {
          borrowerOperations.moveCollateralGainToTrove{ value: 0 }(msg.sender, depositorCollateralGain, _upperHint, _lowerHint);
        }
    }

    // --- Liquidation functions ---

    /*
    * Cancels out the specified debt against the THUSD contained in the Stability Pool (as far as possible)
    * and transfers the Trove's collateral from ActivePool to StabilityPool.
    * Only called by liquidation functions in the TroveManager.
    */
    function offset(uint256 _debtToOffset, uint256 _collToAdd) external override {
        _requireCallerIsTroveManager();
        uint256 totalTHUSD = totalTHUSDDeposits; // cached to save an SLOAD
        if (totalTHUSD == 0 || _debtToOffset == 0) { return; }

        (uint256 collateralGainPerUnitStaked,
            uint256 THUSDLossPerUnitStaked) = _computeRewardsPerUnitStaked(_collToAdd, _debtToOffset, totalTHUSD);

        _updateRewardSumAndProduct(collateralGainPerUnitStaked, THUSDLossPerUnitStaked);  // updates S and P

        _moveOffsetCollAndDebt(_collToAdd, _debtToOffset);
    }

    // --- Offset helper functions ---

    function _computeRewardsPerUnitStaked(
        uint256 _collToAdd,
        uint256 _debtToOffset,
        uint256 _totalTHUSDDeposits
    )
        internal
        returns (uint256 collateralGainPerUnitStaked, uint256 THUSDLossPerUnitStaked)
    {
        /*
        * Compute the THUSD and collateral rewards. Uses a "feedback" error correction, to keep
        * the cumulative error in the P and S state variables low:
        *
        * 1) Form numerators which compensate for the floor division errors that occurred the last time this
        * function was called.
        * 2) Calculate "per-unit-staked" ratios.
        * 3) Multiply each ratio back by its denominator, to reveal the current floor division error.
        * 4) Store these errors for use in the next correction when this function is called.
        * 5) Note: static analysis tools complain about this "division before multiplication", however, it is intended.
        */
        uint256 collateralNumerator = _collToAdd * DECIMAL_PRECISION + lastCollateralError_Offset;

        assert(_debtToOffset <= _totalTHUSDDeposits);
        if (_debtToOffset == _totalTHUSDDeposits) {
            THUSDLossPerUnitStaked = DECIMAL_PRECISION;  // When the Pool depletes to 0, so does each deposit
            lastTHUSDLossError_Offset = 0;
        } else {
            uint256 THUSDLossNumerator = _debtToOffset * DECIMAL_PRECISION - lastTHUSDLossError_Offset;
            /*
            * Add 1 to make error in quotient positive. We want "slightly too much" THUSD loss,
            * which ensures the error in any given compoundedTHUSDDeposit favors the Stability Pool.
            */
            THUSDLossPerUnitStaked = THUSDLossNumerator / _totalTHUSDDeposits + 1;
            lastTHUSDLossError_Offset = THUSDLossPerUnitStaked * _totalTHUSDDeposits - THUSDLossNumerator;
        }

        collateralGainPerUnitStaked = collateralNumerator / _totalTHUSDDeposits;
        lastCollateralError_Offset = collateralNumerator - (collateralGainPerUnitStaked * _totalTHUSDDeposits);

        return (collateralGainPerUnitStaked, THUSDLossPerUnitStaked);
    }

    // Update the Stability Pool reward sum S and product P
    function _updateRewardSumAndProduct(uint256 _collateralGainPerUnitStaked, uint256 _THUSDLossPerUnitStaked) internal {
        uint256 currentP = P;
        uint256 newP;

        assert(_THUSDLossPerUnitStaked <= DECIMAL_PRECISION);
        /*
        * The newProductFactor is the factor by which to change all deposits, due to the depletion of Stability Pool THUSD in the liquidation.
        * We make the product factor 0 if there was a pool-emptying. Otherwise, it is (1 - THUSDLossPerUnitStaked)
        */
        uint256 newProductFactor = DECIMAL_PRECISION - _THUSDLossPerUnitStaked;

        uint128 currentScaleCached = currentScale;
        uint128 currentEpochCached = currentEpoch;
        uint256 currentS = epochToScaleToSum[currentEpochCached][currentScaleCached];

        /*
        * Calculate the new S first, before we update P.
        * The collateral gain for any given depositor from a liquidation depends on the value of their deposit
        * (and the value of totalDeposits) prior to the Stability being depleted by the debt in the liquidation.
        *
        * Since S corresponds to collateral gain, and P to deposit loss, we update S first.
        */
        uint256 marginalCollateralGain = _collateralGainPerUnitStaked * currentP;
        uint256 newS = currentS + marginalCollateralGain;
        epochToScaleToSum[currentEpochCached][currentScaleCached] = newS;
        emit S_Updated(newS, currentEpochCached, currentScaleCached);

        // If the Stability Pool was emptied, increment the epoch, and reset the scale and product P
        if (newProductFactor == 0) {
            currentEpoch = currentEpochCached + 1;
            emit EpochUpdated(currentEpoch);
            currentScale = 0;
            emit ScaleUpdated(currentScale);
            newP = DECIMAL_PRECISION;

        // If multiplying P by a non-zero product factor would reduce P below the scale boundary, increment the scale
        } else if (currentP * newProductFactor / DECIMAL_PRECISION < SCALE_FACTOR) {
            newP = currentP * newProductFactor * SCALE_FACTOR / DECIMAL_PRECISION;
            currentScale = currentScaleCached + 1;
            emit ScaleUpdated(currentScale);
        } else {
            newP = currentP * newProductFactor / DECIMAL_PRECISION;
        }

        assert(newP > 0);
        P = newP;

        emit P_Updated(newP);
    }

    function _moveOffsetCollAndDebt(uint256 _collToAdd, uint256 _debtToOffset) internal {
        IActivePool activePoolCached = activePool;

        // Cancel the liquidated THUSD debt with the THUSD in the stability pool
        activePoolCached.decreaseTHUSDDebt(_debtToOffset);
        _decreaseTHUSD(_debtToOffset);

        // Burn the debt that was successfully offset
        thusdToken.burn(address(this), _debtToOffset);

        activePoolCached.sendCollateral(address(this), _collToAdd);
    }

    function _decreaseTHUSD(uint256 _amount) internal {
        uint256 newTotalTHUSDDeposits = totalTHUSDDeposits - _amount;
        totalTHUSDDeposits = newTotalTHUSDDeposits;
        emit StabilityPoolTHUSDBalanceUpdated(newTotalTHUSDDeposits);
    }

    // --- Reward calculator functions for depositor ---

    /* Calculates the collateral gain earned by the deposit since its last snapshots were taken.
    * Given by the formula:  E = d0 * (S - S(0))/P(0)
    * where S(0) and P(0) are the depositor's snapshots of the sum S and product P, respectively.
    * d0 is the last recorded deposit value.
    */
    function getDepositorCollateralGain(address _depositor) public view override returns (uint) {
        uint256 initialDeposit = deposits[_depositor];

        if (initialDeposit == 0) { return 0; }

        Snapshots memory snapshots = depositSnapshots[_depositor];

        uint256 collateralGain = _getCollateralGainFromSnapshots(initialDeposit, snapshots);
        return collateralGain;
    }

    function _getCollateralGainFromSnapshots(uint256 initialDeposit, Snapshots memory snapshots) internal view returns (uint) {
        /*
        * Grab the sum 'S' from the epoch at which the stake was made. The collateral gain may span up to one scale change.
        * If it does, the second portion of the collateral gain is scaled by 1e9.
        * If the gain spans no scale change, the second portion will be 0.
        */
        uint128 epochSnapshot = snapshots.epoch;
        uint128 scaleSnapshot = snapshots.scale;
        uint256 S_Snapshot = snapshots.S;
        uint256 P_Snapshot = snapshots.P;

        uint256 firstPortion = epochToScaleToSum[epochSnapshot][scaleSnapshot] - S_Snapshot;
        uint256 secondPortion = epochToScaleToSum[epochSnapshot][scaleSnapshot + 1] / SCALE_FACTOR;

        uint256 collateralGain = initialDeposit * (firstPortion + secondPortion) / P_Snapshot / DECIMAL_PRECISION;

        return collateralGain;
    }

    // --- Compounded deposit ---

    /*
    * Return the user's compounded deposit. Given by the formula:  d = d0 * P/P(0)
    * where P(0) is the depositor's snapshot of the product P, taken when they last updated their deposit.
    */
    function getCompoundedTHUSDDeposit(address _depositor) public view override returns (uint) {
        uint256 initialDeposit = deposits[_depositor];
        if (initialDeposit == 0) { return 0; }

        Snapshots memory snapshots = depositSnapshots[_depositor];

        uint256 compoundedDeposit = _getCompoundedStakeFromSnapshots(initialDeposit, snapshots);
        return compoundedDeposit;
    }

    // Internal function, used to calculcate compounded deposits.
    function _getCompoundedStakeFromSnapshots(
        uint256 initialStake,
        Snapshots memory snapshots
    )
        internal
        view
        returns (uint)
    {
        uint256 snapshot_P = snapshots.P;
        uint128 scaleSnapshot = snapshots.scale;
        uint128 epochSnapshot = snapshots.epoch;

        // If stake was made before a pool-emptying event, then it has been fully cancelled with debt -- so, return 0
        if (epochSnapshot < currentEpoch) { return 0; }

        uint256 compoundedStake;
        uint128 scaleDiff = currentScale - scaleSnapshot;

        /* Compute the compounded stake. If a scale change in P was made during the stake's lifetime,
        * account for it. If more than one scale change was made, then the stake has decreased by a factor of
        * at least 1e-9 -- so return 0.
        */
        if (scaleDiff == 0) {
            compoundedStake = initialStake * P / snapshot_P;
        } else if (scaleDiff == 1) {
            compoundedStake = initialStake * P / snapshot_P / SCALE_FACTOR;
        } else { // if scaleDiff >= 2
            compoundedStake = 0;
        }

        /*
        * If compounded deposit is less than a billionth of the initial deposit, return 0.
        *
        * NOTE: originally, this line was in place to stop rounding errors making the deposit too large. However, the error
        * corrections should ensure the error in P "favors the Pool", i.e. any given compounded deposit should slightly less
        * than it's theoretical value.
        *
        * Thus it's unclear whether this line is still really needed.
        */
        if (compoundedStake < initialStake / 1e9) {return 0;}

        return compoundedStake;
    }

    // --- Sender functions for THUSD deposit, collateral gains ---

    // Transfer the THUSD tokens from the user to the Stability Pool's address, and update its recorded THUSD
    function _sendTHUSDtoStabilityPool(address _address, uint256 _amount) internal {
        thusdToken.transferFrom(_address, address(this), _amount);
        uint256 newTotalTHUSDDeposits = totalTHUSDDeposits + _amount;
        totalTHUSDDeposits = newTotalTHUSDDeposits;
        emit StabilityPoolTHUSDBalanceUpdated(newTotalTHUSDDeposits);
    }

    function _sendCollateralGainToDepositor(uint256 _amount) internal {
        if (_amount == 0) {return;}
        uint256 newCollateral = collateral - _amount;
        collateral = newCollateral;
        emit StabilityPoolCollateralBalanceUpdated(newCollateral);
        emit CollateralSent(msg.sender, _amount);

        sendCollateral(IERC20(collateralAddress), msg.sender, _amount);
    }

    // Send THUSD to user and decrease THUSD in Pool
    function _sendTHUSDToDepositor(address _depositor, uint256 THUSDWithdrawal) internal {
        if (THUSDWithdrawal == 0) {return;}

        thusdToken.transfer(_depositor, THUSDWithdrawal);
        _decreaseTHUSD(THUSDWithdrawal);
    }

    // --- Stability Pool Deposit Functionality ---

    function _updateDepositAndSnapshots(address _depositor, uint256 _newValue) internal {
        deposits[_depositor] = _newValue;

        if (_newValue == 0) {
            delete depositSnapshots[_depositor];
            emit DepositSnapshotUpdated(_depositor, 0, 0);
            return;
        }
        uint128 currentScaleCached = currentScale;
        uint128 currentEpochCached = currentEpoch;
        uint256 currentP = P;

        // Get S and G for the current epoch and current scale
        uint256 currentS = epochToScaleToSum[currentEpochCached][currentScaleCached];

        // Record new snapshots of the latest running product P, sum S, and sum G, for the depositor
        depositSnapshots[_depositor].P = currentP;
        depositSnapshots[_depositor].S = currentS;
        depositSnapshots[_depositor].scale = currentScaleCached;
        depositSnapshots[_depositor].epoch = currentEpochCached;

        emit DepositSnapshotUpdated(_depositor, currentP, currentS);
    }

    // --- 'require' functions ---

    function _requireCallerIsActivePool() internal view {
        require( msg.sender == address(activePool), "StabilityPool: Caller is not ActivePool");
    }

    function _requireCallerIsTroveManager() internal view {
        require(msg.sender == address(troveManager), "StabilityPool: Caller is not TroveManager");
    }

    function _requireNoUnderCollateralizedTroves() internal {
        uint256 price = priceFeed.fetchPrice();
        address lowestTrove = sortedTroves.getLast();
        uint256 ICR = troveManager.getCurrentICR(lowestTrove, price);
        require(ICR >= MCR, "StabilityPool: Cannot withdraw while there are troves with ICR < MCR");
    }

    function _requireUserHasDeposit(uint256 _initialDeposit) internal pure {
        require(_initialDeposit > 0, 'StabilityPool: User must have a non-zero deposit');
    }

    function _requireNonZeroAmount(uint256 _amount) internal pure {
        require(_amount > 0, 'StabilityPool: Amount must be non-zero');
    }

    function _requireUserHasTrove(address _depositor) internal view {
        require(
            troveManager.getTroveStatus(_depositor) == ITroveManager.Status.active, 
            "StabilityPool: caller must have an active trove to withdraw collateralGain to"
        );
    }

    function _requireUserHasCollateralGain(address _depositor) internal view {
        uint256 collateralGain = getDepositorCollateralGain(_depositor);
        require(collateralGain > 0, "StabilityPool: caller must have non-zero collateral Gain");
    }

    // When ERC20 token collateral is received this function needs to be called
    function updateCollateralBalance(uint256 _amount) external override {
        _requireCallerIsActivePool();
        collateral += _amount;
        emit StabilityPoolCollateralBalanceUpdated(collateral);
  	}

    // --- Fallback function ---

    receive() external payable {
        _requireCallerIsActivePool();
        collateral += msg.value;
        emit StabilityPoolCollateralBalanceUpdated(collateral);
    }
}
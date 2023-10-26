// SPDX-License-Identifier: MIT

pragma solidity ^0.8.17;

/*
 * The Stability Pool holds THUSD tokens deposited by Stability Pool depositors.
 *
 * When a trove is liquidated, then depending on system conditions, some of its THUSD debt gets offset with
 * THUSD in the Stability Pool:  that is, the offset debt evaporates, and an equal amount of THUSD tokens in the Stability Pool is burned.
 *
 * Thus, a liquidation causes each depositor to receive a THUSD loss, in proportion to their deposit as a share of total deposits.
 * They also receive an collateral gain, as the collateral of the liquidated trove is distributed among Stability depositors,
 * in the same proportion.
 *
 * When a liquidation occurs, it depletes every deposit by the same fraction: for example, a liquidation that depletes 40%
 * of the total THUSD in the Stability Pool, depletes 40% of each deposit.
 *
 * A deposit that has experienced a series of liquidations is termed a "compounded deposit": each liquidation depletes the deposit,
 * multiplying it by some factor in range ]0,1[
 *
 * Please see the implementation spec in the proof document, which closely follows on from the compounded deposit / collateral gain derivations:
 * https://github.com/liquity/liquity/blob/master/papers/Scalable_Reward_Distribution_with_Compounding_Stakes.pdf
 *
 */
interface IStabilityPool {

    // --- Events ---

    event StabilityPoolCollateralBalanceUpdated(uint256 _newBalance);
    event StabilityPoolTHUSDBalanceUpdated(uint256 _newBalance);

    event BorrowerOperationsAddressChanged(address _newBorrowerOperationsAddress);
    event TroveManagerAddressChanged(address _newTroveManagerAddress);
    event ActivePoolAddressChanged(address _newActivePoolAddress);
    event DefaultPoolAddressChanged(address _newDefaultPoolAddress);
    event THUSDTokenAddressChanged(address _newTHUSDTokenAddress);
    event SortedTrovesAddressChanged(address _newSortedTrovesAddress);
    event PriceFeedAddressChanged(address _newPriceFeedAddress);
    event CollateralAddressChanged(address _newCollateralAddress);

    event P_Updated(uint256 _P);
    event S_Updated(uint256 _S, uint128 _epoch, uint128 _scale);
    event EpochUpdated(uint128 _currentEpoch);
    event ScaleUpdated(uint128 _currentScale);

    event DepositSnapshotUpdated(address indexed _depositor, uint256 _P, uint256 _S);
    event UserDepositChanged(address indexed _depositor, uint256 _newDeposit);

    event CollateralGainWithdrawn(address indexed _depositor, uint256 _collateral, uint256 _THUSDLoss);
    event CollateralSent(address _to, uint256 _amount);

    // --- Functions ---

    /*
     * Called only once on init, to set addresses of other Liquity contracts
     * Callable only by owner, renounces ownership at the end
     */
    function setAddresses(
        address _borrowerOperationsAddress,
        address _troveManagerAddress,
        address _activePoolAddress,
        address _thusdTokenAddress,
        address _sortedTrovesAddress,
        address _priceFeedAddress,
        address _collateralAddress
    ) external;

    /*
     * Initial checks:
     * - _amount is not zero
     * ---
     * - Sends depositor's accumulated gains (collateral) to depositor
     */
    function provideToSP(uint256 _amount) external;

    /*
     * Initial checks:
     * - _amount is zero or there are no under collateralized troves left in the system
     * - User has a non zero deposit
     * ---
     * - Sends all depositor's accumulated gains (collateral) to depositor
     * - Decreases deposit stake, and takes new snapshot.
     *
     * If _amount > userDeposit, the user withdraws all of their compounded deposit.
     */
    function withdrawFromSP(uint256 _amount) external;

    /*
     * Initial checks:
     * - User has a non zero deposit
     * - User has an open trove
     * - User has some collateral gain
     * ---
     * - Transfers the depositor's entire collateral gain from the Stability Pool to the caller's trove
     * - Leaves their compounded deposit in the Stability Pool
     * - Updates snapshots for deposit
     */
    function withdrawCollateralGainToTrove(address _upperHint, address _lowerHint) external;

    /*
     * Initial checks:
     * - Caller is TroveManager
     * ---
     * Cancels out the specified debt against the THUSD contained in the Stability Pool (as far as possible)
     * and transfers the Trove's collateral from ActivePool to StabilityPool.
     * Only called by liquidation functions in the TroveManager.
     */
    function offset(uint256 _debt, uint256 _coll) external;

    /*
     * Returns the total amount of collateral held by the pool, accounted in an internal variable instead of `balance`,
     * to exclude edge cases like collateral received from a self-destruct.
     */
    function getCollateralBalance() external view returns (uint);

    /*
     * Returns THUSD held in the pool. Changes when users deposit/withdraw, and when Trove debt is offset.
     */
    function getTotalTHUSDDeposits() external view returns (uint);

    /*
     * Calculates the collateral gain earned by the deposit since its last snapshots were taken.
     */
    function getDepositorCollateralGain(address _depositor) external view returns (uint);

    /*
     * Return the user's compounded deposit.
     */
    function getCompoundedTHUSDDeposit(address _depositor) external view returns (uint);

    /*
     * Only callable by Active Pool, updates ERC20 tokens recieved
     */
    function updateCollateralBalance(uint256 _amount) external;
    /*
     * Fallback function
     * Only callable by Active Pool, it just accounts for ETH received
     * receive() external payable;
     */
    
    function collateralAddress() external view returns(address);
}
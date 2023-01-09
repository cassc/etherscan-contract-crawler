// SPDX-License-Identifier: MIT

pragma solidity 0.8.0;

/*
 * The Stability Pool holds ARTH tokens deposited by Stability Pool depositors.
 *
 * When a trove is liquidated, then depending on system conditions, some of its ARTH debt gets offset with
 * ARTH in the Stability Pool:  that is, the offset debt evaporates, and an equal amount of ARTH tokens in the Stability Pool is burned.
 *
 * Thus, a liquidation causes each depositor to receive a ARTH loss, in proportion to their deposit as a share of total deposits.
 * They also receive an ETH gain, as the ETH collateral of the liquidated trove is distributed among Stability depositors,
 * in the same proportion.
 *
 * When a liquidation occurs, it depletes every deposit by the same fraction: for example, a liquidation that depletes 40%
 * of the total ARTH in the Stability Pool, depletes 40% of each deposit.
 *
 * A deposit that has experienced a series of liquidations is termed a "compounded deposit": each liquidation depletes the deposit,
 * multiplying it by some factor in range ]0,1[
 *
 * Please see the implementation spec in the proof document, which closely follows on from the compounded deposit / ETH gain derivations:
 * https://github.com/liquity/liquity/blob/master/papers/Scalable_Reward_Distribution_with_Compounding_Stakes.pdf
 *
 * --- MAHA ISSUANCE TO STABILITY POOL DEPOSITORS ---
 *
 * An MAHA issuance event occurs at every deposit operation, and every liquidation.
 *
 * Each deposit is tagged with the address of the front end through which it was made.
 *
 * All deposits earn a share of the issued MAHA in proportion to the deposit as a share of total deposits. The MAHA earned
 * by a given deposit, is split between the depositor and the front end through which the deposit was made, based on the front end's kickbackRate.
 *
 * Please see the system Readme for an overview:
 * https://github.com/liquity/dev/blob/main/README.md#maha-issuance-to-stability-providers
 */
interface IStabilityPool {
    // --- Events ---

    event StabilityPoolETHBalanceUpdated(uint256 _newBalance);
    event StabilityPoolARTHBalanceUpdated(uint256 _newBalance);

    event BorrowerOperationsAddressChanged(address _newBorrowerOperationsAddress);
    event TroveManagerAddressChanged(address _newTroveManagerAddress);
    event ActivePoolAddressChanged(address _newActivePoolAddress);
    event DefaultPoolAddressChanged(address _newDefaultPoolAddress);
    event ARTHTokenAddressChanged(address _newARTHTokenAddress);
    event SortedTrovesAddressChanged(address _newSortedTrovesAddress);
    event GovernanceAddressChanged(address _newGovernanceAddress);
    event CommunityIssuanceAddressChanged(address _newCommunityIssuanceAddress);

    event P_Updated(uint256 _P);
    event S_Updated(uint256 _S, uint128 _epoch, uint128 _scale);
    event G_Updated(uint256 _G, uint128 _epoch, uint128 _scale);
    event EpochUpdated(uint128 _currentEpoch);
    event ScaleUpdated(uint128 _currentScale);

    event FrontEndRegistered(address indexed _frontEnd, uint256 _kickbackRate);
    event FrontEndTagSet(address indexed _depositor, address indexed _frontEnd);

    event DepositSnapshotUpdated(address indexed _depositor, uint256 _P, uint256 _S, uint256 _G);
    event FrontEndSnapshotUpdated(address indexed _frontEnd, uint256 _P, uint256 _G);
    event UserDepositChanged(address indexed _depositor, uint256 _newDeposit);
    event FrontEndStakeChanged(
        address indexed _frontEnd,
        uint256 _newFrontEndStake,
        address _depositor
    );

    event ETHGainWithdrawn(address indexed _depositor, uint256 _ETH, uint256 _ARTHLoss);
    event MAHAPaidToDepositor(address indexed _depositor, uint256 _MAHA);
    event MAHAPaidToFrontEnd(address indexed _frontEnd, uint256 _MAHA);
    event EtherSent(address _to, uint256 _amount);

    // --- Functions ---

    /*
     * Called only once on init, to set addresses of other Liquity contracts
     * Callable only by owner, renounces ownership at the end
     */
    function setAddresses(
        address _borrowerOperationsAddress,
        address _troveManagerAddress,
        address _activePoolAddress,
        address _arthTokenAddress,
        address _sortedTrovesAddress,
        address _governanceAddress,
        address _communityIssuanceAddress
    ) external;

    /*
     * Initial checks:
     * - Frontend is registered or zero address
     * - Sender is not a registered frontend
     * - _amount is not zero
     * ---
     * - Triggers a MAHA issuance, based on time passed since the last issuance. The MAHA issuance is shared between *all* depositors and front ends
     * - Tags the deposit with the provided front end tag param, if it's a new deposit
     * - Sends depositor's accumulated gains (MAHA, ETH) to depositor
     * - Sends the tagged front end's accumulated MAHA gains to the tagged front end
     * - Increases deposit and tagged front end's stake, and takes new snapshots for each.
     */
    function provideToSP(uint256 _amount, address _frontEndTag) external;

    /*
     * Initial checks:
     * - _amount is zero or there are no under collateralized troves left in the system
     * - User has a non zero deposit
     * ---
     * - Triggers a MAHA issuance, based on time passed since the last issuance. The MAHA issuance is shared between *all* depositors and front ends
     * - Removes the deposit's front end tag if it is a full withdrawal
     * - Sends all depositor's accumulated gains (MAHA, ETH) to depositor
     * - Sends the tagged front end's accumulated MAHA gains to the tagged front end
     * - Decreases deposit and tagged front end's stake, and takes new snapshots for each.
     *
     * If _amount > userDeposit, the user withdraws all of their compounded deposit.
     */
    function withdrawFromSP(uint256 _amount) external;

    /*
     * Initial checks:
     * - User has a non zero deposit
     * - User has an open trove
     * - User has some ETH gain
     * ---
     * - Triggers a MAHA issuance, based on time passed since the last issuance. The MAHA issuance is shared between *all* depositors and front ends
     * - Sends all depositor's MAHA gain to  depositor
     * - Sends all tagged front end's MAHA gain to the tagged front end
     * - Transfers the depositor's entire ETH gain from the Stability Pool to the caller's trove
     * - Leaves their compounded deposit in the Stability Pool
     * - Updates snapshots for deposit and tagged front end stake
     */
    function withdrawETHGainToTrove(address _upperHint, address _lowerHint) external;

    /*
     * Initial checks:
     * - Frontend (sender) not already registered
     * - User (sender) has no deposit
     * - _kickbackRate is in the range [0, 100%]
     * ---
     * Front end makes a one-time selection of kickback rate upon registering
     */
    function registerFrontEnd(uint256 _kickbackRate) external;

    /*
     * Initial checks:
     * - Caller is TroveManager
     * ---
     * Cancels out the specified debt against the ARTH contained in the Stability Pool (as far as possible)
     * and transfers the Trove's ETH collateral from ActivePool to StabilityPool.
     * Only called by liquidation functions in the TroveManager.
     */
    function offset(uint256 _debt, uint256 _coll) external;

    /*
     * Returns the total amount of ETH held by the pool, accounted in an internal variable instead of `balance`,
     * to exclude edge cases like ETH received from a self-destruct.
     */
    function getETH() external view returns (uint256);

    /*
     * Returns ARTH held in the pool. Changes when users deposit/withdraw, and when Trove debt is offset.
     */
    function getTotalARTHDeposits() external view returns (uint256);

    /*
     * Calculates the ETH gain earned by the deposit since its last snapshots were taken.
     */
    function getDepositorETHGain(address _depositor) external view returns (uint256);

    /*
     * Calculate the MAHA gain earned by a deposit since its last snapshots were taken.
     * If not tagged with a front end, the depositor gets a 100% cut of what their deposit earned.
     * Otherwise, their cut of the deposit's earnings is equal to the kickbackRate, set by the front end through
     * which they made their deposit.
     */
    function getDepositorMAHAGain(address _depositor) external view returns (uint256);

    /*
     * Return the MAHA gain earned by the front end.
     */
    function getFrontEndMAHAGain(address _frontEnd) external view returns (uint256);

    /*
     * Return the user's compounded deposit.
     */
    function getCompoundedARTHDeposit(address _depositor) external view returns (uint256);

    /*
     * Return the front end's compounded stake.
     *
     * The front end's compounded stake is equal to the sum of its depositors' compounded deposits.
     */
    function getCompoundedFrontEndStake(address _frontEnd) external view returns (uint256);

    /*
     * Fallback function
     * Only callable by Active Pool, it just accounts for ETH received
     * receive() external payable;
     */
}
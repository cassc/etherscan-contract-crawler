// SPDX-License-Identifier: GPL-3.0
// Copyright: https://github.com/credit-cooperative/Line-Of-Credit/blob/master/COPYRIGHT.md

 pragma solidity ^0.8.16;

import {LineLib} from "../utils/LineLib.sol";
import {IOracle} from "../interfaces/IOracle.sol";

interface ILineOfCredit {
    // Lender data
    struct Credit {
        //  all denominated in token, not USD
        uint256 deposit; // The total liquidity provided by a Lender in a given token on a Line of Credit
        uint256 principal; // The amount of a Lender's Deposit on a Line of Credit that has actually been drawn down by the Borrower (in Tokens)
        uint256 interestAccrued; // Interest due by a Borrower but not yet repaid to the Line of Credit contract
        uint256 interestRepaid; // Interest repaid by a Borrower to the Line of Credit contract but not yet withdrawn by a Lender
        uint8 decimals; // Decimals of Credit Token for calcs
        address token; // The token being lent out (Credit Token)
        address lender; // The person to repay
        bool isOpen; // Status of position
    }

    // General Events
    event UpdateStatus(uint256 indexed status); // store as normal uint so it can be indexed in subgraph

    event DeployLine(address indexed oracle, address indexed arbiter, address indexed borrower);

    event SortedIntoQ(bytes32 indexed id, uint256 indexed newIdx, uint256 indexed oldIdx, bytes32 oldId);

    // MutualConsent borrower/lender events

    event AddCredit(address indexed lender, address indexed token, uint256 indexed deposit, bytes32 id);
    // can only reference id once AddCredit is emitted because it will be indexed offchain

    event SetRates(bytes32 indexed id, uint128 indexed dRate, uint128 indexed fRate);

    event IncreaseCredit(bytes32 indexed id, uint256 indexed deposit);

    // Lender Events

    // Emits data re Lender removes funds (principal) - there is no corresponding function, just withdraw()
    event WithdrawDeposit(bytes32 indexed id, uint256 indexed amount);

    // Emits data re Lender withdraws interest - there is no corresponding function, just withdraw()
    event WithdrawProfit(bytes32 indexed id, uint256 indexed amount);

    // Emitted when any credit line is closed by the line's borrower or the position's lender
    event CloseCreditPosition(bytes32 indexed id);

    // After accrueInterest runs, emits the amount of interest added to a Borrower's outstanding balance of interest due
    // but not yet repaid to the Line of Credit contract
    event InterestAccrued(bytes32 indexed id, uint256 indexed amount);

    // Borrower Events

    // receive full line or drawdown on credit
    event Borrow(bytes32 indexed id, uint256 indexed amount);

    // Emits that a Borrower has repaid an amount of interest Results in an increase in interestRepaid, i.e. interest not yet withdrawn by a Lender). There is no corresponding function
    event RepayInterest(bytes32 indexed id, uint256 indexed amount);

    // Emits that a Borrower has repaid an amount of principal - there is no corresponding function
    event RepayPrincipal(bytes32 indexed id, uint256 indexed amount);

    event Default(bytes32 indexed id);

    // Access Errors
    error NotActive();
    error NotBorrowing();
    error CallerAccessDenied();

    // Tokens
    error TokenTransferFailed();
    error NoTokenPrice();

    // Line
    error BadModule(address module);
    error NoLiquidity();
    error PositionExists();
    error CloseFailedWithPrincipal();
    error NotInsolvent(address module);
    error NotLiquidatable();
    error AlreadyInitialized();
    error PositionIsClosed();
    error RepayAmountExceedsDebt(uint256 totalAvailable);
    error CantStepQ();
    error EthSupportDisabled();
    error BorrowFailed();

    // Fully public functions

    /**
     * @notice - Runs logic to ensure Line owns all modules are configured properly - collateral, interest rates, arbiter, etc.
     *          - Changes `status` from UNINITIALIZED to ACTIVE
     * @dev     - Reverts on failure to update status
     */
    function init() external;

    // MutualConsent functions

    /**
    * @notice        - On first call, creates proposed terms and emits MutualConsentRegistsered event. No position is created.
                      - On second call, creates position and stores in Line contract, sets interest rates, and starts accruing facility rate fees.
    * @dev           - Requires mutualConsent participants send EXACT same params when calling addCredit
    * @dev           - Fully executes function after a Borrower and a Lender have agreed terms, both Lender and borrower have agreed through mutualConsent
    * @dev           - callable by `lender` and `borrower`
    * @param drate   - The interest rate charged to a Borrower on borrowed / drawn down funds. In bps, 4 decimals.
    * @param frate   - The interest rate charged to a Borrower on the remaining funds available, but not yet drawn down
                        (rate charged on the available headroom). In bps, 4 decimals.
    * @param amount  - The amount of Credit Token to initially deposit by the Lender
    * @param token   - The Credit Token, i.e. the token to be lent out
    * @param lender  - The address that will manage credit line
    * @return id     - Lender's position id to look up in `credits`
  */
    function addCredit(
        uint128 drate,
        uint128 frate,
        uint256 amount,
        address token,
        address lender
    ) external payable returns (bytes32);

    /**
     * @notice           - lets Lender and Borrower update rates on the lender's position
     *                   - accrues interest before updating terms, per InterestRate docs
     *                   - can do so even when LIQUIDATABLE for the purpose of refinancing and/or renego
     * @dev              - callable by Borrower or Lender
     * @param id         - position id that we are updating
     * @param drate      - new drawn rate. In bps, 4 decimals
     * @param frate      - new facility rate. In bps, 4 decimals
     */
    function setRates(bytes32 id, uint128 drate, uint128 frate) external;

    /**
     * @notice           - Lets a Lender and a Borrower increase the credit limit on a position
     * @dev              - line status must be ACTIVE
     * @dev              - callable by borrower
     * @dev              - The function retains the `payable` designation, despite not accepting Eth via mutualConsent modifier, as a gas-optimization
     * @param id         - position id that we are updating
     * @param amount     - amount to deposit by the Lender
     */
    function increaseCredit(bytes32 id, uint256 amount) external payable;

    // Borrower functions

    /**
     * @notice       - Borrower chooses which lender position draw down on and transfers tokens from Line contract to Borrower
     * @dev          - callable by borrower
     * @param id     - the position to draw down on
     * @param amount - amount of tokens the borrower wants to withdraw
     */
    function borrow(bytes32 id, uint256 amount) external;

    /**
     * @notice       - Transfers token used in position id from msg.sender to Line contract.
     * @dev          - Available for anyone to deposit Credit Tokens to be available to be withdrawn by Lenders
     * @dev          - The function retains the `payable` designation, despite reverting with a non-zero msg.value, as a gas-optimization
     * @notice       - see LineOfCredit._repay() for more details
     * @param amount - amount of `token` in `id` to pay back
     */
    function depositAndRepay(uint256 amount) external payable;

    /**
     * @notice       - A Borrower deposits enough tokens to repay and close a credit line.
     * @dev          - callable by borrower
     * @dev          - The function retains the `payable` designation, despite reverting with a non-zero msg.value, as a gas-optimization
     */
    function depositAndClose() external payable;

    /**
     * @notice - Removes and deletes a position, preventing any more borrowing or interest.
     *         - Requires that the position principal has already been repais in full
     * @dev      - MUST repay accrued interest from facility fee during call
     * @dev - callable by `borrower` or Lender
     * @dev          - The function retains the `payable` designation, despite reverting with a non-zero msg.value, as a gas-optimization
     * @param id -the position id to be closed
     */
    function close(bytes32 id) external payable;

    // Lender functions

    /**
     * @notice - Withdraws liquidity from a Lender's position available to the Borrower.
     *         - Lender is only allowed to withdraw tokens not already lent out
     *         - Withdraws from repaid interest (profit) first and then deposit is reduced
     * @dev - can only withdraw tokens from their own position. If multiple lenders lend DAI, the lender1 can't withdraw using lender2's tokens
     * @dev - callable by Lender on `id`
     * @param id - the position id that Lender is withdrawing from
     * @param amount - amount of tokens the Lender would like to withdraw (withdrawn amount may be lower)
     */
    function withdraw(bytes32 id, uint256 amount) external;

    // Arbiter functions
    /**
     * @notice - Allow the Arbiter to signify that the Borrower is incapable of repaying debt permanently.
     *         - Recoverable funds for Lender after declaring insolvency = deposit + interestRepaid - principal
     * @dev    - Needed for onchain impairment accounting e.g. updating ERC4626 share price
     *         - MUST NOT have collateral left for call to succeed. Any collateral must already have been liquidated.
     * @dev    - Callable only by Arbiter.
     */
    function declareInsolvent() external;

    /**
     *
     * @notice - Updates accrued interest for the whole Line of Credit facility (i.e. for all credit lines)
     * @dev    - Loops over all position ids and calls related internal functions during which InterestRateCredit.sol
     *           is called with the id data and then 'interestAccrued' is updated.
     * @dev    - The related internal function _accrue() is called by other functions any time the balance on an individual
     *           credit line changes or if the interest rates of a credit line are changed by mutual consent
     *           between a Borrower and a Lender.
     */
    function accrueInterest() external;

    function healthcheck() external returns (LineLib.STATUS);

    /**
     * @notice - Cycles through position ids andselects first position with non-null principal to the zero index
     * @dev - Only works if the first element in the queue is null
     */
    function stepQ() external;

    /**
     * @notice - Returns the total debt of a Borrower across all positions for all Lenders.
     * @dev    - Denominated in USD, 8 decimals.
     * @dev    - callable by anyone
     * @return totalPrincipal - total amount of principal, in USD, owed across all positions
     * @return totalInterest - total amount of interest, in USD,  owed across all positions
     */
    function updateOutstandingDebt() external returns (uint256, uint256);

    // State getters

    function status() external returns (LineLib.STATUS);

    function borrower() external returns (address);

    function arbiter() external returns (address);

    function oracle() external returns (IOracle);

    /**
     * @notice - getter for amount of active ids + total ids in list
     * @return - (uint256, uint256) - active credit lines, total length
     */
    function counts() external view returns (uint256, uint256);

    /**
     * @notice - getter for amount of active ids + total ids in list
     * @return - (uint256, uint256) - active credit lines, total length
     */

    function interestAccrued(bytes32 id) external returns (uint256);

    /**
     * @notice - info on the next lender position that must be repaid
     * @return - (bytes32, address, address, uint, uint) - id, lender, token, principal, interestAccrued
     */
    function nextInQ() external view returns (bytes32, address, address, uint256, uint256, uint256, uint128, uint128);

    /**
     * @notice - how many tokens can be withdrawn from positions by borrower or lender
     * @return - (uint256, uint256) - remaining deposit, claimable interest
     */
    function available(bytes32 id) external returns (uint256, uint256);
}
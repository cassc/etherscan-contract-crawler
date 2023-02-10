// SPDX-License-Identifier: BUSL-1.1
// Gearbox Protocol. Generalized leverage for DeFi protocols
// (c) Gearbox Holdings, 2022
pragma solidity ^0.8.10;

// LIBRARIES
import { Address } from "@openzeppelin/contracts/utils/Address.sol";
import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import { SafeERC20 } from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import { SafeCast } from "@openzeppelin/contracts/utils/math/SafeCast.sol";

import { ACLTrait } from "../core/ACLTrait.sol";

// INTERFACES
import { IAccountFactory } from "../interfaces/IAccountFactory.sol";
import { ICreditAccount } from "../interfaces/ICreditAccount.sol";
import { IPoolService } from "../interfaces/IPoolService.sol";
import { IWETHGateway } from "../interfaces/IWETHGateway.sol";
import { ICreditManagerV2, ClosureAction } from "../interfaces/ICreditManagerV2.sol";
import { IAddressProvider } from "../interfaces/IAddressProvider.sol";
import { IPriceOracleV2 } from "../interfaces/IPriceOracle.sol";

// CONSTANTS
import { RAY } from "../libraries/Constants.sol";
import { PERCENTAGE_FACTOR } from "../libraries/PercentageMath.sol";
import { DEFAULT_FEE_INTEREST, DEFAULT_FEE_LIQUIDATION, DEFAULT_LIQUIDATION_PREMIUM, LEVERAGE_DECIMALS, ALLOWANCE_THRESHOLD, UNIVERSAL_CONTRACT } from "../libraries/Constants.sol";

uint256 constant ADDR_BIT_SIZE = 160;
uint256 constant INDEX_PRECISION = 10**9;

struct Slot1 {
    /// @dev Interest fee charged by the protocol: fee = interest accrued * feeInterest
    uint16 feeInterest;
    /// @dev Liquidation fee charged by the protocol: fee = totalValue * feeLiquidation
    uint16 feeLiquidation;
    /// @dev Multiplier used to compute the total value of funds during liquidation.
    /// At liquidation, the borrower's funds are discounted, and the pool is paid out of discounted value
    /// The liquidator takes the difference between the discounted and actual values as premium.
    uint16 liquidationDiscount;
    /// @dev Liquidation fee charged by the protocol during liquidation by expiry. Typically lower than feeLiquidation.
    uint16 feeLiquidationExpired;
    /// @dev Multiplier used to compute the total value of funds during liquidation by expiry. Typically higher than
    /// liquidationDiscount (meaning lower premium).
    uint16 liquidationDiscountExpired;
    /// @dev Price oracle used to evaluate assets on Credit Accounts.
    IPriceOracleV2 priceOracle;
    /// @dev Liquidation threshold for the underlying token.
    uint16 ltUnderlying;
}

/// @title Credit Manager
/// @notice Encapsulates the business logic for managing Credit Accounts
///
/// More info: https://dev.gearbox.fi/developers/credit/credit_manager
contract CreditManager is ICreditManagerV2, ACLTrait {
    using SafeERC20 for IERC20;
    using Address for address payable;
    using SafeCast for uint256;

    /// @dev used to protect against reentrancy. Bool is gas-optimal,
    /// since there are other non-zero values packed into the same slot
    bool private entered;

    bool public emergencyLiquidation;

    /// @dev The maximal number of enabled tokens on a single Credit Account
    uint8 public override maxAllowedEnabledTokenLength = 12;

    /// @dev Address of the connected Credit Facade
    address public override creditFacade;

    /// @dev Stores fees & parameters commonly used together for gas savings
    Slot1 internal slot1;

    /// @dev A map from borrower addresses to Credit Account addresses
    mapping(address => address) public override creditAccounts;

    /// @dev Factory contract for Credit Accounts
    IAccountFactory public immutable _accountFactory;

    /// @dev Address of the underlying asset
    address public immutable override underlying;

    /// @dev Address of the connected pool
    /// @notice [DEPRECATED]: use pool() instead.
    address public immutable override poolService;

    /// @dev Address of the connected pool
    address public immutable override pool;

    /// @dev Address of WETH
    address public immutable override wethAddress;

    /// @dev Address of WETH Gateway
    address public immutable wethGateway;

    /// @dev Address of the connected Credit Configurator
    address public creditConfigurator;

    /// @dev Map of token's bit mask to its address and LT compressed into a single uint256
    /// @notice Use collateralTokens(uint256 i) to get uncompressed values.
    mapping(uint256 => uint256) internal collateralTokensCompressed;

    /// @dev Total number of known collateral tokens.
    uint256 public collateralTokensCount;

    /// @dev Internal map of token addresses to their indidivual masks.
    /// @notice A mask is a uint256 that has only 1 non-zero bit in the position correspondingto
    ///         the token's index (i.e., tokenMask = 2 ** index)
    ///         Masks are used to efficiently check set inclusion, since it only involves
    ///         a single AND and comparison to zero
    mapping(address => uint256) internal tokenMasksMapInternal;

    /// @dev Bit mask encoding a set of forbidden tokens
    uint256 public override forbiddenTokenMask;

    /// @dev Maps Credit Accounts to bit masks encoding their enabled token sets
    /// Only enabled tokens are counted as collateral for the Credit Account
    /// @notice An enabled token mask encodes an enabled token by setting
    ///         the bit at the position equal to token's index to 1
    mapping(address => uint256) public override enabledTokensMap;

    /// @dev Maps Credit Accounts to their current cumulative drops in value during fast checks
    /// See more details in fastCollateralCheck()
    mapping(address => uint256) public cumulativeDropAtFastCheckRAY;

    /// @dev Maps allowed adapters to their respective target contracts.
    mapping(address => address) public override adapterToContract;

    /// @dev Maps 3rd party contracts to their respective adapters
    mapping(address => address) public override contractToAdapter;

    /// @dev Maps addresses to their status as emergency liquidator.
    /// @notice Emergency liquidators are trusted addresses
    /// that are able to liquidate positions while the contracts are paused,
    /// e.g. when there is a risk of bad debt while an exploit is being patched.
    /// In the interest of fairness, emergency liquidators do not receive a premium
    /// And are compensated by the Gearbox DAO separately.
    mapping(address => bool) public override canLiquidateWhilePaused;

    /// @dev Stores address of the Universal adapter
    /// @notice See more at https://dev.gearbox.fi/docs/documentation/integrations/universal
    address public universalAdapter;

    /// @dev contract version
    uint256 public constant override version = 2;

    //
    // MODIFIERS
    //

    /// @dev Protects against reentrancy.
    /// @notice Custom ReentrancyGuard implementation is used to optimize storage reads.
    modifier nonReentrant() {
        if (entered) {
            revert ReentrancyLockException();
        }

        entered = true;
        _;
        entered = false;
    }

    /// @dev Restricts calls to Credit Facade or allowed adapters
    modifier adaptersOrCreditFacadeOnly() {
        if (
            adapterToContract[msg.sender] == address(0) &&
            msg.sender != creditFacade
        ) revert AdaptersOrCreditFacadeOnlyException(); //
        _;
    }

    /// @dev Restricts calls to Credit Facade only
    modifier creditFacadeOnly() {
        if (msg.sender != creditFacade) revert CreditFacadeOnlyException();
        _;
    }

    /// @dev Restricts calls to Credit Configurator only
    modifier creditConfiguratorOnly() {
        if (msg.sender != creditConfigurator)
            revert CreditConfiguratorOnlyException();
        _;
    }

    modifier whenNotPausedOrEmergency() {
        require(!paused() || emergencyLiquidation, "Pausable: paused");
        _;
    }

    /// @dev Constructor
    /// @param _pool Address of the pool to borrow funds from
    constructor(address _pool)
        ACLTrait(address(IPoolService(_pool).addressProvider()))
    {
        IAddressProvider addressProvider = IPoolService(_pool)
            .addressProvider();

        pool = _pool; // F:[CM-1]
        poolService = _pool; // F:[CM-1]

        address _underlying = IPoolService(pool).underlyingToken(); // F:[CM-1]
        underlying = _underlying; // F:[CM-1]

        // The underlying is the first token added as collateral
        _addToken(_underlying); // F:[CM-1]

        wethAddress = addressProvider.getWethToken(); // F:[CM-1]
        wethGateway = addressProvider.getWETHGateway(); // F:[CM-1]

        // Price oracle is stored in Slot1, as it is accessed frequently with fees
        slot1.priceOracle = IPriceOracleV2(addressProvider.getPriceOracle()); // F:[CM-1]
        _accountFactory = IAccountFactory(addressProvider.getAccountFactory()); // F:[CM-1]
        creditConfigurator = msg.sender; // F:[CM-1]
    }

    //
    // CREDIT ACCOUNT MANAGEMENT
    //

    ///  @dev Opens credit account and borrows funds from the pool.
    /// - Takes Credit Account from the factory;
    /// - Requests the pool to lend underlying to the Credit Account
    ///
    /// @param borrowedAmount Amount to be borrowed by the Credit Account
    /// @param onBehalfOf The owner of the newly opened Credit Account
    function openCreditAccount(uint256 borrowedAmount, address onBehalfOf)
        external
        override
        whenNotPaused // F:[CM-5]
        nonReentrant
        creditFacadeOnly // F:[CM-2]
        returns (address)
    {
        // Takes a Credit Account from the factory and sets initial parameters
        // The Credit Account will be connected to this Credit Manager until closing
        address creditAccount = _accountFactory.takeCreditAccount(
            borrowedAmount,
            IPoolService(pool).calcLinearCumulative_RAY()
        ); // F:[CM-8]

        // Requests the pool to transfer tokens the Credit Account
        IPoolService(pool).lendCreditAccount(borrowedAmount, creditAccount); // F:[CM-8]

        // Checks that the onBehalfOf does not already have an account, and records it as owner
        _safeCreditAccountSet(onBehalfOf, creditAccount); // F:[CM-7]

        // Initializes the enabled token mask for Credit Account to 1 (only the underlying is enabled)
        enabledTokensMap[creditAccount] = 1; // F:[CM-8]

        // Returns the address of the opened Credit Account
        return creditAccount; // F:[CM-8]
    }

    ///  @dev Closes a Credit Account - covers both normal closure and liquidation
    /// - Checks whether the contract is paused, and, if so, if the payer is an emergency liquidator.
    ///   Only emergency liquidators are able to liquidate account while the CM is paused.
    ///   Emergency liquidations do not pay a liquidator premium or liquidation fees.
    /// - Calculates payments to various recipients on closure:
    ///    + Computes amountToPool, which is the amount to be sent back to the pool.
    ///      This includes the principal, interest and fees, but can't be more than
    ///      total position value
    ///    + Computes remainingFunds during liquidations - these are leftover funds
    ///      after paying the pool and the liquidator, and are sent to the borrower
    ///    + Computes protocol profit, which includes interest and liquidation fees
    ///    + Computes loss if the totalValue is less than borrow amount + interest
    /// - Checks the underlying token balance:
    ///    + if it is larger than amountToPool, then the pool is paid fully from funds on the Credit Account
    ///    + else tries to transfer the shortfall from the payer - either the borrower during closure, or liquidator during liquidation
    /// - Send assets to the "to" address, as long as they are not included into skipTokenMask
    /// - If convertWETH is true, the function converts WETH into ETH before sending
    /// - Returns the Credit Account back to factory
    ///
    /// @param borrower Borrower address
    /// @param closureActionType Whether the account is closed, liquidated or liquidated due to expiry
    /// @param totalValue Portfolio value for liqution, 0 for ordinary closure
    /// @param payer Address which would be charged if credit account has not enough funds to cover amountToPool
    /// @param to Address to which the leftover funds will be sent
    /// @param skipTokenMask Tokenmask contains 1 for tokens which needed to be skipped for sending
    /// @param convertWETH If true converts WETH to ETH
    function closeCreditAccount(
        address borrower,
        ClosureAction closureActionType,
        uint256 totalValue,
        address payer,
        address to,
        uint256 skipTokenMask,
        bool convertWETH
    )
        external
        override
        nonReentrant
        creditFacadeOnly // F:[CM-2]
        returns (uint256 remainingFunds)
    {
        // If the contract is paused and the payer is the emergency liquidator,
        // changes closure action to LIQUIDATE_PAUSED, so that the premium is nullified
        // If the payer is not an emergency liquidator, reverts
        if (paused()) {
            if (
                canLiquidateWhilePaused[payer] &&
                (closureActionType == ClosureAction.LIQUIDATE_ACCOUNT ||
                    closureActionType ==
                    ClosureAction.LIQUIDATE_EXPIRED_ACCOUNT)
            ) {
                closureActionType = ClosureAction.LIQUIDATE_PAUSED; // F: [CM-12, 13]
            } else revert("Pausable: paused"); // F:[CM-5]
        }

        // Checks that the Credit Account exists for the borrower
        address creditAccount = getCreditAccountOrRevert(borrower); // F:[CM-6, 9, 10]

        // Sets borrower's Credit Account to zero address in the map
        // This needs to be done before other actions, to prevent inconsistent state
        // in the middle of closing transaction - e.g., _transferAssetsTo can be used to report a lower
        // value of a CA to third parties before the end of the function execution, since it
        // gives up control flow when some assets are already removed from the account
        delete creditAccounts[borrower]; // F:[CM-9]

        // Makes all computations needed to close credit account
        uint256 amountToPool;
        uint256 borrowedAmount;

        {
            uint256 profit;
            uint256 loss;
            uint256 borrowedAmountWithInterest;
            (
                borrowedAmount,
                borrowedAmountWithInterest,

            ) = calcCreditAccountAccruedInterest(creditAccount); // F:

            (amountToPool, remainingFunds, profit, loss) = calcClosePayments(
                totalValue,
                closureActionType,
                borrowedAmount,
                borrowedAmountWithInterest
            ); // F:[CM-10,11,12]

            uint256 underlyingBalance = IERC20(underlying).balanceOf(
                creditAccount
            );

            // If there is an underlying surplus, transfers it to the "to" address
            if (underlyingBalance > amountToPool + remainingFunds + 1) {
                unchecked {
                    _safeTokenTransfer(
                        creditAccount,
                        underlying,
                        to,
                        underlyingBalance - amountToPool - remainingFunds - 1,
                        convertWETH
                    ); // F:[CM-10,12,16]
                }
                // If there is an underlying shortfall, attempts to transfer it from the payer
            } else {
                unchecked {
                    IERC20(underlying).safeTransferFrom(
                        payer,
                        creditAccount,
                        amountToPool + remainingFunds - underlyingBalance + 1
                    ); // F:[CM-11,13]
                }
            }

            // Transfers the due funds to the pool
            _safeTokenTransfer(
                creditAccount,
                underlying,
                pool,
                amountToPool,
                false
            ); // F:[CM-10,11,12,13]

            // Signals to the pool that debt has been repaid. The pool relies
            // on the Credit Manager to repay the debt correctly, and does not
            // check internally whether the underlying was actually transferred
            IPoolService(pool).repayCreditAccount(borrowedAmount, profit, loss); // F:[CM-10,11,12,13]
        }

        // transfer remaining funds to the borrower [liquidations only]
        if (remainingFunds > 1) {
            _safeTokenTransfer(
                creditAccount,
                underlying,
                borrower,
                remainingFunds,
                false
            ); // F:[CM-13,18]
        }

        // Tokens in skipTokenMask are disabled before transferring all assets
        uint256 enabledTokensMask = enabledTokensMap[creditAccount] &
            ~skipTokenMask; // F:[CM-14]
        _transferAssetsTo(creditAccount, to, convertWETH, enabledTokensMask); // F:[CM-14,17,19]

        // Returns Credit Account to the factory
        _accountFactory.returnCreditAccount(creditAccount); // F:[CM-9]
    }

    /// @dev Manages debt size for borrower:
    ///
    /// - Increase debt:
    ///   + Increases debt by transferring funds from the pool to the credit account
    ///   + Updates the cumulative index to keep interest the same. Since interest
    ///     is always computed dynamically as borrowedAmount * (cumulativeIndexNew / cumulativeIndexOpen - 1),
    ///     cumulativeIndexOpen needs to be updated, as the borrow amount has changed
    ///
    /// - Decrease debt:
    ///   + Repays debt partially + all interest and fees accrued thus far
    ///   + Updates cunulativeIndex to cumulativeIndex now
    ///
    /// @param creditAccount Address of the Credit Account to change debt for
    /// @param amount Amount to increase / decrease the principal by
    /// @param increase True to increase principal, false to decrease
    /// @return newBorrowedAmount The new debt principal
    function manageDebt(
        address creditAccount,
        uint256 amount,
        bool increase
    )
        external
        whenNotPaused // F:[CM-5]
        nonReentrant
        creditFacadeOnly // F:[CM-2]
        returns (uint256 newBorrowedAmount)
    {
        (
            uint256 borrowedAmount,
            uint256 cumulativeIndexAtOpen_RAY,
            uint256 cumulativeIndexNow_RAY
        ) = _getCreditAccountParameters(creditAccount);

        uint256 newCumulativeIndex;
        if (increase) {
            newBorrowedAmount = borrowedAmount + amount;

            // Computes the new cumulative index to keep the interest
            // unchanged with different principal

            newCumulativeIndex = _calcNewCumulativeIndex(
                borrowedAmount,
                amount,
                cumulativeIndexNow_RAY,
                cumulativeIndexAtOpen_RAY,
                true
            );

            // Requests the pool to lend additional funds to the Credit Account
            IPoolService(pool).lendCreditAccount(amount, creditAccount); // F:[CM-20]
        } else {
            // Computes the interest accrued thus far
            uint256 interestAccrued = (borrowedAmount *
                cumulativeIndexNow_RAY) /
                cumulativeIndexAtOpen_RAY -
                borrowedAmount; // F:[CM-21]

            // Computes profit, taken as a percentage of the interest rate
            uint256 profit = (interestAccrued * slot1.feeInterest) /
                PERCENTAGE_FACTOR; // F:[CM-21]

            if (amount >= interestAccrued + profit) {
                // If the amount covers all of the interest and fees, they are
                // paid first, and the remainder is used to pay the principal
                newBorrowedAmount =
                    borrowedAmount +
                    interestAccrued +
                    profit -
                    amount;

                // Pays the amount back to the pool
                ICreditAccount(creditAccount).safeTransfer(
                    underlying,
                    pool,
                    amount
                ); // F:[CM-21]

                // Signals the pool that the debt was partially repaid
                IPoolService(pool).repayCreditAccount(
                    amount - interestAccrued - profit,
                    profit,
                    0
                ); // F:[CM-21]

                // Since interest is fully repaid, the Credit Account's cumulativeIndexAtOpen
                // is set to the current cumulative index - which means interest starts accruing
                // on the new principal from zero
                newCumulativeIndex = IPoolService(pool)
                    .calcLinearCumulative_RAY(); // F:[CM-21]
            } else {
                // If the amount is not enough to cover interest and fees,
                // it is split between the two pro-rata. Since the fee is the percentage
                // of interest, this ensures that the new fee is consistent with the
                // new pending interest
                uint256 amountToInterest = (amount * PERCENTAGE_FACTOR) /
                    (PERCENTAGE_FACTOR + slot1.feeInterest);
                uint256 amountToFees = amount - amountToInterest;

                // Since interest and fees are paid out first, the principal
                // remains unchanged
                newBorrowedAmount = borrowedAmount;

                // Pays the amount back to the pool
                ICreditAccount(creditAccount).safeTransfer(
                    underlying,
                    pool,
                    amount
                ); // F:[CM-21]

                // Signals the pool that the debt was partially repaid
                IPoolService(pool).repayCreditAccount(0, amountToFees, 0); // F:[CM-21]

                // Since the interest was only repaid partially, we need to recompute the
                // cumulativeIndexAtOpen, so that "borrowAmount * (indexNow / indexAtOpenNew - 1)"
                // is equal to interestAccrued - amountToInterest

                newCumulativeIndex = _calcNewCumulativeIndex(
                    borrowedAmount,
                    amountToInterest,
                    cumulativeIndexNow_RAY,
                    cumulativeIndexAtOpen_RAY,
                    false
                );
            }
        }
        //
        // Sets new parameters on the Credit Account
        ICreditAccount(creditAccount).updateParameters(
            newBorrowedAmount,
            newCumulativeIndex
        ); // F:[CM-20. 21]
    }

    /// @dev Calculates the new cumulative index when debt is updated
    /// @param borrowedAmount Current debt principal
    /// @param delta Absolute value of total debt amount change
    /// @param cumulativeIndexNow Current cumulative index of the pool
    /// @param cumulativeIndexOpen Last updated cumulative index recorded for the corresponding debt position
    /// @param isIncrease Whether the debt is increased or decreased
    /// @notice Handles two potential cases:
    ///         * Debt principal is increased by delta - in this case, the principal is changed
    ///           but the interest / fees have to stay the same
    ///         * Interest is decreased by delta - in this case, the principal stays the same,
    ///           but the interest changes. The delta is assumed to have fee repayment excluded.
    ///         The debt decrease case where delta > interest + fees is trivial and should be handled outside
    ///         this function.
    function _calcNewCumulativeIndex(
        uint256 borrowedAmount,
        uint256 delta,
        uint256 cumulativeIndexNow,
        uint256 cumulativeIndexOpen,
        bool isIncrease
    ) internal pure returns (uint256 newCumulativeIndex) {
        if (isIncrease) {
            // In case of debt increase, the principal increases by exactly delta, but interest has to be kept unchanged
            // newCumulativeIndex is proven to be the solution to
            // borrowedAmount * (cumulativeIndexNow / cumulativeIndexOpen - 1) ==
            // == (borrowedAmount + delta) * (cumulativeIndexNow / newCumulativeIndex - 1)

            uint256 newBorrowedAmount = borrowedAmount + delta;

            newCumulativeIndex = ((cumulativeIndexNow *
                newBorrowedAmount *
                INDEX_PRECISION) /
                ((INDEX_PRECISION * cumulativeIndexNow * borrowedAmount) /
                    cumulativeIndexOpen +
                    INDEX_PRECISION *
                    delta));
        } else {
            // In case of debt decrease, the principal is the same, but the interest is reduced exactly by delta
            // newCumulativeIndex is proven to be the solution to
            // borrowedAmount * (cumulativeIndexNow / cumulativeIndexOpen - 1) - delta ==
            // == borrowedAmount * (cumulativeIndexNow / newCumulativeIndex - 1)

            newCumulativeIndex =
                (INDEX_PRECISION * cumulativeIndexNow * cumulativeIndexOpen) /
                (INDEX_PRECISION *
                    cumulativeIndexNow -
                    (INDEX_PRECISION * delta * cumulativeIndexOpen) /
                    borrowedAmount);
        }
    }

    /// @dev Adds collateral to borrower's credit account
    /// @param payer Address of the account which will be charged to provide additional collateral
    /// @param creditAccount Address of the Credit Account
    /// @param token Collateral token to add
    /// @param amount Amount to add
    function addCollateral(
        address payer,
        address creditAccount,
        address token,
        uint256 amount
    )
        external
        whenNotPaused // F:[CM-5]
        nonReentrant
        creditFacadeOnly // F:[CM-2]
    {
        // Checks that the token is not forbidden
        // And enables it so that it is counted in collateral
        _checkAndEnableToken(creditAccount, token); // F:[CM-22]

        IERC20(token).safeTransferFrom(payer, creditAccount, amount); // F:[CM-22]
    }

    /// @dev Transfers Credit Account ownership to another address
    /// @param from Address of previous owner
    /// @param to Address of new owner
    function transferAccountOwnership(address from, address to)
        external
        override
        whenNotPausedOrEmergency // F:[CM-5]
        nonReentrant
        creditFacadeOnly // F:[CM-2]
    {
        address creditAccount = getCreditAccountOrRevert(from); // F:[CM-6]
        delete creditAccounts[from]; // F:[CM-24]

        _safeCreditAccountSet(to, creditAccount); // F:[CM-23, 24]
    }

    /// @dev Requests the Credit Account to approve a collateral token to another contract.
    /// @param borrower Borrower's address
    /// @param targetContract Spender to change allowance for
    /// @param token Collateral token to approve
    /// @param amount New allowance amount
    function approveCreditAccount(
        address borrower,
        address targetContract,
        address token,
        uint256 amount
    )
        external
        override
        whenNotPausedOrEmergency // F:[CM-5]
        nonReentrant
    {
        // This function can only be called by connected adapters (must be a correct adapter/contract pair),
        // Credit Facade or Universal Adapter
        if (
            (adapterToContract[msg.sender] != targetContract &&
                msg.sender != creditFacade &&
                msg.sender != universalAdapter) || targetContract == address(0)
        ) {
            revert AdaptersOrCreditFacadeOnlyException(); // F:[CM-3,25]
        }

        // Checks that the token is a collateral token
        // Forbidden tokens can be approved, since users need that to
        // sell them off
        if (tokenMasksMap(token) == 0) revert TokenNotAllowedException(); // F:

        address creditAccount = getCreditAccountOrRevert(borrower); // F:[CM-6]

        // Attempts to set allowance directly to the required amount
        // If unsuccessful, assumes that the token requires setting allowance to zero first
        if (!_approve(token, targetContract, creditAccount, amount, false)) {
            _approve(token, targetContract, creditAccount, 0, true); // F:
            _approve(token, targetContract, creditAccount, amount, true);
        }
    }

    /// @dev Internal function used to approve token from a Credit Account
    /// Uses Credit Account's execute to properly handle both ERC20-compliant and
    /// non-compliant (no returned value from "approve") tokens
    function _approve(
        address token,
        address targetContract,
        address creditAccount,
        uint256 amount,
        bool revertIfFailed
    ) internal returns (bool) {
        // Makes a low-level call to approve from the Credit Account
        // and parses the value. If nothing or true was returned,
        // assumes that the call succeeded
        try
            ICreditAccount(creditAccount).execute(
                token,
                abi.encodeWithSelector(
                    IERC20.approve.selector,
                    targetContract,
                    amount
                )
            )
        returns (bytes memory result) {
            if (result.length == 0 || abi.decode(result, (bool)) == true)
                return true;
        } catch {}

        // On the first try, failure is allowed to handle tokens
        // that prohibit changing allowance from non-zero value;
        // After that, failure results in a revert
        if (revertIfFailed) revert AllowanceFailedException();
        return false;
    }

    /// @dev Requests a Credit Account to make a low-level call with provided data
    /// This is the intended pathway for state-changing interactions with 3rd-party protocols
    /// @param borrower Borrower's address
    /// @param targetContract Contract to be called
    /// @param data Data to pass with the call
    function executeOrder(
        address borrower,
        address targetContract,
        bytes memory data
    )
        external
        override
        whenNotPausedOrEmergency // F:[CM-5]
        nonReentrant
        returns (bytes memory)
    {
        // Checks that msg.sender is the adapter associated with the passed
        // target contract. The exception is the Universal Adapter, which
        // can potentially call any target.
        if (
            adapterToContract[msg.sender] != targetContract ||
            targetContract == address(0)
        ) {
            if (msg.sender != universalAdapter)
                revert TargetContractNotAllowedException(); // F:[CM-28]
        }

        address creditAccount = getCreditAccountOrRevert(borrower); // F:[CM-6]

        // Emits an event
        emit ExecuteOrder(borrower, targetContract); // F:[CM-29]

        // Returned data is provided as-is to the caller;
        // It is expected that is is parsed and returned as a correct type
        // by the adapter itself.
        return ICreditAccount(creditAccount).execute(targetContract, data); // F:[CM-29]
    }

    //
    // COLLATERAL VALIDITY AND ACCOUNT HEALTH CHECKS
    //

    /// @dev Enables a token on a Credit Account, including it
    /// into account health and total value calculations
    /// @param creditAccount Address of a Credit Account to enable the token for
    /// @param token Address of the token to be enabled
    function checkAndEnableToken(address creditAccount, address token)
        external
        override
        whenNotPausedOrEmergency
        adaptersOrCreditFacadeOnly // F:[CM-3]
        nonReentrant
    {
        _checkAndEnableToken(creditAccount, token); // F:[CM-30]
    }

    /// @dev IMPLEMENTATION: checkAndEnableToken
    /// @param creditAccount Address of a Credit Account to enable the token for
    /// @param token Address of the token to be enabled
    function _checkAndEnableToken(address creditAccount, address token)
        internal
    {
        uint256 tokenMask = tokenMasksMap(token); // F:[CM-30,31]

        // Checks that the token is valid collateral recognized by the system
        // and that it is not forbidden
        if (tokenMask == 0 || forbiddenTokenMask & tokenMask != 0)
            revert TokenNotAllowedException(); // F:[CM-30]

        // Performs an inclusion check using token masks,
        // to avoid accidentally disabling the token
        if (enabledTokensMap[creditAccount] & tokenMask == 0)
            enabledTokensMap[creditAccount] |= tokenMask; // F:[CM-31]
    }

    /// @dev Optimized health check for individual swap-like operations.
    /// @notice Fast health check assumes that only two tokens (input and output)
    ///         participate in the operation and computes a % change in weighted value between
    ///         inbound and outbound collateral. The cumulative negative change across several
    ///         swaps in sequence cannot be larger than feeLiquidation (a fee that the
    ///         protocol is ready to waive if needed). Since this records a % change
    ///         between just two tokens, the corresponding % change in TWV will always be smaller,
    ///         which makes this check safe.
    ///         More details at https://dev.gearbox.fi/docs/documentation/risk/fast-collateral-check#fast-check-protection
    /// @param creditAccount Address of the Credit Account
    /// @param tokenIn Address of the token spent by the swap
    /// @param tokenOut Address of the token received from the swap
    /// @param balanceInBefore Balance of tokenIn before the operation
    /// @param balanceOutBefore Balance of tokenOut before the operation
    function fastCollateralCheck(
        address creditAccount,
        address tokenIn,
        address tokenOut,
        uint256 balanceInBefore,
        uint256 balanceOutBefore
    )
        external
        override
        adaptersOrCreditFacadeOnly // F:[CM-3]
        nonReentrant
    {
        // Checks that inbound collateral is known and not forbidden
        // Enables it if disabled, to include it into TWV
        _checkAndEnableToken(creditAccount, tokenOut); // [CM-32]

        uint256 balanceInAfter = IERC20(tokenIn).balanceOf(creditAccount); // F: [CM-34]
        uint256 balanceOutAfter = IERC20(tokenOut).balanceOf(creditAccount); // F: [CM-34]

        (uint256 amountInCollateral, uint256 amountOutCollateral) = slot1
            .priceOracle
            .fastCheck(
                balanceInBefore - balanceInAfter,
                tokenIn,
                balanceOutAfter - balanceOutBefore,
                tokenOut
            ); // F:[CM-34]

        // Disables tokenIn if the entire balance was spent by the operation
        if (balanceInAfter <= 1) _disableToken(creditAccount, tokenIn); // F:[CM-33]

        // Collateral values must be compared weighted by respective LTs,
        // as otherwise a high-LT (e.g., underlying) token can be swapped
        // to an equivalent amount of a low-LT asset. Without weighting, this would
        // pass the check (since inbound and outbound values are equal),
        // while the health factor of the account would be reduced severely.
        amountOutCollateral *= liquidationThresholds(tokenOut); // F:[CM-34]
        amountInCollateral *= liquidationThresholds(tokenIn); // F:[CM-34]

        // If the value of inbound collateral is larger than inbound collateral
        // a health check does not need to be performed;
        // However, the number of enabled tokens needs to be checked against the limit,
        // as a new collateral token was potentially enabled
        if (amountOutCollateral >= amountInCollateral) {
            _checkAndOptimizeEnabledTokens(creditAccount); // F:[CM-35]
            return; // F:[CM-34]
        }

        // The new cumulative drop in value is computed in RAY format, for precision
        uint256 cumulativeDropRAY = RAY -
            ((amountOutCollateral * RAY) / amountInCollateral) +
            cumulativeDropAtFastCheckRAY[creditAccount]; // F:[CM-36]

        // If then new cumulative drop is less than feeLiquidation, the check is successful,
        // otherwise, a full collateral check is required
        if (
            cumulativeDropRAY <=
            (slot1.feeLiquidation * RAY) / PERCENTAGE_FACTOR
        ) {
            cumulativeDropAtFastCheckRAY[creditAccount] = cumulativeDropRAY; // F:[CM-36]
            _checkAndOptimizeEnabledTokens(creditAccount); // F:[CM-37]
            return;
        }

        // If a fast collateral check didn't pass, a full check is performed and
        // the cumulative drop is reset back to 0 (1 for gas-efficiency).
        _fullCollateralCheck(creditAccount); // F:[CM-34,36]
        cumulativeDropAtFastCheckRAY[creditAccount] = 1; // F:[CM-36]
    }

    /// @dev Performs a full health check on an account, summing up
    /// value of all enabled collateral tokens
    /// @param creditAccount Address of the Credit Account to check
    function fullCollateralCheck(address creditAccount)
        external
        override
        adaptersOrCreditFacadeOnly // F:[CM-3]
        nonReentrant
    {
        _fullCollateralCheck(creditAccount);
    }

    /// @dev IMPLEMENTATION: fullCollateralCheck
    /// @param creditAccount Address of the Credit Account to check
    function _fullCollateralCheck(address creditAccount) internal {
        IPriceOracleV2 _priceOracle = slot1.priceOracle;

        uint256 enabledTokenMask = enabledTokensMap[creditAccount];
        uint256 borrowAmountPlusInterestRateUSD;
        uint256 len;
        unchecked {
            // The total weighted value of a Credit Account has to be compared
            // with the entire debt sum, including interest and fees
            (
                ,
                ,
                uint256 borrowedAmountWithInterestAndFees
            ) = calcCreditAccountAccruedInterest(creditAccount);

            borrowAmountPlusInterestRateUSD = _priceOracle.convertToUSD(
                borrowedAmountWithInterestAndFees * PERCENTAGE_FACTOR,
                underlying
            );

            len = _getMaxIndex(enabledTokenMask) + 1;
        }

        uint256 tokenMask;
        uint256 twvUSD;
        bool atLeastOneTokenWasDisabled;

        for (uint256 i; i < len; ) {
            // The order of evaluation is adjusted to optimize for
            // farming, as it is the largest expected use case
            // Since farming positions are at the end of the collateral token list
            // the loop moves through token masks in descending order (except underlying, which is
            // checked first)
            unchecked {
                tokenMask = i == 0 ? 1 : 1 << (len - i);
            }

            // CASE enabledTokenMask & tokenMask == 0 F:[CM-38]
            if (enabledTokenMask & tokenMask != 0) {
                (
                    address token,
                    uint16 liquidationThreshold
                ) = collateralTokensByMask(tokenMask);
                uint256 balance = IERC20(token).balanceOf(creditAccount);

                // Collateral calculations are only done if there is a non-zero balance
                if (balance > 1) {
                    twvUSD +=
                        _priceOracle.convertToUSD(balance, token) *
                        liquidationThreshold;

                    // Full collateral check evaluates a Credit Account's health factor lazily;
                    // Once the TWV computed thus far exceeds the debt, the check is considered
                    // successful, and the function returns without evaluating any further collateral
                    if (twvUSD >= borrowAmountPlusInterestRateUSD) {
                        // Since a full collateral check is usually called after an operation or MultiCall
                        // involving many tokens, potentially many new tokens can be enabled. As such,
                        // the function needs to check whether the enabled token limit is violated,
                        // and disable any unused tokens, if so. Note that the number of enabled tokens
                        // is calculated from the updated enabledTokenMask, so some of the unused tokens may have already
                        // been disabled
                        uint256 totalTokensEnabled = _calcEnabledTokens(
                            enabledTokenMask
                        );
                        if (totalTokensEnabled > maxAllowedEnabledTokenLength) {
                            unchecked {
                                _optimizeEnabledTokens(
                                    creditAccount,
                                    enabledTokenMask,
                                    totalTokensEnabled,
                                    // At this stage in the function, at least underlying
                                    // must have been processed, so it can be skipped
                                    1,
                                    // Since the function disables all unused tokens it finds
                                    // and iterates in descending order,
                                    // _optimizeEnabledTokens only needs to check up to len - i
                                    len - i
                                ); // F:[CM-41] where i=0
                            }
                        } else {
                            // Saves enabledTokensMask if at least one token was disabled
                            if (atLeastOneTokenWasDisabled) {
                                enabledTokensMap[
                                    creditAccount
                                ] = enabledTokenMask; // F:[CM-39]
                            }
                        }

                        return; // F:[CM-40]
                    }
                    // Zero-balance tokens are disabled; this is done by flipping the
                    // bit in enabledTokenMask, which is then written into storage at the
                    // very end, to avoid redundant storage writes
                } else {
                    enabledTokenMask ^= tokenMask; // F:[CM-39]
                    atLeastOneTokenWasDisabled = true; // F:[CM-39]
                }
            }

            unchecked {
                ++i;
            }
        }
        revert NotEnoughCollateralException();
    }

    /// @dev Checks that the number of enabled tokens on a Credit Account
    ///      does not violate the maximal enabled token limit and tries
    ///      to disable unused tokens if it does
    /// @param creditAccount Account to check enabled tokens for
    function checkAndOptimizeEnabledTokens(address creditAccount)
        external
        override
        adaptersOrCreditFacadeOnly // F: [CM-2]
    {
        _checkAndOptimizeEnabledTokens(creditAccount);
    }

    /// @dev IMPLEMENTATION: checkAndOptimizeEnabledTokens
    function _checkAndOptimizeEnabledTokens(address creditAccount) internal {
        uint256 enabledTokenMask = enabledTokensMap[creditAccount];
        uint256 totalTokensEnabled = _calcEnabledTokens(enabledTokenMask);

        if (totalTokensEnabled > maxAllowedEnabledTokenLength) {
            uint256 maxIndex = _getMaxIndex(enabledTokenMask) + 1;

            _optimizeEnabledTokens(
                creditAccount,
                enabledTokenMask,
                totalTokensEnabled,
                0,
                maxIndex
            );
        }
    }

    /// @dev Calculates the number of enabled tokens, based on the
    ///      provided token mask
    /// @param enabledTokenMask Bit mask encoding a set of enabled tokens
    function _calcEnabledTokens(uint256 enabledTokenMask)
        internal
        pure
        returns (uint256 totalTokensEnabled)
    {
        // Bit mask is a number encoding enabled tokens as 1's;
        // Therefore, to count the number of enabled tokens, we simply
        // need to keep shifting the mask by one bit and checking if the rightmost bit is 1,
        // until the whole mask is 0;
        // Since bit shifting is overflow-safe and the loop has at most 256 steps,
        // the whole function can be marked as unsafe to optimize gas
        unchecked {
            while (enabledTokenMask > 0) {
                totalTokensEnabled += enabledTokenMask & 1;
                enabledTokenMask = enabledTokenMask >> 1;
            }
        }
    }

    /// @dev Searches for tokens with zero balance among enabled tokens
    ///      on a Credit Account and disables them, until the total number
    ///      of enabled tokens is at maxAllowedEnabledTokenLength
    /// @param creditAccount The Credit Account to optimize
    /// @param enabledTokenMask Mask encoding the set of currentl enabled tokens
    /// @param totalTokensEnabled The current number of enabled tokens
    /// @param minIndex Inclusive lower bound of search range
    /// @param maxIndex Non-inclusive upper bound of search range
    function _optimizeEnabledTokens(
        address creditAccount,
        uint256 enabledTokenMask,
        uint256 totalTokensEnabled,
        uint256 minIndex,
        uint256 maxIndex
    ) internal {
        // The whole block can be marked unchecked, since:
        // - maxIndex < 256 at all times (i.e., tokenMask < 2 ** 256);
        // - totalTokensEnabled does not go lower than maxAllowedEnabledTokenLength
        //   (the function returns at that point)
        unchecked {
            for (uint256 i = minIndex; i < maxIndex; ) {
                uint256 tokenMask = 1 << i;
                if (enabledTokenMask & tokenMask != 0) {
                    (address token, ) = collateralTokensByMask(tokenMask);
                    uint256 balance = IERC20(token).balanceOf(creditAccount);

                    if (balance <= 1) {
                        enabledTokenMask ^= tokenMask;
                        --totalTokensEnabled;
                        if (
                            totalTokensEnabled <= maxAllowedEnabledTokenLength
                        ) {
                            enabledTokensMap[creditAccount] = enabledTokenMask;
                            return;
                        }
                    }
                }

                ++i;
            }
        }
        revert TooManyEnabledTokensException();
    }

    /// @dev Disables a token on a credit account
    /// @notice Usually called by adapters to disable spent tokens during a multicall,
    ///         but can also be called separately from the Credit Facade to remove
    ///         unwanted tokens
    function disableToken(address creditAccount, address token)
        external
        override
        whenNotPausedOrEmergency // F:[CM-5]
        adaptersOrCreditFacadeOnly // F:[CM-3]
        nonReentrant
        returns (bool)
    {
        return _disableToken(creditAccount, token);
    }

    /// @dev IMPLEMENTATION: disableToken
    function _disableToken(address creditAccount, address token)
        internal
        returns (bool wasChanged)
    {
        // The enabled token mask encodes all enabled tokens as 1,
        // therefore the corresponding bit is set to 0 to disable it
        uint256 tokenMask = tokenMasksMap(token);
        if (enabledTokensMap[creditAccount] & tokenMask != 0) {
            enabledTokensMap[creditAccount] &= ~tokenMask; // F:[CM-46]
            wasChanged = true;
        }
    }

    /// @dev Checks if the contract is paused; if true, checks that the caller is emergency liquidator
    /// and temporarily enables a special emergencyLiquidator mode to allow liquidation.
    /// @notice Some whenNotPausedOrEmergency functions in CreditManager need to be executable to perform
    /// multicalls during liquidations. emergencyLiquidation mode is enabled temporarily
    /// (for the span of a single multicall) to override
    /// the paused state and allow a special privileged role to liquidate unhealthy positions, if the
    /// contracts are paused due to an emergency.
    /// @notice To save gas, emergency liquidation setting is skipped when the CM is not paused.
    ///
    ///
    /// @param caller Address of CreditFacade caller
    /// @param state True to enable and false to disable emergencyLiqudation mde
    /// @return True if contract paused otherwise false. If the contract is not paused, there is no need
    /// to call this function to disable the emergencyLiquidation mode.
    function checkEmergencyPausable(address caller, bool state)
        external
        creditFacadeOnly // F:[CM-2]
        returns (bool)
    {
        bool pausable = paused(); // F: [CM-67]
        if (pausable && canLiquidateWhilePaused[caller]) {
            emergencyLiquidation = state; // F: [CM-67]
        }
        return pausable; // F: [CM-67]
    }

    //
    // INTERNAL HELPERS
    //

    /// @dev Transfers all enabled assets from a Credit Account to the "to" address
    /// @param creditAccount Credit Account to transfer assets from
    /// @param to Recipient address
    /// @param convertWETH Whether WETH must be converted to ETH before sending
    /// @param enabledTokensMask A bit mask encoding enabled tokens. All of the tokens included
    ///        in the mask will be transferred. If any tokens need to be skipped, they must be
    ///        excluded from the mask beforehand.
    function _transferAssetsTo(
        address creditAccount,
        address to,
        bool convertWETH,
        uint256 enabledTokensMask
    ) internal {
        // Since underlying should have been transferred to "to" before this function is called
        // (if there is a surplus), its tokenMask of 1 is skipped
        uint256 tokenMask = 2;

        // Since enabledTokensMask encodes all enabled tokens as 1,
        // tokenMask > enabledTokensMask is equivalent to the last 1 bit being passed
        // The loop can be ended at this point
        while (tokenMask <= enabledTokensMask) {
            // enabledTokensMask & tokenMask == tokenMask when the token is enabled,
            // and 0 otherwise
            if (enabledTokensMask & tokenMask != 0) {
                (address token, ) = collateralTokensByMask(tokenMask); // F:[CM-44]
                uint256 amount = IERC20(token).balanceOf(creditAccount); // F:[CM-44]
                if (amount > 1) {
                    // 1 is subtracted from amount to leave a non-zero value
                    // in the balance mapping, optimizing future writes
                    // Since the amount is checked to be more than 1,
                    // the block can be marked as unchecked

                    // F:[CM-44]
                    unchecked {
                        _safeTokenTransfer(
                            creditAccount,
                            token,
                            to,
                            amount - 1,
                            convertWETH
                        ); // F:[CM-44]
                    }
                }
            }

            // The loop iterates by moving 1 bit to the left,
            // which corresponds to moving on to the next token
            tokenMask = tokenMask << 1; // F:[CM-44]
        }
    }

    /// @dev Requests the Credit Account to transfer a token to another address
    ///      Able to unwrap WETH before sending, if requested
    /// @param creditAccount Address of the sender Credit Account
    /// @param token Address of the token
    /// @param to Recipient address
    /// @param amount Amount to transfer
    function _safeTokenTransfer(
        address creditAccount,
        address token,
        address to,
        uint256 amount,
        bool convertToETH
    ) internal {
        if (convertToETH && token == wethAddress) {
            ICreditAccount(creditAccount).safeTransfer(
                token,
                wethGateway,
                amount
            ); // F:[CM-45]
            IWETHGateway(wethGateway).unwrapWETH(to, amount); // F:[CM-45]
        } else {
            ICreditAccount(creditAccount).safeTransfer(token, to, amount); // F:[CM-45]
        }
    }

    /// @dev Sets the Credit Account owner while checking that they do not
    ///      have an account already
    /// @param borrower The new owner of the Credit Account
    /// @param creditAccount The Credit Account address
    function _safeCreditAccountSet(address borrower, address creditAccount)
        internal
    {
        if (borrower == address(0) || creditAccounts[borrower] != address(0))
            revert ZeroAddressOrUserAlreadyHasAccountException(); // F:[CM-7]
        creditAccounts[borrower] = creditAccount; // F:[CM-7]
    }

    //
    // GETTERS
    //

    /// @dev Computes amounts that must be sent to various addresses before closing an account
    /// @param totalValue Credit Accounts total value in underlying
    /// @param closureActionType Type of account closure
    ///        * CLOSE_ACCOUNT: The account is healthy and is closed normally
    ///        * LIQUIDATE_ACCOUNT: The account is unhealthy and is being liquidated to avoid bad debt
    ///        * LIQUIDATE_EXPIRED_ACCOUNT: The account has expired and is being liquidated (lowered liquidation premium)
    ///        * LIQUIDATE_PAUSED: The account is liquidated while the system is paused due to emergency (no liquidation premium)
    /// @param borrowedAmount Credit Account's debt principal
    /// @param borrowedAmountWithInterest Credit Account's debt principal + interest
    /// @return amountToPool Amount of underlying to be sent to the pool
    /// @return remainingFunds Amount of underlying to be sent to the borrower (only applicable to liquidations)
    /// @return profit Protocol's profit from fees (if any)
    /// @return loss Protocol's loss from bad debt (if any)
    function calcClosePayments(
        uint256 totalValue,
        ClosureAction closureActionType,
        uint256 borrowedAmount,
        uint256 borrowedAmountWithInterest
    )
        public
        view
        override
        returns (
            uint256 amountToPool,
            uint256 remainingFunds,
            uint256 profit,
            uint256 loss
        )
    {
        // The amount to be paid to pool is computed with fees included
        // The pool will compute the amount of Diesel tokens to treasury
        // based on profit
        amountToPool =
            borrowedAmountWithInterest +
            ((borrowedAmountWithInterest - borrowedAmount) *
                slot1.feeInterest) /
            PERCENTAGE_FACTOR; // F:[CM-43]

        if (
            closureActionType == ClosureAction.LIQUIDATE_ACCOUNT ||
            closureActionType == ClosureAction.LIQUIDATE_EXPIRED_ACCOUNT ||
            closureActionType == ClosureAction.LIQUIDATE_PAUSED
        ) {
            // LIQUIDATION CASE
            uint256 totalFunds;

            // During liquidation, totalValue of the account is discounted
            // by (1 - liquidationPremium). This means that totalValue * liquidationPremium
            // is removed from all calculations and can be claimed by the liquidator at the end of transaction

            // The liquidation premium depends on liquidation type:
            // * For normal unhealthy account liquidations, usual premium applies
            // * For expiry liquidations, the premium is typically reduced,
            //   since the account does not risk bad debt, so the liquidation
            //   is not as urgent
            // * For emergency (paused) liquidations, there is not premium.
            //   This is done in order to preserve fairness, as emergency liquidator
            //   is a priviledged role. Any compensation to the emergency liquidator must
            //   be coordinated with the DAO out of band.

            if (closureActionType == ClosureAction.LIQUIDATE_ACCOUNT) {
                // UNHEALTHY ACCOUNT CASE
                totalFunds =
                    (totalValue * slot1.liquidationDiscount) /
                    PERCENTAGE_FACTOR; // F:[CM-43]

                amountToPool +=
                    (totalValue * slot1.feeLiquidation) /
                    PERCENTAGE_FACTOR; // F:[CM-43]
            } else if (
                closureActionType == ClosureAction.LIQUIDATE_EXPIRED_ACCOUNT
            ) {
                // EXPIRED ACCOUNT CASE
                totalFunds =
                    (totalValue * slot1.liquidationDiscountExpired) /
                    PERCENTAGE_FACTOR; // F:[CM-43]

                amountToPool +=
                    (totalValue * slot1.feeLiquidationExpired) /
                    PERCENTAGE_FACTOR; // F:[CM-43]
            } else {
                // PAUSED CASE
                totalFunds = totalValue; // F: [CM-43]
                amountToPool +=
                    (totalValue * slot1.feeLiquidation) /
                    PERCENTAGE_FACTOR; // F:[CM-43]
            }

            // If there are any funds left after all respective payments (this
            // includes the liquidation premium, since totalFunds is already
            // discounted from totalValue), they are recorded to remainingFunds
            // and will later be sent to the borrower.

            // If totalFunds is not sufficient to cover the entire payment to pool,
            // the Credit Manager will repay what it can. When totalFunds >= debt + interest,
            // this simply means that part of protocol fees will be waived (profit is reduced). Otherwise,
            // there is bad debt (loss > 0).

            // Since values are compared to each other before subtracting,
            // this can be marked as unchecked to optimize gas

            unchecked {
                if (totalFunds > amountToPool) {
                    remainingFunds = totalFunds - amountToPool - 1; // F:[CM-43]
                } else {
                    amountToPool = totalFunds; // F:[CM-43]
                }

                if (totalFunds >= borrowedAmountWithInterest) {
                    profit = amountToPool - borrowedAmountWithInterest; // F:[CM-43]
                } else {
                    loss = borrowedAmountWithInterest - amountToPool; // F:[CM-43]
                }
            }
        } else {
            // CLOSURE CASE

            // During closure, it is assumed that the user has enough to cover
            // the principal + interest + fees. closeCreditAccount, thus, will
            // attempt to charge them the entire amount.

            // Since in this case amountToPool + borrowedAmountWithInterest + fee,
            // this block can be marked as unchecked

            unchecked {
                profit = amountToPool - borrowedAmountWithInterest; // F:[CM-43]
            }
        }
    }

    /// @dev Returns the collateral token at requested index and its liquidation threshold
    /// @param id The index of token to return
    function collateralTokens(uint256 id)
        public
        view
        returns (address token, uint16 liquidationThreshold)
    {
        // Collateral tokens are stored under their masks rather than
        // indicies, so this is simply a convenience function that wraps
        // the getter by mask
        return collateralTokensByMask(1 << id);
    }

    /// @dev Returns the collateral token with requested mask and its liquidationThreshold
    /// @param tokenMask Token mask corresponding to the token
    function collateralTokensByMask(uint256 tokenMask)
        public
        view
        override
        returns (address token, uint16 liquidationThreshold)
    {
        // The underlying is a special case and its mask is always 1
        if (tokenMask == 1) {
            token = underlying; // F:[CM-47]
            liquidationThreshold = slot1.ltUnderlying;
        } else {
            // The address and LT of a collateral token are compressed into a single uint256
            // The first 160 bits of the number is the address, and any bits after that are interpreted as LT
            uint256 collateralTokenCompressed = collateralTokensCompressed[
                tokenMask
            ]; // F:[CM-47]

            // Unsafe downcasting is justified, since the right 160 bits of collateralTokenCompressed
            // always stores the uint160 encoded address and the extra bits need to be cut
            token = address(uint160(collateralTokenCompressed)); // F:[CM-47]
            liquidationThreshold = (collateralTokenCompressed >> ADDR_BIT_SIZE)
                .toUint16(); // F:[CM-47]
        }
    }

    /// @dev Returns the address of a borrower's Credit Account, or reverts if there is none.
    /// @param borrower Borrower's address
    function getCreditAccountOrRevert(address borrower)
        public
        view
        override
        returns (address result)
    {
        result = creditAccounts[borrower]; // F:[CM-48]
        if (result == address(0)) revert HasNoOpenedAccountException(); // F:[CM-48]
    }

    /// @dev Calculates the debt accrued by a Credit Account
    /// @param creditAccount Address of the Credit Account
    /// @return borrowedAmount The debt principal
    /// @return borrowedAmountWithInterest The debt principal + accrued interest
    /// @return borrowedAmountWithInterestAndFees The debt principal + accrued interest and protocol fees
    function calcCreditAccountAccruedInterest(address creditAccount)
        public
        view
        override
        returns (
            uint256 borrowedAmount,
            uint256 borrowedAmountWithInterest,
            uint256 borrowedAmountWithInterestAndFees
        )
    {
        uint256 cumulativeIndexAtOpen_RAY;
        uint256 cumulativeIndexNow_RAY;
        (
            borrowedAmount,
            cumulativeIndexAtOpen_RAY,
            cumulativeIndexNow_RAY
        ) = _getCreditAccountParameters(creditAccount); // F:[CM-49]

        // Interest is never stored and is always computed dynamically
        // as the difference between the current cumulative index of the pool
        // and the cumulative index recorded in the Credit Account
        borrowedAmountWithInterest =
            (borrowedAmount * cumulativeIndexNow_RAY) /
            cumulativeIndexAtOpen_RAY; // F:[CM-49]

        // Fees are computed as a percentage of interest
        borrowedAmountWithInterestAndFees =
            borrowedAmountWithInterest +
            ((borrowedAmountWithInterest - borrowedAmount) *
                slot1.feeInterest) /
            PERCENTAGE_FACTOR; // F: [CM-49]
    }

    /// @dev Returns the parameters of the Credit Account required to calculate debt
    /// @param creditAccount Address of the Credit Account
    /// @return borrowedAmount Debt principal amount
    /// @return cumulativeIndexAtOpen_RAY The cumulative index value used to calculate
    ///         interest in conjunction  with current pool index. Not necessarily the index
    ///         value at the time of account opening, since it can be updated by manageDebt.
    /// @return cumulativeIndexNow_RAY Current cumulative index of the pool
    function _getCreditAccountParameters(address creditAccount)
        internal
        view
        returns (
            uint256 borrowedAmount,
            uint256 cumulativeIndexAtOpen_RAY,
            uint256 cumulativeIndexNow_RAY
        )
    {
        borrowedAmount = ICreditAccount(creditAccount).borrowedAmount(); // F:[CM-49,50]
        cumulativeIndexAtOpen_RAY = ICreditAccount(creditAccount)
            .cumulativeIndexAtOpen(); // F:[CM-49,50]
        cumulativeIndexNow_RAY = IPoolService(pool).calcLinearCumulative_RAY(); // F:[CM-49,50]
    }

    /// @dev Returns the liquidation threshold for the provided token
    /// @param token Token to retrieve the LT for
    function liquidationThresholds(address token)
        public
        view
        override
        returns (uint16 lt)
    {
        // Underlying is a special case and its LT is stored separately
        if (token == underlying) return slot1.ltUnderlying; // F:[CM-47]

        uint256 tokenMask = tokenMasksMap(token);
        if (tokenMask == 0) revert TokenNotAllowedException();
        (, lt) = collateralTokensByMask(tokenMask); // F:[CM-47]
    }

    /// @dev Returns the mask for the provided token
    /// @param token Token to returns the mask for
    function tokenMasksMap(address token)
        public
        view
        override
        returns (uint256 mask)
    {
        mask = (token == underlying) ? 1 : tokenMasksMapInternal[token];
    }

    /// @dev Returns the largest token index out of enabled tokens, based on a mask
    /// @param mask Bit mask encoding enabled tokens
    /// @return index Largest index out of the set of enabled tokens
    function _getMaxIndex(uint256 mask) internal pure returns (uint256 index) {
        if (mask == 1) return 0;

        // Performs a binary search within the range of all token indices
        // If right-shifting a mask by n turns it into 1, then n is the largest index

        uint256 high = 256;
        uint256 low = 1;

        while (true) {
            index = (high + low) >> 1;
            uint256 testMask = 1 << index;

            if (testMask & mask != 0 && (mask >> index == 1)) break;

            if (testMask >= mask) {
                high = index;
            } else {
                low = index;
            }
        }
    }

    /// @dev Returns the fee parameters of the Credit Manager
    /// @return feeInterest Percentage of interest taken by the protocol as profit
    /// @return feeLiquidation Percentage of account value taken by the protocol as profit
    ///         during unhealthy account liquidations
    /// @return liquidationDiscount Multiplier that reduces the effective totalValue during unhealthy account liquidations,
    ///         allowing the liquidator to take the unaccounted for remainder as premium. Equal to (1 - liquidationPremium)
    /// @return feeLiquidationExpired Percentage of account value taken by the protocol as profit
    ///         during expired account liquidations
    /// @return liquidationDiscountExpired Multiplier that reduces the effective totalValue during expired account liquidations,
    ///         allowing the liquidator to take the unaccounted for remainder as premium. Equal to (1 - liquidationPremiumExpired)
    function fees()
        external
        view
        override
        returns (
            uint16 feeInterest,
            uint16 feeLiquidation,
            uint16 liquidationDiscount,
            uint16 feeLiquidationExpired,
            uint16 liquidationDiscountExpired
        )
    {
        feeInterest = slot1.feeInterest; // F:[CM-51]
        feeLiquidation = slot1.feeLiquidation; // F:[CM-51]
        liquidationDiscount = slot1.liquidationDiscount; // F:[CM-51]
        feeLiquidationExpired = slot1.feeLiquidationExpired; // F:[CM-51]
        liquidationDiscountExpired = slot1.liquidationDiscountExpired; // F:[CM-51]
    }

    /// @dev Returns the price oracle used to evaluate collateral tokens
    function priceOracle() external view override returns (IPriceOracleV2) {
        return slot1.priceOracle;
    }

    //
    // CONFIGURATION
    //
    // The following function change vital Credit Manager parameters
    // and can only be called by the Credit Configurator
    //

    /// @dev Adds a token to the list of collateral tokens
    /// @param token Address of the token to add
    function addToken(address token)
        external
        creditConfiguratorOnly // F:[CM-4]
    {
        _addToken(token); // F:[CM-52]
    }

    /// @dev IMPLEMENTATION: addToken
    /// @param token Address of the token to add
    function _addToken(address token) internal {
        // Checks that the token is not already known (has an associated token mask)
        if (tokenMasksMapInternal[token] > 0)
            revert TokenAlreadyAddedException(); // F:[CM-52]

        // Checks that there aren't too many tokens
        // Since token masks are 256 bit numbers with each bit corresponding to 1 token,
        // only at most 256 are supported
        if (collateralTokensCount >= 256) revert TooManyTokensException(); // F:[CM-52]

        // The tokenMask of a token is a bit mask with 1 at position corresponding to its index
        // (i.e. 2 ** index or 1 << index)
        uint256 tokenMask = 1 << collateralTokensCount;
        tokenMasksMapInternal[token] = tokenMask; // F:[CM-53]
        collateralTokensCompressed[tokenMask] = uint256(uint160(token)); // F:[CM-47]
        collateralTokensCount++; // F:[CM-47]
    }

    /// @dev Sets fees and premiums
    /// @param _feeInterest Percentage of interest taken by the protocol as profit
    /// @param _feeLiquidation Percentage of account value taken by the protocol as profit
    ///         during unhealthy account liquidations
    /// @param _liquidationDiscount Multiplier that reduces the effective totalValue during unhealthy account liquidations,
    ///         allowing the liquidator to take the unaccounted for remainder as premium. Equal to (1 - liquidationPremium)
    /// @param _feeLiquidationExpired Percentage of account value taken by the protocol as profit
    ///         during expired account liquidations
    /// @param _liquidationDiscountExpired Multiplier that reduces the effective totalValue during expired account liquidations,
    ///         allowing the liquidator to take the unaccounted for remainder as premium. Equal to (1 - liquidationPremiumExpired)
    function setParams(
        uint16 _feeInterest,
        uint16 _feeLiquidation,
        uint16 _liquidationDiscount,
        uint16 _feeLiquidationExpired,
        uint16 _liquidationDiscountExpired
    )
        external
        creditConfiguratorOnly // F:[CM-4]
    {
        slot1.feeInterest = _feeInterest; // F:[CM-51]
        slot1.feeLiquidation = _feeLiquidation; // F:[CM-51]
        slot1.liquidationDiscount = _liquidationDiscount; // F:[CM-51]
        slot1.feeLiquidationExpired = _feeLiquidationExpired; // F:[CM-51]
        slot1.liquidationDiscountExpired = _liquidationDiscountExpired; // F:[CM-51]
    }

    //
    // CONFIGURATION
    //

    /// @dev Sets the liquidation threshold for a collateral token
    /// @notice Liquidation thresholds are weights used to compute
    ///         TWV with. They denote the risk of the token, with
    ///         more volatile and unpredictable tokens having lower LTs.
    /// @param token The collateral token to set the LT for
    /// @param liquidationThreshold The new LT
    function setLiquidationThreshold(address token, uint16 liquidationThreshold)
        external
        creditConfiguratorOnly // F:[CM-4]
    {
        // Underlying is a special case and its LT is stored in Slot1,
        // to be accessed frequently
        if (token == underlying) {
            // F:[CM-47]
            slot1.ltUnderlying = liquidationThreshold; // F:[CM-47]
        } else {
            uint256 tokenMask = tokenMasksMap(token); // F:[CM-47, 54]
            if (tokenMask == 0) revert TokenNotAllowedException();

            // Token address and liquidation threshold are encoded into a single uint256
            collateralTokensCompressed[tokenMask] =
                (collateralTokensCompressed[tokenMask] & type(uint160).max) |
                (uint256(liquidationThreshold) << 160); // F:[CM-47]
        }
    }

    /// @dev Sets the forbidden token mask
    /// @param _forbidMask The new bit mask encoding the tokens that are forbidden
    /// @notice Forbidden tokens are counted as collateral during health checks, however, they cannot be enabled
    ///         or received as a result of adapter operation anymore. This means that a token can never be
    ///         acquired through adapter operations after being forbidden. Accounts that have enabled forbidden tokens
    ///         also can't borrow any additional funds until they disable those tokens.
    function setForbidMask(uint256 _forbidMask)
        external
        creditConfiguratorOnly // F:[CM-4]
    {
        forbiddenTokenMask = _forbidMask; // F:[CM-55]
    }

    /// @dev Sets the maximal number of enabled tokens on a single Credit Account.
    /// @param newMaxEnabledTokens The new enabled token limit.
    function setMaxEnabledTokens(uint8 newMaxEnabledTokens)
        external
        creditConfiguratorOnly // F: [CM-4]
    {
        maxAllowedEnabledTokenLength = newMaxEnabledTokens; // F: [CC-37]
    }

    /// @dev Sets the link between an adapter and its corresponding targetContract
    /// @param adapter Address of the adapter to be used to access the target contract
    /// @param targetContract A 3rd-party contract for which the adapter is set
    /// @notice The function can be called with (adapter, address(0)) and (address(0), targetContract)
    ///         to disallow a particular target or adapter, since this would set values in respective
    ///         mappings to address(0).
    function changeContractAllowance(address adapter, address targetContract)
        external
        creditConfiguratorOnly
    {
        if (adapter != address(0)) {
            adapterToContract[adapter] = targetContract; // F:[CM-56]
        }
        if (targetContract != address(0)) {
            contractToAdapter[targetContract] = adapter; // F:[CM-56]
        }

        // The universal adapter can potentially target multiple contracts,
        // so it is set using a special vanity address
        if (targetContract == UNIVERSAL_CONTRACT) {
            universalAdapter = adapter; // F:[CM-56]
        }
    }

    /// @dev Sets the Credit Facade
    /// @param _creditFacade Address of the new Credit Facade
    function upgradeCreditFacade(address _creditFacade)
        external
        creditConfiguratorOnly // F:[CM-4]
    {
        creditFacade = _creditFacade;
    }

    /// @dev Sets the Price Oracle
    /// @param _priceOracle Address of the new Price Oracle
    function upgradePriceOracle(address _priceOracle)
        external
        creditConfiguratorOnly // F:[CM-4]
    {
        slot1.priceOracle = IPriceOracleV2(_priceOracle);
    }

    /// @dev Adds an address to the list of emergency liquidators
    /// @param liquidator Address to add to the list
    function addEmergencyLiquidator(address liquidator)
        external
        creditConfiguratorOnly // F:[CM-4]
    {
        canLiquidateWhilePaused[liquidator] = true;
    }

    /// @dev Removes an address from the list of emergency liquidators
    /// @param liquidator Address to remove from the list
    function removeEmergencyLiquidator(address liquidator)
        external
        creditConfiguratorOnly // F: [CM-4]
    {
        canLiquidateWhilePaused[liquidator] = false;
    }

    /// @dev Sets a new Credit Configurator
    /// @param _creditConfigurator Address of the new Credit Configurator
    function setConfigurator(address _creditConfigurator)
        external
        creditConfiguratorOnly // F:[CM-4]
    {
        creditConfigurator = _creditConfigurator; // F:[CM-58]
        emit NewConfigurator(_creditConfigurator); // F:[CM-58]
    }
}
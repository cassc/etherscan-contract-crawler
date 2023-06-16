// SPDX-License-Identifier: BUSL-1.1
// Gearbox Protocol. Generalized leverage for DeFi protocols
// (c) Gearbox Holdings, 2022
pragma solidity ^0.8.10;

import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import { Address } from "@openzeppelin/contracts/utils/Address.sol";
import { EnumerableSet } from "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";
import { ReentrancyGuard } from "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import { SafeCast } from "@openzeppelin/contracts/utils/math/SafeCast.sol";

//  DATA
import { MultiCall } from "../libraries/MultiCall.sol";
import { Balance } from "../libraries/Balances.sol";

/// INTERFACES
import { ICreditFacade, ICreditFacadeExtended } from "../interfaces/ICreditFacade.sol";
import { ICreditManagerV2, ClosureAction } from "../interfaces/ICreditManagerV2.sol";
import { IPriceOracleV2 } from "../interfaces/IPriceOracle.sol";
import { IDegenNFT } from "../interfaces/IDegenNFT.sol";
import { IWETH } from "../interfaces/external/IWETH.sol";
import { IBlacklistHelper } from "../interfaces/IBlacklistHelper.sol";
import { IPausable } from "../interfaces/IPausable.sol";

// CONSTANTS

import { LEVERAGE_DECIMALS } from "../libraries/Constants.sol";
import { PERCENTAGE_FACTOR } from "../libraries/PercentageMath.sol";

// EXCEPTIONS
import { ZeroAddressException } from "../interfaces/IErrors.sol";

struct Params {
    /// @dev Maximal amount of new debt that can be taken per block
    uint128 maxBorrowedAmountPerBlock;
    /// @dev True if increasing debt is forbidden
    bool isIncreaseDebtForbidden;
    /// @dev Timestamp of the next expiration (for expirable Credit Facades only)
    uint40 expirationDate;
    /// @dev Liquidation discount applied to totalValue for emergency liquidator
    uint16 emergencyLiquidationDiscount;
}

struct Limits {
    /// @dev Minimal borrowed amount per credit account
    uint128 minBorrowedAmount;
    /// @dev Maximum borrowed amount per credit account
    uint128 maxBorrowedAmount;
}

struct CumulativeLossParams {
    /// @dev Current cumulative loss from all bad debt liquidations
    uint128 currentCumulativeLoss;
    /// @dev Max cumulative loss accrued before the system is paused
    uint128 maxCumulativeLoss;
}

struct TotalDebt {
    /// @dev Current total borrowing
    uint128 currentTotalDebt;
    /// @dev Total borrowing limit
    uint128 totalDebtLimit;
}

/// @title CreditFacade
/// @notice User interface for interacting with Credit Manager
/// @dev Direct interaction with the Credit Manager is forbidden, but Credit Facade provides all the needed
///      account management functions: open / close / liquidate / addCollateral / manageDebt / multicall.
///      The latter allows to perform multiple actions within a single transaction, followed by a single
///      collateral check in the end.
contract CreditFacade is ICreditFacade, ReentrancyGuard {
    using EnumerableSet for EnumerableSet.AddressSet;
    using Address for address;
    using SafeCast for uint256;

    /// @dev Credit Manager connected to this Credit Facade
    ICreditManagerV2 public immutable creditManager;

    /// @dev Whether the whitelisted mode is active
    bool public immutable whitelisted;

    /// @dev Whether the Credit Manager's underlying has blacklisting
    bool public immutable isBlacklistableUnderlying;

    /// @dev Whether the Credit Facade implements expirable logic
    bool public immutable expirable;

    /// @dev Keeps frequently accessed parameters for storage access optimization
    Params public override params;

    /// @dev Keeps borrowing limits together for storage access optimization
    Limits public override limits;

    /// @dev Keeps parameters that are used to pause the system after too much bad debt over a short period
    CumulativeLossParams public override lossParams;

    TotalDebt public override totalDebt;

    /// @dev Address of the underlying token
    address public immutable underlying;

    /// @dev A map that stores whether a user allows a transfer of an account from another user to themselves
    mapping(address => mapping(address => bool))
        public
        override transfersAllowed;

    /// @dev Address of WETH
    address public immutable wethAddress;

    /// @dev Address of the DegenNFT that gatekeeps account openings in whitelisted mode
    address public immutable override degenNFT;

    /// @dev Address of the BlacklistHelper if underlying is blacklistable, otherwise address(0)
    address public immutable override blacklistHelper;

    /// @dev Address of the pool connected to the Credit Manager
    address public immutable pool;

    /// @dev Stores in a compressed state the last block where borrowing happened and the total amount borrowed in that block
    uint256 internal totalBorrowedInBlock;

    /// @dev Contract version
    uint256 public constant override version = 2_10;

    /// @dev Restricts actions for users with opened credit accounts only
    modifier creditConfiguratorOnly() {
        if (msg.sender != creditManager.creditConfigurator())
            revert CreditConfiguratorOnlyException();

        _;
    }

    /// @dev Initializes creditFacade and connects it with CreditManager
    /// @param _creditManager address of Credit Manager
    /// @param _degenNFT address of the DegenNFT or address(0) if whitelisted mode is not used
    /// @param _blacklistHelper address of the funds recovery contract for blacklistable underlyings.
    ///                         Must be address(0) is the underlying is not blacklistable
    /// @param _expirable Whether the CreditFacade can expire and implements expiration-related logic
    constructor(
        address _creditManager,
        address _degenNFT,
        address _blacklistHelper,
        bool _expirable
    ) {
        // Additional check that _creditManager is not address(0)
        if (_creditManager == address(0)) revert ZeroAddressException(); // F:[FA-1]

        creditManager = ICreditManagerV2(_creditManager); // F:[FA-1A]
        underlying = ICreditManagerV2(_creditManager).underlying(); // F:[FA-1A]
        wethAddress = ICreditManagerV2(_creditManager).wethAddress(); // F:[FA-1A]
        pool = ICreditManagerV2(_creditManager).pool();

        degenNFT = _degenNFT; // F:[FA-1A]
        whitelisted = _degenNFT != address(0); // F:[FA-1A]

        blacklistHelper = _blacklistHelper;
        isBlacklistableUnderlying = _blacklistHelper != address(0);
        if (_blacklistHelper != address(0)) {
            emit BlacklistHelperSet(_blacklistHelper);
        }

        expirable = _expirable;

        totalDebt.totalDebtLimit = type(uint128).max;
    }

    // Notice: ETH interactions
    // CreditFacade implements a new flow for interacting with WETH compared to V1.
    // During all actions, any sent ETH value is automatically wrapped into WETH and
    // sent back to the message sender. This makes the protocol's behavior regarding
    // ETH more flexible and consistent, since there is no need to pre-wrap WETH before
    // interacting with the protocol, and no need to compute how much unused ETH has to be sent back.

    /// @dev Opens credit account, borrows funds from the pool and pulls collateral
    /// without any additional action.
    /// - Performs sanity checks to determine whether opening an account is allowed
    /// - Wraps ETH to WETH and sends it msg. sender is value > 0
    /// - Requests CreditManager to open a Credit Account with a specified borrowed amount
    /// - Transfers collateral in the underlying asset from the user
    /// - Emits OpenCreditAccount event
    ///
    /// More info: https://dev.gearbox.fi/developers/credit/credit_manager#open-credit-account
    ///
    /// @param amount The amount of collateral provided by the borrower
    /// @param onBehalfOf The address to open an account for. Transfers to it have to be allowed if
    /// msg.sender != obBehalfOf
    /// @param leverageFactor Percentage of the user's own funds to borrow. 100 is equal to 100% - borrows the same amount
    /// as the user's own collateral, equivalent to 2x leverage.
    /// @param referralCode Referral code that is used for potential rewards. 0 if no referral code provided.
    function openCreditAccount(
        uint256 amount,
        address onBehalfOf,
        uint16 leverageFactor,
        uint16 referralCode
    ) external payable override nonReentrant {
        uint256 borrowedAmount = (amount * leverageFactor) / LEVERAGE_DECIMALS; // F:[FA-5]

        // Checks whether the new borrowed amount does not violate the block limit
        _checkAndUpdateBorrowedBlockLimit(borrowedAmount); // F:[FA-11A]

        // Checks that the borrowed amount is within the borrowing limits
        _revertIfOutOfBorrowedLimits(borrowedAmount); // F:[FA-11B]

        // Checks that the msg.sender can open an account for onBehalfOf
        _revertIfOpenCreditAccountNotAllowed(onBehalfOf); // F:[FA-4A, 4B, 57]

        // Wraps ETH and sends it back to msg.sender
        _wrapETH(); // F:[FA-3A]

        // Checks that the total debt limit is not exceeded and increases total debt
        _checkAndUpdateTotalDebt(borrowedAmount, true); // F: [FA-11C]

        // Gets the LT of the underlying
        (, uint256 ltu) = creditManager.collateralTokens(0); // F:[FA-6]

        // In order for the account to pass the health check after opening,
        // the inequality "(amount + borrowedAmount) * LTU > borrowedAmount" must hold
        // this can be transformed into "amount * LTU > borrowedAmount * (1 - LTU)"
        if (amount * ltu <= borrowedAmount * (PERCENTAGE_FACTOR - ltu))
            revert NotEnoughCollateralException(); // F:[FA-6]

        // Opens credit accnount and borrows funds from the pool
        // Returns the new credit account's address
        address creditAccount = creditManager.openCreditAccount(
            borrowedAmount,
            onBehalfOf
        ); // F:[FA-5]

        // Emits openCreditAccount event before adding collateral, so that order of events is correct
        emit OpenCreditAccount(
            onBehalfOf,
            creditAccount,
            borrowedAmount,
            referralCode
        ); // F:[FA-5]

        // Transfers collateral from the user to the new Credit Account
        addCollateral(onBehalfOf, creditAccount, underlying, amount); // F:[FA-5]
    }

    /// @dev Opens a Credit Account and runs a batch of operations in a multicall
    /// - Opens credit account with the desired borrowed amount
    /// - Executes all operations in a multicall
    /// - Checks that the new account has enough collateral
    /// - Emits OpenCreditAccount event
    ///
    /// @param borrowedAmount Debt size
    /// @param onBehalfOf The address to open an account for. Transfers to it have to be allowed if
    /// msg.sender != onBehalfOf
    /// @param calls The array of MultiCall structs encoding the required operations. Generally must have
    /// at least a call to addCollateral, as otherwise the health check at the end will fail.
    /// @param referralCode Referral code which is used for potential rewards. 0 if no referral code provided
    function openCreditAccountMulticall(
        uint256 borrowedAmount,
        address onBehalfOf,
        MultiCall[] calldata calls,
        uint16 referralCode
    ) external payable override nonReentrant {
        // Checks whether the new borrowed amount does not violate the block limit
        _checkAndUpdateBorrowedBlockLimit(borrowedAmount); // F:[FA-11]

        // Checks that the msg.sender can open an account for onBehalfOf
        _revertIfOpenCreditAccountNotAllowed(onBehalfOf); // F:[FA-4A, 4B, 57]

        // Checks that the borrowed amount is within the borrowing limits
        _revertIfOutOfBorrowedLimits(borrowedAmount); // F:[FA-11B]

        // Wraps ETH and sends it back to msg.sender address
        _wrapETH(); // F:[FA-3B]

        // Checks that the total debt limit is not exceeded and increases total debt
        _checkAndUpdateTotalDebt(borrowedAmount, true); // F: [FA-11C]

        // Requests the Credit Manager to open a Credit Account
        address creditAccount = creditManager.openCreditAccount(
            borrowedAmount,
            onBehalfOf
        ); // F:[FA-8]

        // emits a new event
        emit OpenCreditAccount(
            onBehalfOf,
            creditAccount,
            borrowedAmount,
            referralCode
        ); // F:[FA-8]

        // F:[FA-10]: no free flashloans through opening a Credit Account
        // and immediately decreasing debt
        if (calls.length != 0)
            _multicall(calls, onBehalfOf, creditAccount, false, true); // F:[FA-8]

        // Checks that the new credit account has enough collateral to cover the debt
        creditManager.fullCollateralCheck(creditAccount); // F:[FA-8, 9]
    }

    /// @dev A version of `closeCreditAccount` with `convertWETH` parameter that is ignored.
    ///      Used for backward compatibility.
    function closeCreditAccount(
        address to,
        uint256 skipTokenMask,
        bool,
        MultiCall[] calldata calls
    ) external payable override nonReentrant {
        _closeCreditAccount(to, skipTokenMask, calls);
    }

    /// @dev Runs a batch of transactions within a multicall and closes the account
    /// - Wraps ETH to WETH and sends it msg.sender if value > 0
    /// - Executes the multicall - the main purpose of a multicall when closing is to convert all assets to underlying
    /// in order to pay the debt.
    /// - Closes credit account:
    ///    + Checks the underlying balance: if it is greater than the amount paid to the pool, transfers the underlying
    ///      from the Credit Account and proceeds. If not, tries to transfer the shortfall from msg.sender.
    ///    + Transfers all enabled assets with non-zero balances to the "to" address, unless they are marked
    ///      to be skipped in skipTokenMask
    /// - Emits a CloseCreditAccount event
    ///
    /// @param to Address to send funds to during account closing
    /// @param skipTokenMask Uint-encoded bit mask where 1's mark tokens that shouldn't be transferred
    /// @param calls The array of MultiCall structs encoding the operations to execute before closing the account.
    function closeCreditAccount(
        address to,
        uint256 skipTokenMask,
        MultiCall[] calldata calls
    ) external payable override nonReentrant {
        _closeCreditAccount(to, skipTokenMask, calls);
    }

    /// @dev IMPLEMENTATION: closeCreditAccount
    function _closeCreditAccount(
        address to,
        uint256 skipTokenMask,
        MultiCall[] calldata calls
    ) internal {
        // Check for existing CA
        address creditAccount = creditManager.getCreditAccountOrRevert(
            msg.sender
        ); // F:[FA-2]

        // Wraps ETH and sends it back to msg.sender
        _wrapETH(); // F:[FA-3C]

        // [FA-13]: Calls to CreditFacade are forbidden during closure
        if (calls.length != 0)
            _multicall(calls, msg.sender, creditAccount, true, false); // F:[FA-2, 12, 13]

        uint256 availableLiquidityBefore = _getAvailableLiquidity();
        (
            uint256 borrowedAmount,
            uint256 borrowAmountWithInterest,

        ) = creditManager.calcCreditAccountAccruedInterest(creditAccount);

        // Requests the Credit manager to close the Credit Account
        creditManager.closeCreditAccount(
            msg.sender,
            ClosureAction.CLOSE_ACCOUNT,
            0,
            msg.sender,
            to,
            skipTokenMask,
            false
        ); // F:[FA-2, 12]

        uint256 availableLiquidityAfter = _getAvailableLiquidity();

        if (
            availableLiquidityAfter <
            availableLiquidityBefore + borrowAmountWithInterest
        ) {
            revert LiquiditySanityCheckException();
        }

        // Decreases the total debt
        _checkAndUpdateTotalDebt(borrowedAmount, false);

        // Emits a CloseCreditAccount event
        emit CloseCreditAccount(msg.sender, to); // F:[FA-12]
    }

    /// @dev Runs a batch of transactions within a multicall and liquidates the account
    /// - Computes the total value and checks that hf < 1. An account can't be liquidated when hf >= 1.
    ///   Total value has to be computed before the multicall, otherwise the liquidator would be able
    ///   to manipulate it.
    /// - Wraps ETH to WETH and sends it to msg.sender (liquidator) if value > 0
    /// - Executes the multicall - the main purpose of a multicall when liquidating is to convert all assets to underlying
    ///   in order to pay the debt.
    /// - Liquidate credit account:
    ///    + Computes the amount that needs to be paid to the pool. If totalValue * liquidationDiscount < borrow + interest + fees,
    ///      only totalValue * liquidationDiscount has to be paid. Since liquidationDiscount < 1, the liquidator can take
    ///      totalValue * (1 - liquidationDiscount) as premium. Also computes the remaining funds to be sent to borrower
    ///      as totalValue * liquidationDiscount - amountToPool.
    ///    + If borrower happens to be blacklisted in the underlying asset, sends funds to the blacklist helper
    ///      and marks them as claimable by the borrower.
    ///    + Checks the underlying balance: if it is greater than amountToPool + remainingFunds, transfers the underlying
    ///      from the Credit Account and proceeds. If not, tries to transfer the shortfall from the liquidator.
    ///    + Transfers all enabled assets with non-zero balances to the "to" address, unless they are marked
    ///      to be skipped in skipTokenMask. If the liquidator is confident that all assets were converted
    ///      during the multicall, they can set the mask to uint256.max - 1, to only transfer the underlying
    /// - Emits LiquidateCreditAccount event
    ///
    /// @param to Address to send funds to after liquidation
    /// @param skipTokenMask Uint-encoded bit mask where 1's mark tokens that shouldn't be transferred
    /// @param calls The array of MultiCall structs encoding the operations to execute before liquidating the account.
    function liquidateCreditAccount(
        address borrower,
        address to,
        uint256 skipTokenMask,
        MultiCall[] calldata calls
    ) external payable override nonReentrant {
        _liquidateCreditAccount(borrower, to, skipTokenMask, calls);
    }

    /// @dev A version of `liquidateCreditAccount` with `convertWETH` parameter that is ignored.
    ///      Used for backward compatibility.
    function liquidateCreditAccount(
        address borrower,
        address to,
        uint256 skipTokenMask,
        bool,
        MultiCall[] calldata calls
    ) external payable override nonReentrant {
        _liquidateCreditAccount(borrower, to, skipTokenMask, calls);
    }

    /// @dev IMPLEMENTATION: liquidateCreditAccount
    function _liquidateCreditAccount(
        address borrower,
        address to,
        uint256 skipTokenMask,
        MultiCall[] calldata calls
    ) internal {
        // Checks that the CA exists to revert early for late liquidations and save gas
        address creditAccount = creditManager.getCreditAccountOrRevert(
            borrower
        ); // F:[FA-2]

        // Checks that the to address is not zero
        if (to == address(0)) revert ZeroAddressException(); // F:[FA-16A]

        // Checks that the account hf < 1 and computes the totalValue
        // before the multicall
        (bool isLiquidatable, uint256 totalValue) = _isAccountLiquidatable(
            creditAccount
        ); // F:[FA-14]

        // An account can't be liquidated if hf >= 1
        if (!isLiquidatable)
            revert CantLiquidateWithSuchHealthFactorException(); // F:[FA-14]

        // Wraps ETH and sends it back to msg.sender
        _wrapETH(); // F:[FA-3D]

        // Checks if the liquidation is done while the contract is paused
        bool emergencyLiquidation = _checkIfEmergencyLiquidator(true);

        if (calls.length != 0)
            _multicall(calls, borrower, creditAccount, true, false); // F:[FA-15]

        if (emergencyLiquidation) {
            totalValue =
                (totalValue * params.emergencyLiquidationDiscount) /
                PERCENTAGE_FACTOR;
            _checkIfEmergencyLiquidator(false);
        }

        uint256 remainingFunds = _closeLiquidatedAccount(
            totalValue,
            creditAccount,
            borrower,
            to,
            skipTokenMask,
            false
        );

        emit LiquidateCreditAccount(borrower, msg.sender, to, remainingFunds); // F:[FA-15]
    }

    /// @dev Runs a batch of transactions within a multicall and liquidates the account when
    /// this Credit Facade is expired
    /// The general flow of liquidation is nearly the same as normal liquidations, with two main differences:
    ///     - An account can be liquidated on an expired Credit Facade even with hf > 1. However,
    ///       no accounts can be liquidated through this function if the Credit Facade is not expired.
    ///     - Liquidation premiums and fees for liquidating expired accounts are reduced.
    /// It is still possible to normally liquidate an underwater Credit Account, even when the Credit Facade
    /// is expired.
    /// @param to Address to send funds to after liquidation
    /// @param skipTokenMask Uint-encoded bit mask where 1's mark tokens that shouldn't be transferred
    /// @param calls The array of MultiCall structs encoding the operations to execute before liquidating the account.
    /// @notice See more at https://dev.gearbox.fi/docs/documentation/credit/liquidation#liquidating-accounts-by-expiration
    function liquidateExpiredCreditAccount(
        address borrower,
        address to,
        uint256 skipTokenMask,
        MultiCall[] calldata calls
    ) external payable override nonReentrant {
        _liquidateExpiredCreditAccount(borrower, to, skipTokenMask, calls);
    }

    /// @dev A version of `liquidateExpiredCreditAccount` with `convertWETH` parameter that is ignored.
    ///      Used for backward compatibility.
    function liquidateExpiredCreditAccount(
        address borrower,
        address to,
        uint256 skipTokenMask,
        bool,
        MultiCall[] calldata calls
    ) external payable override nonReentrant {
        _liquidateExpiredCreditAccount(borrower, to, skipTokenMask, calls);
    }

    /// @dev IMPLEMENTATION: liquidateExpiredCreditAccount
    function _liquidateExpiredCreditAccount(
        address borrower,
        address to,
        uint256 skipTokenMask,
        MultiCall[] calldata calls
    ) internal {
        // Checks that the CA exists to revert early for late liquidations and save gas
        address creditAccount = creditManager.getCreditAccountOrRevert(
            borrower
        );

        // Checks that the to address is not zero
        if (to == address(0)) revert ZeroAddressException();

        // Checks that this Credit Facade is expired and reverts if not
        if (!_isExpired()) {
            revert CantLiquidateNonExpiredException(); // F: [FA-47,48]
        }

        // Calculates the total value of an account
        (uint256 totalValue, ) = calcTotalValue(creditAccount);

        // Wraps ETH and sends it back to msg.sender address
        _wrapETH();

        // Checks if the liquidation is done while the contract is paused
        bool emergencyLiquidation = _checkIfEmergencyLiquidator(true);

        if (calls.length != 0)
            _multicall(calls, borrower, creditAccount, true, false); // F:[FA-49]

        if (emergencyLiquidation) {
            totalValue =
                (totalValue * params.emergencyLiquidationDiscount) /
                PERCENTAGE_FACTOR;
            _checkIfEmergencyLiquidator(false);
        }

        uint256 remainingFunds = _closeLiquidatedAccount(
            totalValue,
            creditAccount,
            borrower,
            to,
            skipTokenMask,
            true
        );

        // Emits event
        emit LiquidateExpiredCreditAccount(
            borrower,
            msg.sender,
            to,
            remainingFunds
        ); // F:[FA-49]
    }

    /// @dev Closes a liquidated credit account, possibly expired
    function _closeLiquidatedAccount(
        uint256 totalValue,
        address creditAccount,
        address borrower,
        address to,
        uint256 skipTokenMask,
        bool expired
    ) internal returns (uint256 remainingFunds) {
        uint256 helperBalance = _isBlacklisted(borrower);
        // If the borrower is blacklisted, transfer the account to a special recovery contract,
        // so that the attempt to transfer remaining funds to a blacklisted borrower does not
        // break the liquidation. The borrower can retrieve the funds from the recovery contract afterwards.
        if (helperBalance > 0) {
            creditManager.transferAccountOwnership(borrower, blacklistHelper); // F:[FA-56]
        }

        uint256 availableLiquidityBefore = _getAvailableLiquidity();

        (
            uint256 borrowedAmount,
            uint256 borrowAmountWithInterest,

        ) = creditManager.calcCreditAccountAccruedInterest(creditAccount);

        // Liquidates the CA and sends the remaining funds to the borrower or blacklist helper
        remainingFunds = creditManager.closeCreditAccount(
            helperBalance > 0 ? blacklistHelper : borrower,
            expired
                ? ClosureAction.LIQUIDATE_EXPIRED_ACCOUNT
                : ClosureAction.LIQUIDATE_ACCOUNT,
            totalValue,
            msg.sender,
            to,
            skipTokenMask,
            false
        ); // F:[FA-15,49]

        uint256 availableLiquidityAfter = _getAvailableLiquidity();

        uint256 loss = availableLiquidityAfter <
            availableLiquidityBefore + borrowAmountWithInterest
            ? availableLiquidityBefore +
                borrowAmountWithInterest -
                availableLiquidityAfter
            : 0;

        if (loss > 0) {
            params.isIncreaseDebtForbidden = true; // F: [FA-15A]

            lossParams.currentCumulativeLoss += loss.toUint128();
            if (
                lossParams.currentCumulativeLoss > lossParams.maxCumulativeLoss
            ) {
                _pauseCreditManager(); // F: [FA-15B]
            }
            emit IncurLossOnLiquidation(loss);
        }

        // Decreases the total debt
        _checkAndUpdateTotalDebt(borrowedAmount, false);

        /// Credit Facade increases borrower's claimable balance in BlacklistHelper, so the
        /// borrower can recover funds to a different address
        if (helperBalance > 0 && remainingFunds > 1) {
            _increaseClaimableBalance(borrower, helperBalance);
        }
    }

    /// @dev Checks whether borrower is blacklisted in the underlying token and, if so,
    ///      returns non-zero value equal to blacklist helper's balance of underlying
    //       Zero return value always indicates that borrower is not blacklisted
    function _isBlacklisted(address borrower)
        internal
        view
        returns (uint256 helperBalance)
    {
        if (
            isBlacklistableUnderlying &&
            IBlacklistHelper(blacklistHelper).isBlacklisted(
                underlying,
                borrower
            ) // F:[FA-56]
        ) {
            // can't realistically overflow
            unchecked {
                helperBalance =
                    IERC20(underlying).balanceOf(blacklistHelper) +
                    1;
            }
        }
    }

    /// @dev Checks if blacklist helper's balance of underlying increased after liquidation
    ///      and, if so, increases the borrower's claimable balance by the difference
    ///      Not relying on `remainingFunds` to support fee-on-transfer tokens
    function _increaseClaimableBalance(
        address borrower,
        uint256 helperBalanceBefore
    ) internal {
        uint256 helperBalance = IERC20(underlying).balanceOf(blacklistHelper);
        if (helperBalance > helperBalanceBefore) {
            uint256 amount;
            unchecked {
                amount = helperBalance - helperBalanceBefore + 1;
            }
            IBlacklistHelper(blacklistHelper).addClaimable(
                underlying,
                borrower,
                amount
            ); // F:[FA-56]
            emit UnderlyingSentToBlacklistHelper(borrower, amount); // F:[FA-56]
        }
    }

    /// @dev Increases debt for a Credit Account
    /// @param borrower Owner of the account
    /// @param creditAccount CA to increase debt for
    /// @param amount Amount to borrow
    function _increaseDebt(
        address borrower,
        address creditAccount,
        uint256 amount
    ) internal {
        // It is forbidden to take new debt if increaseDebtForbidden mode is enabled
        if (params.isIncreaseDebtForbidden) {
            revert IncreaseDebtForbiddenException();
        } // F:[FA-18C]

        // Checks that the borrowed amount does not violate the per block limit
        _checkAndUpdateBorrowedBlockLimit(amount); // F:[FA-18A]

        // Checks that there are no forbidden tokens, as borrowing
        // is prohibited when forbidden tokens are enabled on the account
        _checkForbiddenTokens(creditAccount);

        // Checks that the total debt limit is not exceeded and increases total debt
        _checkAndUpdateTotalDebt(amount, true); // F: [FA-11C]

        // Requests the Credit Manager to borrow additional funds from the pool
        uint256 newBorrowedAmount = creditManager.manageDebt(
            creditAccount,
            amount,
            true
        ); // F:[FA-17]

        // Checks that the new total borrowed amount is within bounds
        _revertIfOutOfBorrowedLimits(newBorrowedAmount); // F:[FA-18B]

        // Emits event
        emit IncreaseBorrowedAmount(borrower, amount); // F:[FA-17]
    }

    /// @dev Checks that there are no intersections between the user's enabled tokens
    /// and the set of forbidden tokens
    /// @notice The main purpose of forbidding tokens is to prevent exposing
    /// pool funds to dangerous or exploited collateral, without immediately
    /// liquidating accounts that hold the forbidden token
    /// There are two ways pool funds can be exposed:
    ///     - The CA owner tries to swap borrowed funds to the forbidden asset:
    ///       this will be blocked by checkAndEnableToken, which is invoked for tokenOut
    ///       after every operation;
    ///     - The CA owner with an already enabled forbidden token transfers it
    ///       to the account - they can't use addCollateral / enableToken due to checkAndEnableToken,
    ///       but can transfer the token directly when it is enabled and it will be counted in the collateral -
    ///       an borrows against it. This check is used to prevent this.
    /// If the owner has a forbidden token and want to take more debt, they must first
    /// dispose of the token and disable it.
    function _checkForbiddenTokens(address creditAccount) internal view {
        uint256 enabledTokenMask = creditManager.enabledTokensMap(
            creditAccount
        );
        uint256 forbiddenTokenMask = creditManager.forbiddenTokenMask();

        if (enabledTokenMask & forbiddenTokenMask > 0) {
            revert ActionProhibitedWithForbiddenTokensException();
        }
    }

    /// @dev Decreases debt for a Credit Account
    /// @param borrower Owner of the account
    /// @param creditAccount Account to decrease debt for
    /// @param amount Amount to repay
    function _decreaseDebt(
        address borrower,
        address creditAccount,
        uint256 amount
    ) internal {
        (uint256 borrowedAmountBefore, , ) = creditManager
            .calcCreditAccountAccruedInterest(creditAccount);

        // Requests the creditManager to reduce the borrowed sum by amount
        uint256 newBorrowedAmount = creditManager.manageDebt(
            creditAccount,
            amount,
            false
        ); // F:[FA-19]

        // Checks that the new borrowed amount is within limits
        _revertIfOutOfBorrowedLimits(newBorrowedAmount); // F:[FA-20]

        // Decreases total debt
        // Since part of the amount can be used to repay interest,
        // we need to compute the difference between the old and new borrowed amount
        _checkAndUpdateTotalDebt(
            borrowedAmountBefore - newBorrowedAmount,
            false
        );

        // Emits an event
        emit DecreaseBorrowedAmount(borrower, amount); // F:[FA-19]
    }

    /// @dev Adds collateral to borrower's credit account
    /// @param onBehalfOf Address of the borrower whose account is funded
    /// @param token Address of a collateral token
    /// @param amount Amount to add
    function addCollateral(
        address onBehalfOf,
        address token,
        uint256 amount
    ) external payable override nonReentrant {
        // Wraps ETH and sends it back to msg.sender
        _wrapETH(); // F:[FA-3E]

        // Checks that onBehalfOf has an account
        address creditAccount = creditManager.getCreditAccountOrRevert(
            onBehalfOf
        ); // F:[FA-2]

        addCollateral(onBehalfOf, creditAccount, token, amount);

        // Since this action can enable new tokens, Credit Manager
        // needs to check that the max enabled token limit is not
        // breached
        creditManager.checkAndOptimizeEnabledTokens(creditAccount); // F: [FA-21C]
    }

    function addCollateral(
        address onBehalfOf,
        address creditAccount,
        address token,
        uint256 amount
    ) internal {
        // Checks that msg.sender can transfer funds to onBehalfOf's account
        // This is done to prevent malicious actors sending bad collateral
        // to users
        // mgs.sender can only add collateral if transfer are approved
        // from itself to onBehalfOf
        _revertIfActionOnAccountNotAllowed(onBehalfOf); // F: [FA-21A]

        // Requests Credit Manager to transfer collateral to the Credit Account
        creditManager.addCollateral(msg.sender, creditAccount, token, amount); // F:[FA-21]

        // Emits event
        emit AddCollateral(onBehalfOf, token, amount); // F:[FA-21]
    }

    /// @dev Executes a batch of transactions within a Multicall, to manage an existing account
    ///  - Wraps ETH and sends it back to msg.sender, if value > 0
    ///  - Executes the Multicall
    ///  - Performs a fullCollateralCheck to verify that hf > 1 after all actions
    /// @param calls The array of MultiCall structs encoding the operations to execute.
    function multicall(MultiCall[] calldata calls)
        external
        payable
        override
        nonReentrant
    {
        // Checks that msg.sender has an account
        address creditAccount = creditManager.getCreditAccountOrRevert(
            msg.sender
        );

        // Wraps ETH and sends it back to msg.sender
        _wrapETH(); // F:[FA-3F]

        if (calls.length != 0) {
            _multicall(calls, msg.sender, creditAccount, false, false);

            // Performs a fullCollateralCheck
            // During a multicall, all intermediary health checks are skipped,
            // as one fullCollateralCheck at the end is sufficient
            creditManager.fullCollateralCheck(creditAccount);
        }
    }

    /// @dev IMPLEMENTATION: multicall
    /// - Transfers ownership from  borrower to this contract, as most adapter and Credit Manager functions retrieve
    ///   the Credit Account by msg.sender
    /// - Executes the provided list of calls:
    ///   + if targetContract == address(this), parses call data in the struct and calls the appropriate function (see _processCreditFacadeMulticall below)
    ///   + if targetContract == adapter, calls the adapter with call data as provided.
    /// @param borrower Owner of the Credit Account
    /// @param creditAccount Credit Account address
    /// @param isClosure Whether the multicall is being invoked during a closure action. Calls to Credit Facade are forbidden inside
    ///                  multicalls on closure.
    /// @param increaseDebtWasCalled True if debt was increased before or during the multicall. Used to prevent free flashloans by
    ///                  increasing and decreasing debt within a single multicall.
    function _multicall(
        MultiCall[] calldata calls,
        address borrower,
        address creditAccount,
        bool isClosure,
        bool increaseDebtWasCalled
    ) internal {
        // Takes ownership of the Credit Account
        creditManager.transferAccountOwnership(borrower, address(this)); // F:[FA-26]

        // Emits event for multicall start - used in analytics to track actions within multicalls
        emit MultiCallStarted(borrower); // F:[FA-26]

        // Declares the expectedBalances array, which can later be used for slippage control
        Balance[] memory expectedBalances;

        uint256 len = calls.length; // F:[FA-26]
        for (uint256 i = 0; i < len; ) {
            MultiCall calldata mcall = calls[i]; // F:[FA-26]

            // Reverts of calldata has less than 4 bytes
            if (mcall.callData.length < 4) revert IncorrectCallDataException(); // F:[FA-22]

            if (mcall.target == address(this)) {
                // No internal calls on closure except slippage control, to avoid loss manipulation
                if (isClosure) {
                    bytes4 method = bytes4(mcall.callData);
                    if (
                        method !=
                        ICreditFacadeExtended.revertIfReceivedLessThan.selector
                    ) revert ForbiddenDuringClosureException(); // F:[FA-13]
                }

                //
                // CREDIT FACADE
                //

                // increaseDebtWasCalled and expectedBalances are parameters that persist throughout multicall,
                // therefore they are passed to the internal function processor, which returns updated values
                (
                    increaseDebtWasCalled,
                    expectedBalances
                ) = _processCreditFacadeMulticall(
                    borrower,
                    creditAccount,
                    mcall.callData,
                    increaseDebtWasCalled,
                    expectedBalances
                );
            } else {
                //
                // ADAPTERS
                //

                // Checks that the target is an allowed adapter and not CreditManager
                // As CreditFacade has powerful permissions in CreditManagers,
                // functionCall to it is strictly forbidden, even if
                // the Configurator adds it as an adapter
                if (
                    creditManager.adapterToContract(mcall.target) ==
                    address(0) ||
                    mcall.target == address(creditManager)
                ) revert TargetContractNotAllowedException(); // F:[FA-24]

                // Makes a call
                mcall.target.functionCall(mcall.callData); // F:[FA-29]
            }

            unchecked {
                ++i;
            }
        }

        // If expectedBalances was set by calling revertIfGetLessThan,
        // checks that actual token balances are not less than expected balances
        if (expectedBalances.length != 0)
            _compareBalances(expectedBalances, creditAccount);

        // Emits event for multicall end - used in analytics to track actions within multicalls
        emit MultiCallFinished(); // F:[FA-27,27,29]

        // Returns ownership back to the borrower
        creditManager.transferAccountOwnership(address(this), borrower); // F:[FA-27,27,29]
    }

    /// @dev Internal function for processing calls to Credit Facade within the multicall
    /// @param borrower Original owner of the Credit Account
    /// @param creditAccount Credit Account address
    /// @param callData Call data of the currently processed call
    /// @param increaseDebtWasCalledBefore Whether debt was increased before entering the function
    /// @param expectedBalances Array of expected balances before entering the function
    function _processCreditFacadeMulticall(
        address borrower,
        address creditAccount,
        bytes calldata callData,
        bool increaseDebtWasCalledBefore,
        Balance[] memory expectedBalancesBefore
    )
        internal
        returns (bool increaseDebtWasCalled, Balance[] memory expectedBalances)
    {
        increaseDebtWasCalled = increaseDebtWasCalledBefore;
        expectedBalances = expectedBalancesBefore;

        bytes4 method = bytes4(callData);

        //
        // REVERT_IF_GET_LESS_THAN
        //

        // This is an extension function that instructs CreditFacade to check token balances at the end
        // Used to control slippage after the entire sequence of operations, since tracking slippage
        // On each operation is not ideal
        if (method == ICreditFacadeExtended.revertIfReceivedLessThan.selector) {
            // Method can only be called once since the provided Balance array
            // contains deltas that are added to the current balances
            // Calling this function again could potentially override old values
            // and cause confusion, especially if called later in the MultiCall
            if (expectedBalances.length != 0)
                revert ExpectedBalancesAlreadySetException(); // F:[FA-45A]

            // Retrieves the balance list from calldata
            expectedBalances = abi.decode(callData[4:], (Balance[])); // F:[FA-45]

            // Sets expected balances to currentBalance + delta
            expectedBalances = _storeBalances(expectedBalances, creditAccount); // F:[FA-45]
        }
        //
        // ADD COLLATERAL
        //
        else if (method == ICreditFacade.addCollateral.selector) {
            // Parses parameters from calldata
            (address onBehalfOf, address token, uint256 amount) = abi.decode(
                callData[4:],
                (address, address, uint256)
            ); // F:[FA-26, 27]

            // In case onBehalfOf isn't the owner of the currently processed account,
            // retrieves onBehalfOf's account
            addCollateral(
                onBehalfOf,
                onBehalfOf == borrower
                    ? creditAccount
                    : creditManager.getCreditAccountOrRevert(onBehalfOf),
                token,
                amount
            ); // F:[FA-26, 27]
        }
        //
        // INCREASE DEBT
        //
        else if (method == ICreditFacadeExtended.increaseDebt.selector) {
            // Sets increaseDebtWasCalled to prevent debt reductions afterwards,
            // as that could be used to get free flash loans
            increaseDebtWasCalled = true; // F:[FA-28]

            // Parses parameters from calldata
            uint256 amount = abi.decode(callData[4:], (uint256)); // F:[FA-26]
            _increaseDebt(borrower, creditAccount, amount); // F:[FA-26]
        }
        //
        // DECREASE DEBT
        //
        else if (method == ICreditFacadeExtended.decreaseDebt.selector) {
            // it's forbidden to call decreaseDebt after increaseDebt, in the same multicall
            if (increaseDebtWasCalled)
                revert IncreaseAndDecreaseForbiddenInOneCallException(); // F:[FA-28]

            // Parses parameters from calldata
            uint256 amount = abi.decode(callData[4:], (uint256)); // F:[FA-27]

            _decreaseDebt(borrower, creditAccount, amount); // F:[FA-27]
        }
        //
        // ENABLE TOKEN
        //
        else if (method == ICreditFacadeExtended.enableToken.selector) {
            // Parses token
            address token = abi.decode(callData[4:], (address)); // F: [FA-53]

            // Executes enableToken for creditAccount
            _enableToken(borrower, creditAccount, token); // F: [FA-53]
        }
        //
        // DISABLE TOKEN
        //
        // This is an extenstion method used to disable tokens on a Credit Account
        // Can be used to remove troublesome tokens (e.g., forbidden tokens) from an account
        else if (method == ICreditFacadeExtended.disableToken.selector) {
            // Parses token
            address token = abi.decode(callData[4:], (address)); // F: [FA-54]

            // Executes disableToken for creditAccount
            _disableToken(borrower, creditAccount, token); // F: [FA-54]
        } else {
            // Reverts if the passed selector is unrecognized
            revert UnknownMethodException(); // F:[FA-23]
        }
    }

    /// @dev Adds expected deltas to current balances on a Credit account and returns the result
    /// @param expected Expected changes to existing balances
    /// @param creditAccount Credit Account to compute balances for
    function _storeBalances(Balance[] memory expected, address creditAccount)
        internal
        view
        returns (Balance[] memory)
    {
        uint256 len = expected.length; // F:[FA-45]
        for (uint256 i = 0; i < len; ) {
            expected[i].balance += IERC20(expected[i].token).balanceOf(
                creditAccount
            ); // F:[FA-45]
            unchecked {
                ++i;
            }
        }

        return expected; // F:[FA-45]
    }

    /// @dev Compares current balances to previously saved expected balances.
    /// Reverts if at least one balance is lower than expected
    /// @param expected Expected balances after all operations
    /// @param creditAccount Credit Account to check
    function _compareBalances(Balance[] memory expected, address creditAccount)
        internal
        view
    {
        uint256 len = expected.length; // F:[FA-45]
        for (uint256 i = 0; i < len; ) {
            if (
                IERC20(expected[i].token).balanceOf(creditAccount) <
                expected[i].balance
            ) revert BalanceLessThanMinimumDesiredException(expected[i].token); // F:[FA-45]
            unchecked {
                ++i;
            }
        }
    }

    /// @dev Transfers credit account to another user
    /// By default, this action is forbidden, and the user has to approve transfers from sender to itself
    /// by calling approveAccountTransfer.
    /// This is done to prevent malicious actors from transferring compromised accounts to other users.
    /// @param to Address to transfer the account to
    function transferAccountOwnership(address to)
        external
        override
        nonReentrant
    {
        // In whitelisted mode only select addresses can have Credit Accounts
        // So this action is prohibited
        if (whitelisted) revert NotAllowedInWhitelistedMode(); // F:[FA-32]

        address creditAccount = creditManager.getCreditAccountOrRevert(
            msg.sender
        ); // F:[FA-2]

        // Checks that transfer is allowed
        if (!transfersAllowed[msg.sender][to])
            revert AccountTransferNotAllowedException(); // F:[FA-33]

        /// Checks that the account hf > 1, as it is forbidden to transfer
        /// accounts that are liquidatable
        (bool isLiquidatable, ) = _isAccountLiquidatable(creditAccount); // F:[FA-34]

        if (isLiquidatable) revert CantTransferLiquidatableAccountException(); // F:[FA-34]

        // Requests the Credit Manager to transfer the account
        creditManager.transferAccountOwnership(msg.sender, to); // F:[FA-35]

        // Emits event
        emit TransferAccount(msg.sender, to); // F:[FA-35]
    }

    /// @dev Verifies that the msg.sender can open an account for onBehalfOf
    /// -  For expirable Credit Facade, expiration date must not be reached
    /// -  For whitelisted mode, msg.sender must open the account for themselves
    ///    and have at least one DegenNFT to burn
    /// -  Otherwise, checks that account transfers from msg.sender to onBehalfOf
    ///    are approved
    /// @param onBehalfOf Account which would own credit account
    function _revertIfOpenCreditAccountNotAllowed(address onBehalfOf) internal {
        // Opening new Credit Accounts is prohibited in increaseDebtForbidden mode
        if (params.isIncreaseDebtForbidden)
            revert IncreaseDebtForbiddenException(); // F:[FA-7]

        // Checks that this CreditFacade is not expired
        if (_isExpired()) {
            revert OpenAccountNotAllowedAfterExpirationException(); // F: [FA-46]
        }

        // Checks that the borrower is not blacklisted, if the underlying is blacklistable
        if (_isBlacklisted(onBehalfOf) != 0) {
            revert NotAllowedForBlacklistedAddressException(); // F:[FA-57]
        }

        // F:[FA-5] covers case when degenNFT == address(0)
        if (degenNFT != address(0)) {
            // F:[FA-4B]

            // In whitelisted mode, users can only open an account by burning a DegenNFT
            // And opening an account for another address is forbidden
            if (whitelisted && msg.sender != onBehalfOf)
                revert NotAllowedInWhitelistedMode(); // F:[FA-4B]

            IDegenNFT(degenNFT).burn(onBehalfOf, 1); // F:[FA-4B]
        }

        _revertIfActionOnAccountNotAllowed(onBehalfOf);
    }

    /// @dev Checks if the message sender is allowed to do an action on a CA
    /// @param onBehalfOf The account which owns the target CA
    function _revertIfActionOnAccountNotAllowed(address onBehalfOf)
        internal
        view
    {
        // msg.sender must either be the account owner themselves,
        // or be approved for transfers
        if (
            msg.sender != onBehalfOf &&
            !transfersAllowed[msg.sender][onBehalfOf]
        ) revert AccountTransferNotAllowedException(); // F:[FA-04C]
    }

    /// @dev Checks that the per-block borrow limit was not violated and updates the
    /// amount borrowed in current block
    function _checkAndUpdateBorrowedBlockLimit(uint256 amount) internal {
        // Skipped in whitelisted mode, since there is a strict limit on the number
        // of credit accounts that can be opened, which implies a limit on borrowing
        if (!whitelisted) {
            uint256 _limitPerBlock = params.maxBorrowedAmountPerBlock; // F:[FA-18]

            // If the limit is unit128.max, the check is disabled
            // F:[FA-36] test case when _limitPerBlock == type(uint128).max
            if (_limitPerBlock != type(uint128).max) {
                (
                    uint64 lastBlock,
                    uint128 lastLimit
                ) = getTotalBorrowedInBlock(); // F:[FA-18, 37]

                uint256 newLimit = (lastBlock == block.number)
                    ? amount + lastLimit // F:[FA-37]
                    : amount; // F:[FA-18, 37]

                if (newLimit > _limitPerBlock)
                    revert BorrowedBlockLimitException(); // F:[FA-18]

                _updateTotalBorrowedInBlock(newLimit.toUint128()); // F:[FA-37]
            }
        }
    }

    /// @dev Checks that the borrowed principal is within borrowing limits
    /// @param borrowedAmount The current principal of a Credit Account
    function _revertIfOutOfBorrowedLimits(uint256 borrowedAmount)
        internal
        view
    {
        // Checks that amount is in limits
        if (
            borrowedAmount < uint256(limits.minBorrowedAmount) ||
            borrowedAmount > uint256(limits.maxBorrowedAmount)
        ) revert BorrowAmountOutOfLimitsException(); // F:
    }

    function _checkIfEmergencyLiquidator(bool state) internal returns (bool) {
        return creditManager.checkEmergencyPausable(msg.sender, state);
    }

    /// @dev Updates total debt and checks that it does not exceed the limit
    function _checkAndUpdateTotalDebt(uint256 delta, bool isIncrease) internal {
        if (delta > 0) {
            TotalDebt memory td = totalDebt;

            if (isIncrease) {
                td.currentTotalDebt += delta.toUint128();
                if (td.currentTotalDebt > td.totalDebtLimit) {
                    revert BorrowAmountOutOfLimitsException();
                }
            } else {
                td.currentTotalDebt -= delta.toUint128();
            }

            totalDebt = td;
        }
    }

    /// @dev Returns the last block where debt was taken,
    ///      and the total amount borrowed in that block
    function getTotalBorrowedInBlock()
        public
        view
        returns (uint64 blockLastUpdate, uint128 borrowedInBlock)
    {
        blockLastUpdate = uint64(totalBorrowedInBlock >> 128); // F:[FA-37]
        borrowedInBlock = uint128(totalBorrowedInBlock & type(uint128).max); // F:[FA-37]
    }

    /// @dev Saves the total amount borrowed in the current block for future checks
    /// @param borrowedInBlock Updated total borrowed amount
    function _updateTotalBorrowedInBlock(uint128 borrowedInBlock) internal {
        totalBorrowedInBlock = uint256(block.number << 128) | borrowedInBlock; // F:[FA-37]
    }

    /// @dev Approves account transfer from another user to msg.sender
    /// @param from Address for which account transfers are allowed/forbidden
    /// @param state True is transfer is allowed, false if forbidden
    function approveAccountTransfer(address from, bool state)
        external
        override
        nonReentrant
    {
        transfersAllowed[from][msg.sender] = state; // F:[FA-38]

        // Emits event
        emit TransferAccountAllowed(from, msg.sender, state); // F:[FA-38]
    }

    /// @dev Enables token in enabledTokenMask for a Credit Account
    /// @param creditAccount Account for which the token is enabled
    /// @param token Collateral token to enabled
    function _enableToken(
        address borrower,
        address creditAccount,
        address token
    ) internal {
        // Will revert if the token is not known or forbidden,
        // If the token is disabled, adds the respective bit to the mask, otherwise does nothing
        creditManager.checkAndEnableToken(creditAccount, token); // F:[FA-39]

        // Emits event
        emit TokenEnabled(borrower, token);
    }

    /// @dev Disable a token for a Credit Account
    /// @param borrower Owner of the account
    /// @param token Token to disable
    function _disableToken(
        address borrower,
        address creditAccount,
        address token
    ) internal {
        // If the token is enabled, removes a respective bit from the mask,
        // otherwise does nothing
        if (creditManager.disableToken(creditAccount, token)) {
            // Emits event
            emit TokenDisabled(borrower, token);
        } // F: [FA-54]
    }

    /// @dev Pauses the Credit Manager
    function _pauseCreditManager() internal {
        IPausable(address(creditManager)).pause();
    }

    //
    // GETTERS
    //

    /// @dev Returns true if token is a collateral token and is not forbidden,
    /// otherwise returns false
    /// @param token Token to check
    function isTokenAllowed(address token)
        public
        view
        override
        returns (bool allowed)
    {
        uint256 tokenMask = creditManager.tokenMasksMap(token); // F:[FA-40]
        allowed =
            (tokenMask != 0) &&
            (creditManager.forbiddenTokenMask() & tokenMask == 0); // F:[FA-40]
    }

    /// @dev Calculates total value for provided Credit Account in underlying
    /// More: https://dev.gearbox.fi/developers/credit/economy#totalUSD-value
    ///
    /// @param creditAccount Credit Account address
    /// @return total Total value in underlying
    /// @return twv Total weighted (discounted by liquidation thresholds) value in underlying
    function calcTotalValue(address creditAccount)
        public
        view
        override
        returns (uint256 total, uint256 twv)
    {
        IPriceOracleV2 priceOracle = IPriceOracleV2(
            creditManager.priceOracle()
        ); // F:[FA-41]

        (uint256 totalUSD, uint256 twvUSD) = _calcTotalValueUSD(
            priceOracle,
            creditAccount
        );
        total = priceOracle.convertFromUSD(totalUSD, underlying); // F:[FA-41]
        twv =
            priceOracle.convertFromUSD(twvUSD, underlying) /
            PERCENTAGE_FACTOR; // F:[FA-41]
    }

    /// @dev Calculates total value for provided Credit Account in USD
    /// @param priceOracle Oracle used to convert assets to USD
    /// @param creditAccount Address of the Credit Account
    /// @return totalUSD Total value of the account in USD
    /// @return twvUSD Total weighted (discounted by liquidation thresholds) value in USD
    function _calcTotalValueUSD(
        IPriceOracleV2 priceOracle,
        address creditAccount
    ) internal view returns (uint256 totalUSD, uint256 twvUSD) {
        uint256 tokenMask = 1;
        uint256 enabledTokensMask = creditManager.enabledTokensMap(
            creditAccount
        ); // F:[FA-41]

        while (tokenMask <= enabledTokensMask) {
            if (enabledTokensMask & tokenMask != 0) {
                (address token, uint16 liquidationThreshold) = creditManager
                    .collateralTokensByMask(tokenMask);
                uint256 balance = IERC20(token).balanceOf(creditAccount); // F:[FA-41]

                if (balance > 1) {
                    uint256 value = priceOracle.convertToUSD(balance, token); // F:[FA-41]

                    unchecked {
                        totalUSD += value; // F:[FA-41]
                    }
                    twvUSD += value * liquidationThreshold; // F:[FA-41]
                }
            } // T:[FA-41]

            tokenMask = tokenMask << 1; // F:[FA-41]
        }
    }

    /**
     * @dev Calculates health factor for the credit account
     *
     *          sum(asset[i] * liquidation threshold[i])
     *   Hf = --------------------------------------------
     *         borrowed amount + interest accrued + fees
     *
     *
     * More info: https://dev.gearbox.fi/developers/credit/economy#health-factor
     *
     * @param creditAccount Credit account address
     * @return hf = Health factor in bp (see PERCENTAGE FACTOR in PercentageMath.sol)
     */
    function calcCreditAccountHealthFactor(address creditAccount)
        public
        view
        override
        returns (uint256 hf)
    {
        (, uint256 twv) = calcTotalValue(creditAccount); // F:[FA-42]
        (, , uint256 borrowAmountWithInterestAndFees) = creditManager
            .calcCreditAccountAccruedInterest(creditAccount); // F:[FA-42]
        hf = (twv * PERCENTAGE_FACTOR) / borrowAmountWithInterestAndFees; // F:[FA-42]
    }

    /// @dev Returns true if the borrower has an open Credit Account
    /// @param borrower Borrower address
    function hasOpenedCreditAccount(address borrower)
        public
        view
        override
        returns (bool)
    {
        return creditManager.creditAccounts(borrower) != address(0); // F:[FA-43]
    }

    /// @dev Wraps ETH into WETH and sends it back to msg.sender
    function _wrapETH() internal {
        if (msg.value > 0) {
            IWETH(wethAddress).deposit{ value: msg.value }(); // F:[FA-3]
            IWETH(wethAddress).transfer(msg.sender, msg.value); // F:[FA-3]
        }
    }

    /// @dev Checks if account is liquidatable (i.e., hf < 1)
    /// @param creditAccount Address of credit account to check
    /// @return isLiquidatable True if account can be liquidated
    /// @return totalValue Total value of the Credit Account in underlying
    function _isAccountLiquidatable(address creditAccount)
        internal
        view
        returns (bool isLiquidatable, uint256 totalValue)
    {
        IPriceOracleV2 priceOracle = IPriceOracleV2(
            creditManager.priceOracle()
        ); // F:[FA-14]

        (uint256 totalUSD, uint256 twvUSD) = _calcTotalValueUSD(
            priceOracle,
            creditAccount
        );

        // Computes total value in underlying
        totalValue = priceOracle.convertFromUSD(totalUSD, underlying); // F:[FA-14]

        (, , uint256 borrowAmountWithInterestAndFees) = creditManager
            .calcCreditAccountAccruedInterest(creditAccount); // F:[FA-14]

        // borrowAmountPlusInterestRateUSD x 10000 to be compared with USD values multiplied by LTs
        uint256 borrowAmountPlusInterestRateUSD = priceOracle.convertToUSD(
            borrowAmountWithInterestAndFees,
            underlying
        ) * PERCENTAGE_FACTOR;

        // Checks that current Hf < 1
        isLiquidatable = twvUSD < borrowAmountPlusInterestRateUSD;
    }

    /// @dev Returns whether the Credit Facade is expired
    function _isExpired() internal view returns (bool isExpired) {
        isExpired = (expirable) && (block.timestamp >= params.expirationDate); // F: [FA-46,47,48]
    }

    /// @dev Returns the current available liquidity of the pool
    function _getAvailableLiquidity() internal view returns (uint256) {
        return IERC20(underlying).balanceOf(pool);
    }

    //
    // CONFIGURATION
    //

    /// @dev Sets the increaseDebtForbidden mode
    /// @notice increaseDebtForbidden can be used to secure pool funds
    /// without pausing the entire system. E.g., if a bug is reported
    /// that can potentially lead to loss of funds, but there is no
    /// immediate threat, new borrowing can be stopped, while other
    /// functionality (trading, closing/liquidating accounts) is retained
    function setIncreaseDebtForbidden(bool _mode)
        external
        creditConfiguratorOnly // F:[FA-44]
    {
        params.isIncreaseDebtForbidden = _mode;
    }

    /// @dev Sets borrowing limit per single block
    /// @notice Borrowing limit per block in conjunction with
    /// the monitoring system serves to minimize loss from hacks
    /// While an attacker would be able to steal, in worst case,
    /// up to (limitPerBlock * n blocks) of funds, the monitoring
    /// system would pause the contracts after detecting suspicious
    /// activity
    function setLimitPerBlock(uint128 newLimit)
        external
        creditConfiguratorOnly // F:[FA-44]
    {
        params.maxBorrowedAmountPerBlock = newLimit;
    }

    /// @dev Sets the total debt limit and the current total debt value (used for Credit Facade migration)
    function setTotalDebtParams(uint128 newCurrentTotalDebt, uint128 newLimit)
        external
        creditConfiguratorOnly
    {
        totalDebt.currentTotalDebt = newCurrentTotalDebt;
        totalDebt.totalDebtLimit = newLimit;
    }

    /// @dev Sets Credit Facade expiration date
    /// @notice See more at https://dev.gearbox.fi/docs/documentation/credit/liquidation#liquidating-accounts-by-expiration
    function setExpirationDate(uint40 newExpirationDate)
        external
        creditConfiguratorOnly
    {
        if (!expirable) {
            revert NotAllowedWhenNotExpirableException();
        }
        params.expirationDate = newExpirationDate;
    }

    /// @dev Sets borrowing limits per single Credit Account
    /// @param _minBorrowedAmount The minimal borrowed amount per Credit Account. Minimal amount can be relevant
    /// for liquidations, since very small amounts will make liquidations unprofitable for liquidators
    /// @param _maxBorrowedAmount The maximal borrowed amount per Credit Account. Used to limit exposure per a single
    /// credit account - especially relevant in whitelisted mode.
    function setCreditAccountLimits(
        uint128 _minBorrowedAmount,
        uint128 _maxBorrowedAmount
    ) external creditConfiguratorOnly {
        limits.minBorrowedAmount = _minBorrowedAmount; // F:
        limits.maxBorrowedAmount = _maxBorrowedAmount; // F:
    }

    /// @dev Sets the max cumulative loss that can be accrued before pausing the Credit Manager
    function setMaxCumulativeLoss(uint128 _maxCumulativeLoss)
        external
        creditConfiguratorOnly
    {
        lossParams.maxCumulativeLoss = _maxCumulativeLoss;
    }

    /// @dev Resets the current cumulative loss value
    function resetCumulativeLoss() external creditConfiguratorOnly {
        lossParams.currentCumulativeLoss = 0;
    }

    /// @dev Sets the new emergency liquidation discount value
    function setEmergencyLiquidationDiscount(uint16 newDiscount)
        external
        creditConfiguratorOnly
    {
        params.emergencyLiquidationDiscount = newDiscount;
    }
}
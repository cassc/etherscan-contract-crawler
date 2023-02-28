// SPDX-License-Identifier: MIT

pragma solidity ^0.8.11;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/AccessControlEnumerableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/IERC721Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/CountersUpgradeable.sol";

import "./interfaces/ICallDelegator.sol";
import "./interfaces/IPromissoryNote.sol";
import "./interfaces/IAssetVault.sol";
import "./interfaces/IFeeController.sol";
import "./interfaces/ILoanCore.sol";

import "./InstallmentsCalc.sol";
import "./PromissoryNote.sol";
import "./vault/OwnableERC721.sol";
import {
    LC_ZeroAddress,
    LC_ReusedNote,
    LC_CollateralInUse,
    LC_InvalidState,
    LC_NotExpired,
    LC_NonceUsed,
    LC_LoanNotDefaulted
} from "./errors/Lending.sol";

/**
 * @title LoanCore
 * @author Non-Fungible Technologies, Inc.
 *
 * The LoanCore lending contract is the heart of the Arcade.xyz lending protocol.
 * It stores and maintains loan state, enforces loan lifecycle invariants, takes
 * escrow of assets during an active loans, governs the release of collateral on
 * repayment or default, and tracks signature nonces for loan consent.
 *
 * Also contains logic for approving Asset Vault calls using the
 * ICallDelegator interface.
 */
contract LoanCore is
    ILoanCore,
    Initializable,
    InstallmentsCalc,
    AccessControlEnumerableUpgradeable,
    PausableUpgradeable,
    ICallDelegator,
    UUPSUpgradeable
{
    using CountersUpgradeable for CountersUpgradeable.Counter;
    using SafeERC20Upgradeable for IERC20Upgradeable;

    // ============================================ STATE ==============================================

    // =================== Constants =====================

    bytes32 public constant ADMIN_ROLE = keccak256("ADMIN_ROLE");
    bytes32 public constant ORIGINATOR_ROLE = keccak256("ORIGINATOR_ROLE");
    bytes32 public constant REPAYER_ROLE = keccak256("REPAYER_ROLE");
    bytes32 public constant FEE_CLAIMER_ROLE = keccak256("FEE_CLAIMER_ROLE");

    uint256 private constant PERCENT_MISSED_FOR_LENDER_CLAIM = 4000;
    // =============== Contract References ================

    IPromissoryNote public override borrowerNote;
    IPromissoryNote public override lenderNote;
    IFeeController public override feeController;

    // =================== Loan State =====================

    CountersUpgradeable.Counter private loanIdTracker;
    mapping(uint256 => LoanLibrary.LoanData) private loans;
    // key is hash of (collateralAddress, collateralId)
    mapping(bytes32 => bool) private collateralInUse;
    mapping(address => mapping(uint160 => bool)) public usedNonces;

    /// @dev Reentrancy guards
    uint256 private _locked;
    bool private _lockSet;

    // ========================================== CONSTRUCTOR ===========================================

    /**
     * @notice Runs the initializer function in an upgradeable contract.
     *
     * @dev Add Unsafe-allow comment to notify upgrades plugin to accept the constructor.
     */
    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() initializer {}

    // ========================================== INITIALIZER ===========================================

    /**
     * @notice Initializes the loan core contract, by initializing parent
     *         contracts, setting up roles, and setting up contract references.
     *
     * @param _feeController      The address of the contract governing protocol fees.
     */
    function initialize(
        IFeeController _feeController,
        IPromissoryNote _borrowerNote,
        IPromissoryNote _lenderNote
    ) public initializer {
        if (address(_feeController) == address(0)) revert LC_ZeroAddress();
        if (address(_borrowerNote) == address(0)) revert LC_ZeroAddress();
        if (address(_lenderNote) == address(0)) revert LC_ZeroAddress();
        if (address(_borrowerNote) == address(_lenderNote)) revert LC_ReusedNote();

        // only those with FEE_CLAIMER_ROLE can update or grant FEE_CLAIMER_ROLE
        __AccessControlEnumerable_init_unchained();
        __UUPSUpgradeable_init_unchained();
        __Pausable_init_unchained();

        _setupRole(ADMIN_ROLE, _msgSender());
        _setRoleAdmin(ADMIN_ROLE, ADMIN_ROLE);
        _setRoleAdmin(ORIGINATOR_ROLE, ADMIN_ROLE);
        _setRoleAdmin(REPAYER_ROLE, ADMIN_ROLE);

        _setupRole(FEE_CLAIMER_ROLE, _msgSender());
        _setRoleAdmin(FEE_CLAIMER_ROLE, FEE_CLAIMER_ROLE);

        feeController = _feeController;

        /// @dev Although using references for both promissory notes, these
        ///      must be fresh versions and cannot be re-used across multiple
        ///      loanCore instances, to ensure loanId <> tokenID parity
        borrowerNote = _borrowerNote;
        lenderNote = _lenderNote;

        // Avoid having loanId = 0
        loanIdTracker.increment();

        // Set the reentrancy lock
        _locked = 1;
    }

    // ===================================== UPGRADE AUTHORIZATION ======================================

    /**
     * @notice Authorization function to define whether a contract upgrade should be allowed.
     *
     * @param newImplementation     The address of the upgraded verion of this contract.
     */
    function _authorizeUpgrade(address newImplementation) internal override onlyRole(ADMIN_ROLE) {}

    // ====================================== LIFECYCLE OPERATIONS ======================================

    /**
     * @notice Start a loan, matching a set of terms, with a given
     *         lender and borrower. Collects collateral and distributes
     *         principal, along with collecting an origination fee for the
     *         protocol. Can only be called by OriginationController.
     *
     * @param lender                The lender for the loan.
     * @param borrower              The borrower for the loan.
     * @param terms                 The terms of the loan.
     *
     * @return loanId               The ID of the newly created loan.
     */
    function startLoan(
        address lender,
        address borrower,
        LoanLibrary.LoanTerms calldata terms
    ) external override whenNotPaused onlyRole(ORIGINATOR_ROLE) nonReentrant returns (uint256 loanId) {
        // check collateral is not already used in a loan.
        bytes32 collateralKey = keccak256(abi.encode(terms.collateralAddress, terms.collateralId));
        if (collateralInUse[collateralKey]) revert LC_CollateralInUse(terms.collateralAddress, terms.collateralId);

        // get current loanId and increment for next function call
        loanId = loanIdTracker.current();
        loanIdTracker.increment();

        // Initiate loan state
        loans[loanId] = LoanLibrary.LoanData({
            terms: terms,
            state: LoanLibrary.LoanState.Active,
            startDate: uint160(block.timestamp),
            balance: terms.principal,
            balancePaid: 0,
            lateFeesAccrued: 0,
            numInstallmentsPaid: 0
        });

        collateralInUse[collateralKey] = true;

        // Distribute notes and principal
        _mintLoanNotes(loanId, borrower, lender);

        IERC721Upgradeable(terms.collateralAddress).transferFrom(_msgSender(), address(this), terms.collateralId);

        IERC20Upgradeable(terms.payableCurrency).safeTransferFrom(_msgSender(), address(this), terms.principal);

        IERC20Upgradeable(terms.payableCurrency).safeTransfer(borrower, _getPrincipalLessFees(terms.principal));

        emit LoanStarted(loanId, lender, borrower);
    }

    /**
     * @notice Repay the given loan. Can only be called by RepaymentController,
     *         which verifies repayment conditions. This method will calculate
     *         the total interest due, collect it from the borrower, and redistribute
     *         principal + interest to the lender, and collateral to the borrower.
     *         All promissory notes will be burned and the loan will be marked as complete.
     *
     * @param loanId                The ID of the loan to repay.
     */
    function repay(uint256 loanId) external override onlyRole(REPAYER_ROLE) nonReentrant {
        LoanLibrary.LoanData memory data = loans[loanId];
        // ensure valid initial loan state when starting loan
        if (data.state != LoanLibrary.LoanState.Active) revert LC_InvalidState(data.state);

        uint256 returnAmount = getFullInterestAmount(data.terms.principal, data.terms.interestRate);

        // get promissory notes from two parties involved
        address lender = lenderNote.ownerOf(loanId);
        address borrower = borrowerNote.ownerOf(loanId);

        // state changes and cleanup
        // NOTE: these must be performed before assets are released to prevent reentrance
        loans[loanId].state = LoanLibrary.LoanState.Repaid;
        collateralInUse[keccak256(abi.encode(data.terms.collateralAddress, data.terms.collateralId))] = false;

        _burnLoanNotes(loanId);

        // transfer from msg.sender to this contract
        IERC20Upgradeable(data.terms.payableCurrency).safeTransferFrom(_msgSender(), address(this), returnAmount);
        // asset and collateral redistribution
        // Not using safeTransfer to prevent lenders from blocking
        // loan receipt and forcing a default
        IERC20Upgradeable(data.terms.payableCurrency).transfer(lender, returnAmount);
        IERC721Upgradeable(data.terms.collateralAddress).transferFrom(address(this), borrower, data.terms.collateralId);

        emit LoanRepaid(loanId);
    }

    /**
     * @notice Claim collateral on a given loan. Can only be called by RepaymentController,
     *         which verifies claim conditions. This method validates that the loan's due
     *         date has passed, and then distributes collateral to the lender. All promissory
     *         notes will be burned and the loan will be marked as complete.
     *
     * @param loanId                              The ID of the loan to claim.
     * @param currentInstallmentPeriod            The current installment period if
     *                                            installment loan type, else 0.
     */
    function claim(uint256 loanId, uint256 currentInstallmentPeriod)
        external
        override
        whenNotPaused
        onlyRole(REPAYER_ROLE)
        nonReentrant
    {
        LoanLibrary.LoanData memory data = loans[loanId];
        // ensure valid initial loan state when starting loan
        if (data.state != LoanLibrary.LoanState.Active) revert LC_InvalidState(data.state);

        // First check if the call is being made after the due date.
        // Additionally, if an unexpired installment loan, verify over 40% of the total
        // number of installments have been missed before the lender can claim.
        uint256 dueDate = data.startDate + data.terms.durationSecs;
        if (data.terms.numInstallments == 0 || block.timestamp > dueDate) {
            // for non installment loan types call must be after due date
            if (dueDate > block.timestamp) revert LC_NotExpired(dueDate);

            // perform claim...
        }
        else {
            // verify installment loan type, not legacy loan (safety check)
            if (data.terms.numInstallments == 0) revert LC_NotExpired(dueDate);
            // verify greater than 40% total installments have been missed
            _verifyDefaultedLoan(data.terms.numInstallments, data.numInstallmentsPaid, currentInstallmentPeriod);
        }

        address lender = lenderNote.ownerOf(loanId);

        // NOTE: these must be performed before assets are released to prevent reentrance
        loans[loanId].state = LoanLibrary.LoanState.Defaulted;
        collateralInUse[keccak256(abi.encode(data.terms.collateralAddress, data.terms.collateralId))] = false;

        _burnLoanNotes(loanId);

        // collateral redistribution
        IERC721Upgradeable(data.terms.collateralAddress).transferFrom(address(this), lender, data.terms.collateralId);

        emit LoanClaimed(loanId);
    }

    /**
     * @notice Roll over a loan, atomically closing one and re-opening a new one with the
     *         same collateral. Instead of full repayment, only net payments from each
     *         party are required. Each rolled-over loan is marked as complete, and the new
     *         loan is given a new unique ID and notes. At the time of calling, any needed
     *         net payments have been collected by the RepaymentController for withdrawal.
     *
     * @param oldLoanId             The ID of the old loan.
     * @param borrower              The borrower for the loan.
     * @param lender                The lender for the old loan.
     * @param terms                 The terms of the new loan.
     * @param _settledAmount        The amount LoanCore needs to withdraw to settle.
     * @param _amountToOldLender    The payment to the old lender (if lenders are changing).
     * @param _amountToLender       The payment to the lender (if same as old lender).
     * @param _amountToBorrower     The payemnt to the borrower (in the case of leftover principal).
     *
     * @return newLoanId            The ID of the new loan.
     */
    function rollover(
        uint256 oldLoanId,
        address borrower,
        address lender,
        LoanLibrary.LoanTerms calldata terms,
        uint256 _settledAmount,
        uint256 _amountToOldLender,
        uint256 _amountToLender,
        uint256 _amountToBorrower
    ) external override whenNotPaused onlyRole(ORIGINATOR_ROLE) nonReentrant returns (uint256 newLoanId) {
        // Repay loan
        LoanLibrary.LoanData storage data = loans[oldLoanId];
        data.state = LoanLibrary.LoanState.Repaid;

        address oldLender = lenderNote.ownerOf(oldLoanId);
        IERC20Upgradeable payableCurrency = IERC20Upgradeable(data.terms.payableCurrency);

        if (data.terms.numInstallments > 0) {
            (uint256 interestDue, uint256 lateFees, uint256 numMissedPayments) = _calcAmountsDue(
                data.balance,
                data.startDate,
                data.terms.durationSecs,
                data.terms.numInstallments,
                data.numInstallmentsPaid,
                data.terms.interestRate
            );

            data.lateFeesAccrued += lateFees;
            data.numInstallmentsPaid += uint24(numMissedPayments) + 1;
            data.balancePaid += data.balance + interestDue + lateFees;
            data.balance = 0;
        }

        _burnLoanNotes(oldLoanId);

        // Set up new loan
        newLoanId = loanIdTracker.current();
        loanIdTracker.increment();

        loans[newLoanId] = LoanLibrary.LoanData({
            terms: terms,
            state: LoanLibrary.LoanState.Active,
            startDate: uint160(block.timestamp),
            balance: terms.principal,
            balancePaid: 0,
            lateFeesAccrued: 0,
            numInstallmentsPaid: 0
        });

        // Distribute notes and principal
        _mintLoanNotes(newLoanId, borrower, lender);

        IERC20Upgradeable(payableCurrency).safeTransferFrom(_msgSender(), address(this), _settledAmount);
        _transferIfNonzero(payableCurrency, oldLender, _amountToOldLender);
        _transferIfNonzero(payableCurrency, lender, _amountToLender);
        _transferIfNonzero(payableCurrency, borrower, _amountToBorrower);

        emit LoanRepaid(oldLoanId);
        emit LoanStarted(newLoanId, lender, borrower);
        emit LoanRolledOver(oldLoanId, newLoanId);
    }

    // ===================================== INSTALLMENT OPERATI\ONS =====================================

    /**
     * @notice Called from RepaymentController when paying back an installment loan.
     *         New loan state parameters are calculated in the Repayment Controller.
     *         Based on if the _paymentToPrincipal is greater than the current balance,
     *         the loan state is updated. (0 = minimum payment sent, > 0 pay down principal).
     *         The paymentTotal (_paymentToPrincipal + _paymentToLateFees) is always transferred to the lender.
     *
     * @param _loanId                       The ID of the loan..
     * @param _currentMissedPayments        Number of payments missed since the last installment payment.
     * @param _paymentToPrincipal           Amount sent in addition to minimum amount due, used to pay down principal.
     * @param _paymentToInterest            Amount due in interest.
     * @param _paymentToLateFees            Amount due in only late fees.
     */
    function repayPart(
        uint256 _loanId,
        uint256 _currentMissedPayments,
        uint256 _paymentToPrincipal,
        uint256 _paymentToInterest,
        uint256 _paymentToLateFees
    ) external override onlyRole(REPAYER_ROLE) nonReentrant {
        LoanLibrary.LoanData storage data = loans[_loanId];
        // ensure valid initial loan state when repaying loan
        if (data.state != LoanLibrary.LoanState.Active) revert LC_InvalidState(data.state);

        // get the lender and borrower
        address lender = lenderNote.ownerOf(_loanId);
        address borrower = borrowerNote.ownerOf(_loanId);

        uint256 _balanceToPay = _paymentToPrincipal;
        if (_balanceToPay >= data.balance) {
            _balanceToPay = data.balance;

            // mark loan as closed
            data.state = LoanLibrary.LoanState.Repaid;
            collateralInUse[keccak256(abi.encode(data.terms.collateralAddress, data.terms.collateralId))] = false;

            _burnLoanNotes(_loanId);
        }

        // Unlike paymentTotal, cannot go over maximum amount owed
        uint256 boundedPaymentTotal = _balanceToPay + _paymentToLateFees + _paymentToInterest;

        // update loan state
        data.lateFeesAccrued += _paymentToLateFees;
        data.numInstallmentsPaid += uint24(_currentMissedPayments) + 1;
        data.balance -= _balanceToPay;
        data.balancePaid += boundedPaymentTotal;

        LoanLibrary.LoanState currentState = data.state;

        // calculate total sent by borrower and transferFrom repayment controller to this address
        uint256 paymentTotal = _paymentToPrincipal + _paymentToLateFees + _paymentToInterest;
        IERC20Upgradeable(data.terms.payableCurrency).safeTransferFrom(_msgSender(), address(this), paymentTotal);
        // Send payment to lender.
        // Not using safeTransfer to prevent lenders from blocking
        // loan receipt and forcing a default
        IERC20Upgradeable(data.terms.payableCurrency).transfer(lender, boundedPaymentTotal);

        // If repaid, send collateral to borrower
        if (currentState == LoanLibrary.LoanState.Repaid) {
            IERC721Upgradeable(data.terms.collateralAddress).transferFrom(
                address(this),
                borrower,
                data.terms.collateralId
            );

            if (_paymentToPrincipal > _balanceToPay) {
                // Borrower overpaid, so send refund
                IERC20Upgradeable(data.terms.payableCurrency).safeTransfer(
                    borrower,
                    _paymentToPrincipal - _balanceToPay
                );
            }

            emit LoanRepaid(_loanId);
        } else {
            // minimum repayment events will emit 0 and unchanged principal
            emit InstallmentPaymentReceived(_loanId, _paymentToPrincipal, data.balance);
        }
    }

    // ======================================== NONCE MANAGEMENT ========================================

    /**
     * @notice Mark a nonce as used in the context of starting a loan. Reverts if
     *         nonce has already been used. Can only be called by Origination Controller.
     *
     * @param user                  The user for whom to consume a nonce.
     * @param nonce                 The nonce to consume.
     */
    function consumeNonce(address user, uint160 nonce) external override whenNotPaused onlyRole(ORIGINATOR_ROLE) {
        _useNonce(user, nonce);
    }

    /**
     * @notice Mark a nonce as used in order to invalidate signatures with the nonce.
     *         Does not allow specifying the user, and automatically consumes the nonce
     *         of the caller.
     *
     * @param nonce                 The nonce to consume.
     */
    function cancelNonce(uint160 nonce) external override {
        _useNonce(_msgSender(), nonce);
    }

    // ========================================= VIEW FUNCTIONS =========================================

    /**
     * @notice Returns the LoanData struct for the specified loan ID.
     *
     * @param loanId                The ID of the given loan.
     *
     * @return loanData             The struct containing loan state and terms.
     */
    function getLoan(uint256 loanId) external view override returns (LoanLibrary.LoanData memory loanData) {
        return loans[loanId];
    }

    /**
     * @notice Reports if the caller is allowed to call functions on the given vault.
     *         Determined by if they are the borrower for the loan, defined by ownership
     *         of the relevant BorrowerNote.
     *
     * @dev Implemented as part of the ICallDelegator interface.
     *
     * @param caller                The user that wants to call a function.
     * @param vault                 The vault that the caller wants to call a function on.
     *
     * @return allowed              True if the caller is allowed to call on the vault.
     */
    function canCallOn(address caller, address vault) external view override returns (bool) {
        // if the collateral is not currently being used in a loan, disallow
        if (!collateralInUse[keccak256(abi.encode(OwnableERC721(vault).ownershipToken(), uint256(uint160(vault))))]) {
            return false;
        }
        for (uint256 i = 0; i < borrowerNote.balanceOf(caller); i++) {
            uint256 loanId = borrowerNote.tokenOfOwnerByIndex(caller, i);

            // if the borrower is currently borrowing against this vault,
            // return true
            if (loans[loanId].terms.collateralId == uint256(uint160(vault))) {
                return true;
            }
        }
        return false;
    }

    /**
     * @notice Reports whether the given nonce has been previously used by a user. Returning
     *         false does not mean that the nonce will not clash with another potential off-chain
     *         signature that is stored somewhere.
     *
     * @param user                  The user to check the nonce for.
     * @param nonce                 The nonce to check.
     *
     * @return used                 Whether the nonce has been used.
     */
    function isNonceUsed(address user, uint160 nonce) external view override returns (bool) {
        return usedNonces[user][nonce];
    }

    // ======================================== ADMIN FUNCTIONS =========================================

    /**
     * @notice Sets the fee controller to a new address. It must implement the
     *         IFeeController interface. Can only be called by the contract owner.
     *
     * @param _newController        The new fee controller contract.
     */
    function setFeeController(IFeeController _newController) external onlyRole(FEE_CLAIMER_ROLE) {
        if (address(_newController) == address(0)) revert LC_ZeroAddress();

        feeController = _newController;

        emit SetFeeController(address(feeController));
    }

    /**
     * @notice Claim the protocol fees for the given token. Any token used as principal
     *         for a loan will have accumulated fees. Must be called by contract owner.
     *
     * @param token                 The contract address of the token to claim fees for.
     */
    function claimFees(IERC20Upgradeable token) external onlyRole(FEE_CLAIMER_ROLE) {
        // any token balances remaining on this contract are fees owned by the protocol
        uint256 amount = token.balanceOf(address(this));
        token.safeTransfer(_msgSender(), amount);
        emit FeesClaimed(address(token), _msgSender(), amount);
    }

    /**
     * @notice Pauses the contract, preventing loan lifecyle operations.
     *         Should only be used in case of emergency. Can only be called
     *         by contract owner.
     */
    function pause() external onlyRole(ADMIN_ROLE) {
        _pause();
    }

    /**
     * @notice Unpauses the contract, enabling loan lifecycle operations.
     *         Can be used after pausing due to emergency or during contract
     *         upgrade. Can only be called by contract owner.
     */
    function unpause() external onlyRole(ADMIN_ROLE) {
        _unpause();
    }

    // ============================================= HELPERS ============================================

    /**
     * @dev Takes a principal value and returns the amount that will be distributed
     *      to the borrower after protocol fees.
     *
     * @param principal             The principal amount.
     *
     * @return principalLessFees    The amount after fees.
     */
    function _getPrincipalLessFees(uint256 principal) internal view returns (uint256) {
        return principal - (principal * feeController.getOriginationFee()) / BASIS_POINTS_DENOMINATOR;
    }

    /**
     * @dev Consume a nonce, by marking it as used for that user. Reverts if the nonce
     *      has already been used.
     *
     * @param user                  The user for whom to consume a nonce.
     * @param nonce                 The nonce to consume.
     */
    function _useNonce(address user, uint160 nonce) internal {
        if (usedNonces[user][nonce]) revert LC_NonceUsed(user, nonce);
        // set nonce to used
        usedNonces[user][nonce] = true;

        emit NonceUsed(user, nonce);
    }

    /**
     * @notice Check collateral is available to claim via default.
     *         This function passes when the last payment made by the borrower
     *         was made over 40% of the total number of installment periods previously.
     *         For example a loan with 10 installment periods. The borrower would
     *         have to miss 4 consecutive payments during the loan to default.
     *
     * @dev Missed payments checked are consecutive due how the numInstallmentsPaid
     *      value in LoanData is being updated to the current installment period
     *      everytime a repayment at any time is made for an installment loan.
     *      (numInstallmentsPaid += _currentMissedPayments + 1).
     *
     * @param numInstallments                  Total number of installments in loan.
     * @param numInstallmentsPaid              Installment period of the last installment payment.
     * @param currentInstallmentPeriod         Current installment period call made in.
     */
    function _verifyDefaultedLoan(
        uint256 numInstallments,
        uint256 numInstallmentsPaid,
        uint256 currentInstallmentPeriod
    ) internal pure {
        // make sure if called in the same installment period as payment was made,
        // does not get to currentInstallmentsMissed calculation. needs to be first.
        if (numInstallmentsPaid == currentInstallmentPeriod) revert LC_LoanNotDefaulted();

        // get installments missed necessary for loan default (*1000)
        uint256 installmentsMissedForDefault = ((numInstallments * PERCENT_MISSED_FOR_LENDER_CLAIM) * 1000) /
            BASIS_POINTS_DENOMINATOR;

        // get current installments missed (*1000)
        // +1 added to numInstallmentsPaid as a grace period on the current installment payment.
        uint256 currentInstallmentsMissed = ((currentInstallmentPeriod) * 1000) - ((numInstallmentsPaid + 1) * 1000);

        // check if the number of missed payments is greater than
        // 40% the total number of installment periods
        if (currentInstallmentsMissed < installmentsMissedForDefault) revert LC_LoanNotDefaulted();
    }

    /*
     * @dev Mint a borrower and lender note together - easier to make sure
     *      they are synchronized.
     *
     * @param loanId                The token ID to mint.
     * @param borrower              The address of the recipient of the borrower note.
     * @param lender                The address of the recpient of the lender note.
     */
    function _mintLoanNotes(
        uint256 loanId,
        address borrower,
        address lender
    ) internal {
        borrowerNote.mint(borrower, loanId);
        lenderNote.mint(lender, loanId);
    }

    /**
     * @dev Burn a borrower and lender note together - easier to make sure
     *      they are synchronized.
     *
     * @param loanId                The token ID to burn.
     */
    function _burnLoanNotes(uint256 loanId) internal {
        lenderNote.burn(loanId);
        borrowerNote.burn(loanId);
    }

    /**
     * @dev Perform an ERC20 transfer, if the specified amount is nonzero - else no-op.
     *
     * @param token                 The token to transfer.
     * @param to                    The address receiving the tokens.
     * @param amount                The amount of tokens to transfer.
     */
    function _transferIfNonzero(
        IERC20Upgradeable token,
        address to,
        uint256 amount
    ) internal {
        if (amount > 0) token.safeTransfer(to, amount);
    }

    /**
     * @dev Used on upgrade to set the initial value of the reentrancy lock.
     */
    function setLock() external onlyRole(ADMIN_ROLE) {
        require(!_lockSet, "lock already set");

        _lockSet = true;
        _locked = 1;
    }

    /**
     * @dev Reentrancy guard, checking locked state.
     */
    modifier nonReentrant() {
        require(_locked == 1, "REENTRANCY");

        _locked = 2;

        _;

        _locked = 1;
    }
}
// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.7;

import { IERC20 }                from "../modules/erc20/contracts/interfaces/IERC20.sol";
import { ERC20Helper }           from "../modules/erc20-helper/src/ERC20Helper.sol";
import { IMapleProxyFactory }    from "../modules/maple-proxy-factory/contracts/interfaces/IMapleProxyFactory.sol";
import { MapleProxiedInternals } from "../modules/maple-proxy-factory/contracts/MapleProxiedInternals.sol";

import { IMapleLoan }           from "./interfaces/IMapleLoan.sol";
import { IMapleLoanFeeManager } from "./interfaces/IMapleLoanFeeManager.sol";

import { IGlobalsLike, ILenderLike, IMapleProxyFactoryLike } from "./interfaces/Interfaces.sol";

import { MapleLoanStorage } from "./MapleLoanStorage.sol";

/*

    ███╗   ███╗ █████╗ ██████╗ ██╗     ███████╗    ██╗      ██████╗  █████╗ ███╗   ██╗    ██╗   ██╗███████╗
    ████╗ ████║██╔══██╗██╔══██╗██║     ██╔════╝    ██║     ██╔═══██╗██╔══██╗████╗  ██║    ██║   ██║██╔════╝
    ██╔████╔██║███████║██████╔╝██║     █████╗      ██║     ██║   ██║███████║██╔██╗ ██║    ██║   ██║███████╗
    ██║╚██╔╝██║██╔══██║██╔═══╝ ██║     ██╔══╝      ██║     ██║   ██║██╔══██║██║╚██╗██║    ╚██╗ ██╔╝╚════██║
    ██║ ╚═╝ ██║██║  ██║██║     ███████╗███████╗    ███████╗╚██████╔╝██║  ██║██║ ╚████║     ╚████╔╝ ███████║
    ╚═╝     ╚═╝╚═╝  ╚═╝╚═╝     ╚══════╝╚══════╝    ╚══════╝ ╚═════╝ ╚═╝  ╚═╝╚═╝  ╚═══╝      ╚═══╝  ╚══════╝

*/

/// @title MapleLoan implements a primitive loan with additional functionality, and is intended to be proxied.
contract MapleLoan is IMapleLoan, MapleProxiedInternals, MapleLoanStorage {

    uint256 public constant override HUNDRED_PERCENT = 1e6;

    uint256 private constant SCALED_ONE = 1e18;

    modifier limitDrawableUse() {
        if (msg.sender == _borrower) {
            _;
            return;
        }

        uint256 drawableFundsBeforePayment = _drawableFunds;

        _;

        // Either the caller is the borrower or `_drawableFunds` has not decreased.
        require(_drawableFunds >= drawableFundsBeforePayment, "ML:CANNOT_USE_DRAWABLE");
    }

    modifier onlyBorrower() {
        _revertIfNotBorrower();
        _;
    }

    modifier onlyLender() {
        _revertIfNotLender();
        _;
    }

    modifier whenNotPaused() {
        _revertIfPaused();
        _;
    }

    /**************************************************************************************************************************************/
    /*** Administrative Functions                                                                                                       ***/
    /**************************************************************************************************************************************/

    function migrate(address migrator_, bytes calldata arguments_) external override whenNotPaused {
        require(msg.sender == _factory(),        "ML:M:NOT_FACTORY");
        require(_migrate(migrator_, arguments_), "ML:M:FAILED");
    }

    function setImplementation(address newImplementation_) external override whenNotPaused {
        require(msg.sender == _factory(),               "ML:SI:NOT_FACTORY");
        require(_setImplementation(newImplementation_), "ML:SI:FAILED");
    }

    function upgrade(uint256 toVersion_, bytes calldata arguments_) external override whenNotPaused {
        require(msg.sender == IGlobalsLike(globals()).securityAdmin(), "ML:U:NO_AUTH");

        emit Upgraded(toVersion_, arguments_);

        IMapleProxyFactory(_factory()).upgradeInstance(toVersion_, arguments_);
    }

    /**************************************************************************************************************************************/
    /*** Borrow Functions                                                                                                               ***/
    /**************************************************************************************************************************************/

    function acceptBorrower() external override whenNotPaused {
        require(msg.sender == _pendingBorrower, "ML:AB:NOT_PENDING_BORROWER");

        _pendingBorrower = address(0);

        emit BorrowerAccepted(_borrower = msg.sender);
    }

    function closeLoan(uint256 amount_)
        external override whenNotPaused limitDrawableUse returns (uint256 principal_, uint256 interest_, uint256 fees_)
    {
        // The amount specified is an optional amount to be transferred from the caller, as a convenience for EOAs.
        // NOTE: FUNDS SHOULD NOT BE TRANSFERRED TO THIS CONTRACT NON-ATOMICALLY. IF THEY ARE, THE BALANCE MAY BE STOLEN USING `skim`.
        require(
            amount_ == uint256(0) || ERC20Helper.transferFrom(_fundsAsset, msg.sender, address(this), amount_),
            "ML:CL:TRANSFER_FROM_FAILED"
        );

        uint256 paymentDueDate_ = _nextPaymentDueDate;

        require(block.timestamp <= paymentDueDate_, "ML:CL:PAYMENT_IS_LATE");


        ( principal_, interest_, ) = getClosingPaymentBreakdown();

        _refinanceInterest = uint256(0);

        uint256 principalAndInterest_ = principal_ + interest_;

        // The drawable funds are increased by the extra funds in the contract, minus the total needed for payment.
        // NOTE: This line will revert if not enough funds were added for the full payment amount.
        _drawableFunds = (_drawableFunds + getUnaccountedAmount(_fundsAsset)) - principalAndInterest_;

        fees_ = _handleServiceFeePayment(_paymentsRemaining);

        // NOTE: Closing a loan always results in the an impairment being removed.
        _clearLoanAccounting();

        emit LoanClosed(principal_, interest_, fees_);

        require(ERC20Helper.transfer(_fundsAsset, _lender, principalAndInterest_), "ML:MP:TRANSFER_FAILED");

        ILenderLike(_lender).claim(principal_, interest_, paymentDueDate_, 0);

        emit FundsClaimed(principalAndInterest_, _lender);
    }

    function drawdownFunds(uint256 amount_, address destination_) external override whenNotPaused onlyBorrower returns (uint256 collateralPosted_) {
        emit FundsDrawnDown(amount_, destination_);

        // Post additional collateral required to facilitate this drawdown, if needed.
        uint256 additionalCollateralRequired_ = getAdditionalCollateralRequiredFor(amount_);

        if (additionalCollateralRequired_ > uint256(0)) {
            // Determine collateral currently unaccounted for.
            uint256 unaccountedCollateral_ = getUnaccountedAmount(_collateralAsset);

            // Post required collateral, specifying then amount lacking as the optional amount to be transferred from.
            collateralPosted_ = postCollateral(
                additionalCollateralRequired_ > unaccountedCollateral_ ? additionalCollateralRequired_ - unaccountedCollateral_ : uint256(0)
            );
        }

        _drawableFunds -= amount_;

        require(ERC20Helper.transfer(_fundsAsset, destination_, amount_), "ML:DF:TRANSFER_FAILED");
        require(_isCollateralMaintained(),                                "ML:DF:INSUFFICIENT_COLLATERAL");
    }

    function makePayment(uint256 amount_)
        external override whenNotPaused limitDrawableUse returns (uint256 principal_, uint256 interest_, uint256 fees_)
    {
        // The amount specified is an optional amount to be transfer from the caller, as a convenience for EOAs.
        // NOTE: FUNDS SHOULD NOT BE TRANSFERRED TO THIS CONTRACT NON-ATOMICALLY. IF THEY ARE, THE BALANCE MAY BE STOLEN USING `skim`.
        require(
            amount_ == uint256(0) || ERC20Helper.transferFrom(_fundsAsset, msg.sender, address(this), amount_),
            "ML:MP:TRANSFER_FROM_FAILED"
        );

        ( principal_, interest_, ) = getNextPaymentBreakdown();

        _refinanceInterest = uint256(0);

        uint256 principalAndInterest_ = principal_ + interest_;

        // The drawable funds are increased by the extra funds in the contract, minus the total needed for payment.
        // NOTE: This line will revert if not enough funds were added for the full payment amount.
        _drawableFunds = (_drawableFunds + getUnaccountedAmount(_fundsAsset)) - principalAndInterest_;

        fees_ = _handleServiceFeePayment(1);

        uint256 paymentsRemaining_      = _paymentsRemaining;
        uint256 previousPaymentDueDate_ = _nextPaymentDueDate;
        uint256 nextPaymentDueDate_;

        // NOTE: Making a payment always results in the impairment being removed.
        if (paymentsRemaining_ == uint256(1)) {
            _clearLoanAccounting();  // Assumes `getNextPaymentBreakdown` returns a `principal_` that is `_principal`.
        } else {
            _nextPaymentDueDate  = nextPaymentDueDate_ = previousPaymentDueDate_ + _paymentInterval;
            _principal          -= principal_;
            _paymentsRemaining   = paymentsRemaining_ - uint256(1);

            delete _originalNextPaymentDueDate;
        }

        emit PaymentMade(principal_, interest_, fees_);

        require(ERC20Helper.transfer(_fundsAsset, _lender, principalAndInterest_), "ML:MP:TRANSFER_FAILED");

        ILenderLike(_lender).claim(principal_, interest_, previousPaymentDueDate_, nextPaymentDueDate_);

        emit FundsClaimed(principalAndInterest_, _lender);

        require(_isCollateralMaintained(), "ML:MP:INSUFFICIENT_COLLATERAL");
    }

    function postCollateral(uint256 amount_) public override whenNotPaused returns (uint256 collateralPosted_) {
        // The amount specified is an optional amount to be transfer from the caller, as a convenience for EOAs.
        // NOTE: FUNDS SHOULD NOT BE TRANSFERRED TO THIS CONTRACT NON-ATOMICALLY. IF THEY ARE, THE BALANCE MAY BE STOLEN USING `skim`.
        require(
            amount_ == uint256(0) || ERC20Helper.transferFrom(_collateralAsset, msg.sender, address(this), amount_),
            "ML:PC:TRANSFER_FROM_FAILED"
        );

        _collateral += (collateralPosted_ = getUnaccountedAmount(_collateralAsset));

        emit CollateralPosted(collateralPosted_);
    }

    function proposeNewTerms(address refinancer_, uint256 deadline_, bytes[] calldata calls_)
        external override whenNotPaused onlyBorrower returns (bytes32 refinanceCommitment_)
    {
        require(deadline_ >= block.timestamp,                                       "ML:PNT:INVALID_DEADLINE");
        require(IGlobalsLike(globals()).isInstanceOf("FT_REFINANCER", refinancer_), "ML:PNT:INVALID_REFINANCER");
        require(calls_.length > uint256(0),                                         "ML:PNT:EMPTY_CALLS");

        emit NewTermsProposed(
            _refinanceCommitment = refinanceCommitment_ = _getRefinanceCommitment(refinancer_, deadline_, calls_),
            refinancer_,
            deadline_,
            calls_
        );
    }

    function removeCollateral(uint256 amount_, address destination_) external override whenNotPaused onlyBorrower {
        emit CollateralRemoved(amount_, destination_);

        _collateral -= amount_;

        require(ERC20Helper.transfer(_collateralAsset, destination_, amount_), "ML:RC:TRANSFER_FAILED");
        require(_isCollateralMaintained(),                                     "ML:RC:INSUFFICIENT_COLLATERAL");
    }

    function returnFunds(uint256 amount_) external override whenNotPaused returns (uint256 fundsReturned_) {
        // The amount specified is an optional amount to be transfer from the caller, as a convenience for EOAs.
        // NOTE: FUNDS SHOULD NOT BE TRANSFERRED TO THIS CONTRACT NON-ATOMICALLY. IF THEY ARE, THE BALANCE MAY BE STOLEN USING `skim`.
        require(
            amount_ == uint256(0) || ERC20Helper.transferFrom(_fundsAsset, msg.sender, address(this), amount_),
            "ML:RF:TRANSFER_FROM_FAILED"
        );

        _drawableFunds += (fundsReturned_ = getUnaccountedAmount(_fundsAsset));

        emit FundsReturned(fundsReturned_);
    }

    function setPendingBorrower(address pendingBorrower_) external override whenNotPaused onlyBorrower {
        require(IGlobalsLike(globals()).isBorrower(pendingBorrower_), "ML:SPB:INVALID_BORROWER");

        emit PendingBorrowerSet(_pendingBorrower = pendingBorrower_);
    }

    /**************************************************************************************************************************************/
    /*** Lend Functions                                                                                                                 ***/
    /**************************************************************************************************************************************/

    function acceptLender() external override whenNotPaused {
        require(msg.sender == _pendingLender, "ML:AL:NOT_PENDING_LENDER");

        _pendingLender = address(0);

        emit LenderAccepted(_lender = msg.sender);
    }

    function acceptNewTerms(address refinancer_, uint256 deadline_, bytes[] calldata calls_)
        external override whenNotPaused onlyLender returns (bytes32 refinanceCommitment_)
    {
        // NOTE: A zero refinancer address and/or empty calls array will never (probabilistically) match a refinance commitment in storage.
        require(
            _refinanceCommitment == (refinanceCommitment_ = _getRefinanceCommitment(refinancer_, deadline_, calls_)),
            "ML:ANT:COMMITMENT_MISMATCH"
        );

        require(refinancer_.code.length != uint256(0), "ML:ANT:INVALID_REFINANCER");

        require(block.timestamp <= deadline_, "ML:ANT:EXPIRED_COMMITMENT");

        uint256 paymentInterval_           = _paymentInterval;
        uint256 nextPaymentDueDate_        = _nextPaymentDueDate;
        uint256 previousPrincipalRequested = _principalRequested;

        uint256 timeSinceLastDueDate_ = block.timestamp + paymentInterval_ < nextPaymentDueDate_
            ? 0
            : block.timestamp - (nextPaymentDueDate_ - paymentInterval_);

        // Not ideal for checks-effects-interactions,
        // but the feeManager is a trusted contract and it's needed to save the fee before refinance.
        IMapleLoanFeeManager feeManager_ = IMapleLoanFeeManager(_feeManager);
        feeManager_.updateRefinanceServiceFees(previousPrincipalRequested, timeSinceLastDueDate_);

        // Get the amount of interest owed since the last payment due date, as well as the time since the last due date
        uint256 proRataInterest_ = getRefinanceInterest(block.timestamp);

        // In case there is still a refinance interest, just increment it instead of setting it.
        _refinanceInterest += proRataInterest_;

        // Clear refinance commitment to prevent implications of re-acceptance of another call to `_acceptNewTerms`.
        delete _refinanceCommitment;

        // NOTE: Accepting new terms always results in the an impairment being removed.
        delete _originalNextPaymentDueDate;

        for (uint256 i_; i_ < calls_.length; ++i_) {
            ( bool success_, ) = refinancer_.delegatecall(calls_[i_]);
            require(success_, "ML:ANT:FAILED");
        }

        // TODO: Emit this before the refinance calls in order to adhere to the CEI pattern.
        emit NewTermsAccepted(refinanceCommitment_, refinancer_, deadline_, calls_);

        address fundsAsset_         = _fundsAsset;
        uint256 principalRequested_ = _principalRequested;

        paymentInterval_ = _paymentInterval;

        // Increment the due date to be one full payment interval from now, to restart the payment schedule with new terms.
        // NOTE: `_paymentInterval` here is possibly newly set via the above delegate calls, so cache it.
        _nextPaymentDueDate = block.timestamp + paymentInterval_;

        // Update Platform Fees and pay originations.
        feeManager_.updatePlatformServiceFee(principalRequested_, paymentInterval_);

        _drawableFunds -= feeManager_.payOriginationFees(fundsAsset_, principalRequested_);

        // Ensure that collateral is maintained after changes made.
        require(_isCollateralMaintained(),                       "ML:ANT:INSUFFICIENT_COLLATERAL");
        require(getUnaccountedAmount(fundsAsset_) == uint256(0), "ML:ANT:UNEXPECTED_FUNDS");
    }

    function fundLoan() external override whenNotPaused onlyLender returns (uint256 fundsLent_) {
        address lender_ = _lender;

        // Can only fund loan if there are payments remaining (defined in the initialization) and no payment is due (as set by a funding).
        require((_nextPaymentDueDate == uint256(0)) && (_paymentsRemaining != uint256(0)), "ML:FL:LOAN_ACTIVE");

        address fundsAsset_         = _fundsAsset;
        uint256 paymentInterval_    = _paymentInterval;
        uint256 principalRequested_ = _principalRequested;

        require(ERC20Helper.approve(fundsAsset_, _feeManager, type(uint256).max), "ML:FL:APPROVE_FAIL");

        // Saves the platform service fee rate for future payments.
        IMapleLoanFeeManager(_feeManager).updatePlatformServiceFee(principalRequested_, paymentInterval_);

        uint256 originationFees_ = IMapleLoanFeeManager(_feeManager).payOriginationFees(fundsAsset_, principalRequested_);

        _drawableFunds += (principalRequested_ - originationFees_);

        require(getUnaccountedAmount(fundsAsset_) == uint256(0), "ML:FL:UNEXPECTED_FUNDS");

        emit Funded(
            lender_,
            fundsLent_ = _principal = principalRequested_,
            _nextPaymentDueDate = block.timestamp + paymentInterval_
        );
    }

    function impairLoan() external override whenNotPaused onlyLender {
        uint256 originalNextPaymentDueDate_ = _nextPaymentDueDate;

        // If the loan is late, do not change the payment due date.
        uint256 newPaymentDueDate_ = block.timestamp > originalNextPaymentDueDate_ ? originalNextPaymentDueDate_ : block.timestamp;

        emit LoanImpaired(newPaymentDueDate_);

        _nextPaymentDueDate         = newPaymentDueDate_;
        _originalNextPaymentDueDate = originalNextPaymentDueDate_;  // Store the existing payment due date to enable reversion.
    }

    function removeLoanImpairment() external override whenNotPaused onlyLender {
        uint256 originalNextPaymentDueDate_ = _originalNextPaymentDueDate;

        require(originalNextPaymentDueDate_ != 0,               "ML:RLI:NOT_IMPAIRED");
        require(block.timestamp <= originalNextPaymentDueDate_, "ML:RLI:PAST_DATE");

        _nextPaymentDueDate = originalNextPaymentDueDate_;
        delete _originalNextPaymentDueDate;

        emit ImpairmentRemoved(originalNextPaymentDueDate_);
    }

    function repossess(address destination_)
        external override whenNotPaused onlyLender returns (uint256 collateralRepossessed_, uint256 fundsRepossessed_)
    {
        uint256 nextPaymentDueDate_ = _nextPaymentDueDate;

        require(
            nextPaymentDueDate_ != uint256(0) && (block.timestamp > nextPaymentDueDate_ + _gracePeriod),
            "ML:R:NOT_IN_DEFAULT"
        );

        _clearLoanAccounting();

        // Uniquely in `_repossess`, stop accounting for all funds so that they can be swept.
        _collateral    = uint256(0);
        _drawableFunds = uint256(0);

        address collateralAsset_ = _collateralAsset;

        // Either there is no collateral to repossess, or the transfer of the collateral succeeds.
        require(
            (collateralRepossessed_ = getUnaccountedAmount(collateralAsset_)) == uint256(0) ||
            ERC20Helper.transfer(collateralAsset_, destination_, collateralRepossessed_),
            "ML:R:C_TRANSFER_FAILED"
        );

        address fundsAsset_ = _fundsAsset;

        // Either there are no funds to repossess, or the transfer of the funds succeeds.
        require(
            (fundsRepossessed_ = getUnaccountedAmount(fundsAsset_)) == uint256(0) ||
            ERC20Helper.transfer(fundsAsset_, destination_, fundsRepossessed_),
            "ML:R:F_TRANSFER_FAILED"
        );

        emit Repossessed(collateralRepossessed_, fundsRepossessed_, destination_);
    }

    function setPendingLender(address pendingLender_) external override whenNotPaused onlyLender {
        emit PendingLenderSet(_pendingLender = pendingLender_);
    }

    /**************************************************************************************************************************************/
    /*** Miscellaneous Functions                                                                                                        ***/
    /**************************************************************************************************************************************/

    function rejectNewTerms(address refinancer_, uint256 deadline_, bytes[] calldata calls_)
        external override whenNotPaused returns (bytes32 refinanceCommitment_)
    {
        require((msg.sender == _borrower) || (msg.sender == _lender), "ML:RNT:NO_AUTH");

        require(
            _refinanceCommitment == (refinanceCommitment_ = _getRefinanceCommitment(refinancer_, deadline_, calls_)),
            "ML:RNT:COMMITMENT_MISMATCH"
        );

        _refinanceCommitment = bytes32(0);

        emit NewTermsRejected(refinanceCommitment_, refinancer_, deadline_, calls_);
    }

    function skim(address token_, address destination_) external override whenNotPaused returns (uint256 skimmed_) {
        emit Skimmed(token_, skimmed_ = getUnaccountedAmount(token_), destination_);
        require(ERC20Helper.transfer(token_, destination_, skimmed_), "ML:S:TRANSFER_FAILED");
    }

    /**************************************************************************************************************************************/
    /*** View Functions                                                                                                                 ***/
    /**************************************************************************************************************************************/

    function getAdditionalCollateralRequiredFor(uint256 drawdown_) public view override returns (uint256 collateral_) {
        // Determine the collateral needed in the contract for a reduced drawable funds amount.
        uint256 collateralNeeded_  = _getCollateralRequiredFor(_principal, _drawableFunds - drawdown_, _principalRequested, _collateralRequired);
        uint256 currentCollateral_ = _collateral;

        collateral_ = collateralNeeded_ > currentCollateral_ ? collateralNeeded_ - currentCollateral_ : uint256(0);
    }

    function getClosingPaymentBreakdown() public view override returns (uint256 principal_, uint256 interest_, uint256 fees_) {
        (
            uint256 delegateServiceFee_,
            uint256 delegateRefinanceFee_,
            uint256 platformServiceFee_,
            uint256 platformRefinanceFee_
        ) = IMapleLoanFeeManager(_feeManager).getServiceFeeBreakdown(address(this), _paymentsRemaining);

        fees_ = delegateServiceFee_ + platformServiceFee_ + delegateRefinanceFee_ + platformRefinanceFee_;

        // Compute interest and include any uncaptured interest from refinance.
        interest_ = (((principal_ = _principal) * _closingRate) / HUNDRED_PERCENT) + _refinanceInterest;
    }

    function getNextPaymentDetailedBreakdown()
        public view override returns (uint256 principal_, uint256[3] memory interest_, uint256[2] memory fees_)
    {
        ( principal_, interest_, fees_ )
            = _getPaymentBreakdown(
                block.timestamp,
                _nextPaymentDueDate,
                _paymentInterval,
                _principal,
                _endingPrincipal,
                _paymentsRemaining,
                _interestRate,
                _lateFeeRate,
                _lateInterestPremiumRate
            );
    }

    function getNextPaymentBreakdown() public view override returns (uint256 principal_, uint256 interest_, uint256 fees_) {
        uint256[3] memory interestArray_;
        uint256[2] memory feesArray_;

        ( principal_, interestArray_, feesArray_ ) = _getPaymentBreakdown(
            block.timestamp,
            _nextPaymentDueDate,
            _paymentInterval,
            _principal,
            _endingPrincipal,
            _paymentsRemaining,
            _interestRate,
            _lateFeeRate,
            _lateInterestPremiumRate
        );

        interest_ = interestArray_[0] + interestArray_[1] + interestArray_[2];
        fees_     = feesArray_[0]     + feesArray_[1];
    }

    function getRefinanceInterest(uint256 timestamp_) public view override returns (uint256 proRataInterest_) {
        proRataInterest_ = _getRefinanceInterest(
            timestamp_,
            _paymentInterval,
            _principal,
            _endingPrincipal,
            _interestRate,
            _paymentsRemaining,
            _nextPaymentDueDate,
            _lateFeeRate,
            _lateInterestPremiumRate
        );
    }

    function getUnaccountedAmount(address asset_) public view override returns (uint256 unaccountedAmount_) {
        unaccountedAmount_ = IERC20(asset_).balanceOf(address(this))
            - (asset_ == _collateralAsset ? _collateral    : uint256(0))   // `_collateral` is `_collateralAsset` accounted for.
            - (asset_ == _fundsAsset      ? _drawableFunds : uint256(0));  // `_drawableFunds` is `_fundsAsset` accounted for.
    }

    /**************************************************************************************************************************************/
    /*** State View Functions                                                                                                           ***/
    /**************************************************************************************************************************************/

    function borrower() external view override returns (address borrower_) {
        borrower_ = _borrower;
    }

    function closingRate() external view override returns (uint256 closingRate_) {
        closingRate_ = _closingRate;
    }

    function collateral() external view override returns (uint256 collateral_) {
        collateral_ = _collateral;
    }

    function collateralAsset() external view override returns (address collateralAsset_) {
        collateralAsset_ = _collateralAsset;
    }

    function collateralRequired() external view override returns (uint256 collateralRequired_) {
        collateralRequired_ = _collateralRequired;
    }

    function drawableFunds() external view override returns (uint256 drawableFunds_) {
        drawableFunds_ = _drawableFunds;
    }

    function endingPrincipal() external view override returns (uint256 endingPrincipal_) {
        endingPrincipal_ = _endingPrincipal;
    }

    function excessCollateral() external view override returns (uint256 excessCollateral_) {
        uint256 collateralNeeded_  = _getCollateralRequiredFor(_principal, _drawableFunds, _principalRequested, _collateralRequired);
        uint256 currentCollateral_ = _collateral;

        excessCollateral_ = currentCollateral_ > collateralNeeded_ ? currentCollateral_ - collateralNeeded_ : uint256(0);
    }

    function factory() external view override returns (address factory_) {
        factory_ = _factory();
    }

    function feeManager() external view override returns (address feeManager_) {
        feeManager_ = _feeManager;
    }

    function fundsAsset() external view override returns (address fundsAsset_) {
        fundsAsset_ = _fundsAsset;
    }

    function globals() public view override returns (address globals_) {
        globals_ = IMapleProxyFactoryLike(_factory()).mapleGlobals();
    }

    function governor() public view override returns (address governor_) {
        governor_ = IGlobalsLike(globals()).governor();
    }

    function gracePeriod() external view override returns (uint256 gracePeriod_) {
        gracePeriod_ = _gracePeriod;
    }

    function implementation() external view override returns (address implementation_) {
        implementation_ = _implementation();
    }

    function interestRate() external view override returns (uint256 interestRate_) {
        interestRate_ = _interestRate;
    }

    function isImpaired() public view override returns (bool isImpaired_) {
        isImpaired_ = _originalNextPaymentDueDate != uint256(0);
    }

    function lateFeeRate() external view override returns (uint256 lateFeeRate_) {
        lateFeeRate_ = _lateFeeRate;
    }

    function lateInterestPremiumRate() external view override returns (uint256 lateInterestPremiumRate_) {
        lateInterestPremiumRate_ = _lateInterestPremiumRate;
    }

    function lender() external view override returns (address lender_) {
        lender_ = _lender;
    }

    function nextPaymentDueDate() external view override returns (uint256 nextPaymentDueDate_) {
        nextPaymentDueDate_ = _nextPaymentDueDate;
    }

    function originalNextPaymentDueDate() external view override returns (uint256 originalNextPaymentDueDate_) {
        originalNextPaymentDueDate_ = _originalNextPaymentDueDate;
    }

    function paymentInterval() external view override returns (uint256 paymentInterval_) {
        paymentInterval_ = _paymentInterval;
    }

    function paymentsRemaining() external view override returns (uint256 paymentsRemaining_) {
        paymentsRemaining_ = _paymentsRemaining;
    }

    function pendingBorrower() external view override returns (address pendingBorrower_) {
        pendingBorrower_ = _pendingBorrower;
    }

    function pendingLender() external view override returns (address pendingLender_) {
        pendingLender_ = _pendingLender;
    }

    function principal() external view override returns (uint256 principal_) {
        principal_ = _principal;
    }

    function principalRequested() external view override returns (uint256 principalRequested_) {
        principalRequested_ = _principalRequested;
    }

    function refinanceCommitment() external view override returns (bytes32 refinanceCommitment_) {
        refinanceCommitment_ = _refinanceCommitment;
    }

    function refinanceInterest() external view override returns (uint256 refinanceInterest_) {
        refinanceInterest_ = _refinanceInterest;
    }

    /**************************************************************************************************************************************/
    /*** Internal General Functions                                                                                                     ***/
    /**************************************************************************************************************************************/

    /// @dev Clears all state variables to end a loan, but keep borrower and lender withdrawal functionality intact.
    function _clearLoanAccounting() internal {
        _refinanceCommitment = bytes32(0);

        _gracePeriod     = uint256(0);
        _paymentInterval = uint256(0);

        _interestRate            = uint256(0);
        _closingRate             = uint256(0);
        _lateFeeRate             = uint256(0);
        _lateInterestPremiumRate = uint256(0);

        _endingPrincipal = uint256(0);

        _nextPaymentDueDate = uint256(0);
        _paymentsRemaining  = uint256(0);
        _principal          = uint256(0);

        _refinanceInterest = uint256(0);

        _originalNextPaymentDueDate = uint256(0);
    }

    /**************************************************************************************************************************************/
    /*** Internal Pure/View Functions                                                                                                   ***/
    /**************************************************************************************************************************************/

    /// @dev Returns the total collateral to be posted for some drawn down (outstanding) principal and overall collateral ratio requirement.
    function _getCollateralRequiredFor(
        uint256 principal_,
        uint256 drawableFunds_,
        uint256 principalRequested_,
        uint256 collateralRequired_
    )
        internal pure returns (uint256 collateral_)
    {
        // Where (collateral / outstandingPrincipal) should be greater or equal to (collateralRequired / principalRequested).
        // NOTE: principalRequested_ cannot be 0, which is reasonable, since it means this was never a loan.
        collateral_ = principal_ <= drawableFunds_
            ? uint256(0)
            : (collateralRequired_ * (principal_ - drawableFunds_) + principalRequested_ - 1) / principalRequested_;
    }

    /// @dev Returns principal and interest portions of a payment instalment, given generic, stateless loan parameters.
    function _getInstallment(
        uint256 principal_,
        uint256 endingPrincipal_,
        uint256 interestRate_,
        uint256 paymentInterval_,
        uint256 totalPayments_
    )
        internal pure returns (uint256 principalAmount_, uint256 interestAmount_)
    {
        /*************************************************************************************************\
         *                             |                                                                 *
         * A = installment amount      |      /                         \     /           R           \  *
         * P = principal remaining     |     |  /                 \      |   | ----------------------- | *
         * R = interest rate           | A = | | P * ( 1 + R ) ^ N | - E | * |   /             \       | *
         * N = payments remaining      |     |  \                 /      |   |  | ( 1 + R ) ^ N | - 1  | *
         * E = ending principal target |      \                         /     \  \             /      /  *
         *                             |                                                                 *
         *                             |---------------------------------------------------------------- *
         *                                                                                               *
         * - Where R           is `periodicRate`                                                         *
         * - Where (1 + R) ^ N is `raisedRate`                                                           *
         * - Both of these rates are scaled by 1e18 (e.g., 12% => 0.12 * 10 ** 18)                       *
        \*************************************************************************************************/

        uint256 periodicRate_ = _getPeriodicInterestRate(interestRate_, paymentInterval_);              // 1e18 decimal precision
        uint256 raisedRate_   = _scaledExponent(SCALED_ONE + periodicRate_, totalPayments_, SCALED_ONE); // 1e18 decimal precision

        // NOTE: If a lack of precision in `_scaledExponent` results in a `raisedRate_` smaller than one,
        //       assume it to be one and simplify the equation.
        if (raisedRate_ <= SCALED_ONE) return ((principal_ - endingPrincipal_) / totalPayments_, uint256(0));

        uint256 total_ = ((((principal_ * raisedRate_) / SCALED_ONE) - endingPrincipal_) * periodicRate_) / (raisedRate_ - SCALED_ONE);

        interestAmount_  = _getInterest(principal_, interestRate_, paymentInterval_);
        principalAmount_ = total_ >= interestAmount_ ? total_ - interestAmount_ : uint256(0);
    }

    /// @dev Returns an amount by applying an annualized and scaled interest rate, to a principal, over an interval of time.
    function _getInterest(uint256 principal_, uint256 interestRate_, uint256 interval_) internal pure returns (uint256 interest_) {
        interest_ = (principal_ * _getPeriodicInterestRate(interestRate_, interval_)) / SCALED_ONE;
    }

    function _getLateInterest(
        uint256 currentTime_,
        uint256 principal_,
        uint256 interestRate_,
        uint256 nextPaymentDueDate_,
        uint256 lateFeeRate_,
        uint256 lateInterestPremiumRate_
    )
        internal pure returns (uint256 lateInterest_)
    {
        if (currentTime_ <= nextPaymentDueDate_) return 0;

        // Calculates the number of full days late in seconds (will always be multiples of 86,400).
        // Rounds up and is inclusive so that if a payment is 1s late or 24h0m0s late it is 1 full day late.
        // 24h0m1s late would be two full days late.
        // ((86400n - 0n + (86400n - 1n)) / 86400n) * 86400n = 86400n
        // ((86401n - 0n + (86400n - 1n)) / 86400n) * 86400n = 172800n
        uint256 fullDaysLate_ = ((currentTime_ - nextPaymentDueDate_ + (1 days - 1)) / 1 days) * 1 days;

        lateInterest_ += _getInterest(principal_, interestRate_ + lateInterestPremiumRate_, fullDaysLate_);
        lateInterest_ += (lateFeeRate_ * principal_) / HUNDRED_PERCENT;
    }

    /// @dev Returns total principal and interest portion of a number of payments, given generic, stateless loan parameters and loan state.
    function _getPaymentBreakdown(
        uint256 currentTime_,
        uint256 nextPaymentDueDate_,
        uint256 paymentInterval_,
        uint256 principal_,
        uint256 endingPrincipal_,
        uint256 paymentsRemaining_,
        uint256 interestRate_,
        uint256 lateFeeRate_,
        uint256 lateInterestPremiumRate_
    )
        internal view
        returns (
            uint256           principalAmount_,
            uint256[3] memory interest_,
            uint256[2] memory fees_
        )
    {
        ( principalAmount_, interest_[0] ) = _getInstallment(
            principal_,
            endingPrincipal_,
            interestRate_,
            paymentInterval_,
            paymentsRemaining_
        );

        principalAmount_ = paymentsRemaining_ == uint256(1) ? principal_ : principalAmount_;

        interest_[1] = _getLateInterest(
            currentTime_,
            principal_,
            interestRate_,
            nextPaymentDueDate_,
            lateFeeRate_,
            lateInterestPremiumRate_
        );

        interest_[2] = _refinanceInterest;

        (
            uint256 delegateServiceFee_,
            uint256 delegateRefinanceFee_,
            uint256 platformServiceFee_,
            uint256 platformRefinanceFee_
        ) = IMapleLoanFeeManager(_feeManager).getServiceFeeBreakdown(address(this), 1);

        fees_[0] = delegateServiceFee_ + delegateRefinanceFee_;
        fees_[1] = platformServiceFee_ + platformRefinanceFee_;
    }

    /// @dev Returns the interest rate over an interval, given an annualized interest rate, scaled to 1e18.
    function _getPeriodicInterestRate(uint256 interestRate_, uint256 interval_) internal pure returns (uint256 periodicInterestRate_) {
        periodicInterestRate_ = (interestRate_ * (SCALED_ONE / HUNDRED_PERCENT) * interval_) / uint256(365 days);
    }

    /// @dev Returns refinance commitment given refinance parameters.
    function _getRefinanceCommitment(address refinancer_, uint256 deadline_, bytes[] calldata calls_)
        internal pure returns (bytes32 refinanceCommitment_)
    {
        refinanceCommitment_ = keccak256(abi.encode(refinancer_, deadline_, calls_));
    }

    function _getRefinanceInterest(
        uint256 currentTime_,
        uint256 paymentInterval_,
        uint256 principal_,
        uint256 endingPrincipal_,
        uint256 interestRate_,
        uint256 paymentsRemaining_,
        uint256 nextPaymentDueDate_,
        uint256 lateFeeRate_,
        uint256 lateInterestPremiumRate_
    )
        internal pure returns (uint256 refinanceInterest_)
    {
        // If the user has made an early payment, there is no refinance interest owed.
        if (currentTime_ + paymentInterval_ < nextPaymentDueDate_) return 0;

        uint256 refinanceInterestInterval_ = _min(currentTime_ - (nextPaymentDueDate_ - paymentInterval_), paymentInterval_);

        ( , refinanceInterest_ ) = _getInstallment(
            principal_,
            endingPrincipal_,
            interestRate_,
            refinanceInterestInterval_,
            paymentsRemaining_
        );

        refinanceInterest_ += _getLateInterest(
            currentTime_,
            principal_,
            interestRate_,
            nextPaymentDueDate_,
            lateFeeRate_,
            lateInterestPremiumRate_
        );
    }

    function _handleServiceFeePayment(uint256 numberOfPayments_) internal returns (uint256 fees_) {
        uint256 balanceBeforeServiceFees_ = IERC20(_fundsAsset).balanceOf(address(this));

        IMapleLoanFeeManager(_feeManager).payServiceFees(_fundsAsset, numberOfPayments_);

        uint256 balanceAfterServiceFees_ = IERC20(_fundsAsset).balanceOf(address(this));

        if (balanceBeforeServiceFees_ > balanceAfterServiceFees_) {
            _drawableFunds -= (fees_ = balanceBeforeServiceFees_ - balanceAfterServiceFees_);
        } else {
            _drawableFunds += balanceAfterServiceFees_ - balanceBeforeServiceFees_;
        }
    }

    /// @dev Returns whether the amount of collateral posted is commensurate with the amount of drawn down (outstanding) principal.
    function _isCollateralMaintained() internal view returns (bool isMaintained_) {
        isMaintained_ = _collateral >= _getCollateralRequiredFor(_principal, _drawableFunds, _principalRequested, _collateralRequired);
    }

    function _min(uint256 a_, uint256 b_) internal pure returns (uint256 minimum_) {
        minimum_ = a_ < b_ ? a_ : b_;
    }

    function _revertIfNotBorrower() internal view {
        require(msg.sender == _borrower, "ML:NOT_BORROWER");
    }

    function _revertIfNotLender() internal view {
        require(msg.sender == _lender, "ML:NOT_LENDER");
    }

    function _revertIfPaused() internal view {
        require(!IGlobalsLike(globals()).isFunctionPaused(msg.sig), "L:PAUSED");
    }

    /**
     *  @dev Returns exponentiation of a scaled base value.
     *
     *       Walk through example:
     *       LINE  |  base_          |  exponent_  |  one_  |  result_
     *             |  3_00           |  18         |  1_00  |  0_00
     *        A    |  3_00           |  18         |  1_00  |  1_00
     *        B    |  3_00           |  9          |  1_00  |  1_00
     *        C    |  9_00           |  9          |  1_00  |  1_00
     *        D    |  9_00           |  9          |  1_00  |  9_00
     *        B    |  9_00           |  4          |  1_00  |  9_00
     *        C    |  81_00          |  4          |  1_00  |  9_00
     *        B    |  81_00          |  2          |  1_00  |  9_00
     *        C    |  6_561_00       |  2          |  1_00  |  9_00
     *        B    |  6_561_00       |  1          |  1_00  |  9_00
     *        C    |  43_046_721_00  |  1          |  1_00  |  9_00
     *        D    |  43_046_721_00  |  1          |  1_00  |  387_420_489_00
     *        B    |  43_046_721_00  |  0          |  1_00  |  387_420_489_00
     *
     * Another implementation of this algorithm can be found in Dapphub's DSMath contract:
     * https://github.com/dapphub/ds-math/blob/ce67c0fa9f8262ecd3d76b9e4c026cda6045e96c/src/math.sol#L77
     */
    function _scaledExponent(uint256 base_, uint256 exponent_, uint256 one_) internal pure returns (uint256 result_) {
        // If exponent_ is odd, set result_ to base_, else set to one_.
        result_ = exponent_ & uint256(1) != uint256(0) ? base_ : one_;          // A

        // Divide exponent_ by 2 (overwriting itself) and proceed if not zero.
        while ((exponent_ >>= uint256(1)) != uint256(0)) {                      // B
            base_ = (base_ * base_) / one_;                                     // C

            // If exponent_ is even, go back to top.
            if (exponent_ & uint256(1) == uint256(0)) continue;

            // If exponent_ is odd, multiply result_ is multiplied by base_.
            result_ = (result_ * base_) / one_;                                 // D
        }
    }

}
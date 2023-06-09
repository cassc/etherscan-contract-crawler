// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.7;

import { IERC20 }                from "../modules/erc20/contracts/interfaces/IERC20.sol";
import { ERC20Helper }           from "../modules/erc20-helper/src/ERC20Helper.sol";
import { IMapleProxyFactory }    from "../modules/maple-proxy-factory/contracts/interfaces/IMapleProxyFactory.sol";
import { MapleProxiedInternals } from "../modules/maple-proxy-factory/contracts/MapleProxiedInternals.sol";

import { IMapleLoan } from "./interfaces/IMapleLoan.sol";

import { IGlobalsLike, ILenderLike, IMapleProxyFactoryLike } from "./interfaces/Interfaces.sol";

import { MapleLoanStorage } from "./MapleLoanStorage.sol";

/*

    ███╗   ███╗ █████╗ ██████╗ ██╗     ███████╗
    ████╗ ████║██╔══██╗██╔══██╗██║     ██╔════╝
    ██╔████╔██║███████║██████╔╝██║     █████╗
    ██║╚██╔╝██║██╔══██║██╔═══╝ ██║     ██╔══╝
    ██║ ╚═╝ ██║██║  ██║██║     ███████╗███████╗
    ╚═╝     ╚═╝╚═╝  ╚═╝╚═╝     ╚══════╝╚══════╝

     ██████╗ ██████╗ ███████╗███╗   ██╗    ████████╗███████╗██████╗ ███╗   ███╗    ██╗      ██████╗  █████╗ ███╗   ██╗    ██╗   ██╗ ██╗
    ██╔═══██╗██╔══██╗██╔════╝████╗  ██║    ╚══██╔══╝██╔════╝██╔══██╗████╗ ████║    ██║     ██╔═══██╗██╔══██╗████╗  ██║    ██║   ██║███║
    ██║   ██║██████╔╝█████╗  ██╔██╗ ██║       ██║   █████╗  ██████╔╝██╔████╔██║    ██║     ██║   ██║███████║██╔██╗ ██║    ██║   ██║╚██║
    ██║   ██║██╔═══╝ ██╔══╝  ██║╚██╗██║       ██║   ██╔══╝  ██╔══██╗██║╚██╔╝██║    ██║     ██║   ██║██╔══██║██║╚██╗██║    ╚██╗ ██╔╝ ██║
    ╚██████╔╝██║     ███████╗██║ ╚████║       ██║   ███████╗██║  ██║██║ ╚═╝ ██║    ███████╗╚██████╔╝██║  ██║██║ ╚████║     ╚████╔╝  ██║
     ╚═════╝ ╚═╝     ╚══════╝╚═╝  ╚═══╝       ╚═╝   ╚══════╝╚═╝  ╚═╝╚═╝     ╚═╝    ╚══════╝ ╚═════╝ ╚═╝  ╚═╝╚═╝  ╚═══╝      ╚═══╝   ╚═╝

*/

/// @title MapleLoan implements an open term loan, and is intended to be proxied.
contract MapleLoan is IMapleLoan, MapleProxiedInternals, MapleLoanStorage {

    uint256 public constant override HUNDRED_PERCENT = 1e6;

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
        require(msg.sender == pendingBorrower, "ML:AB:NOT_PENDING_BORROWER");

        delete pendingBorrower;

        emit BorrowerAccepted(borrower = msg.sender);
    }

    function acceptNewTerms(address refinancer_, uint256 deadline_, bytes[] calldata calls_)
        external override whenNotPaused onlyBorrower returns (bytes32 refinanceCommitment_)
    {
        require(refinancer_.code.length != uint256(0), "ML:ANT:INVALID_REFINANCER");
        require(block.timestamp <= deadline_,          "ML:ANT:EXPIRED_COMMITMENT");

        // NOTE: A zero refinancer address and/or empty calls array will never (probabilistically) match a refinance commitment in storage.
        require(
            refinanceCommitment == (refinanceCommitment_ = _getRefinanceCommitment(refinancer_, deadline_, calls_)),
            "ML:ANT:COMMITMENT_MISMATCH"
        );

        uint256 previousPrincipal_ = principal;

        (
            ,
            uint256 interest_,
            uint256 lateInterest_,
            uint256 delegateServiceFee_,
            uint256 platformServiceFee_
        ) = getPaymentBreakdown(block.timestamp);

        // Clear refinance commitment to prevent implications of re-acceptance of another call to `_acceptNewTerms`.
        delete refinanceCommitment;

        for (uint256 i_; i_ < calls_.length; ++i_) {
            ( bool success_, ) = refinancer_.delegatecall(calls_[i_]);
            require(success_, "ML:ANT:FAILED");
        }

        // TODO: Emit this before the refinance calls in order to adhere to the CEI pattern.
        emit NewTermsAccepted(refinanceCommitment_, refinancer_, deadline_, calls_);

        address fundsAsset_   = fundsAsset;
        uint256 newPrincipal_ = principal;

        int256 netPrincipalToReturnToLender_ = _int256(previousPrincipal_) - _int256(newPrincipal_);

        uint256 interestAndFees_ = interest_ + lateInterest_ + delegateServiceFee_ + platformServiceFee_;

        address borrower_ = borrower;

        ILenderLike lender_ = ILenderLike(lender);

        require(
            ERC20Helper.transferFrom(
                fundsAsset_,
                borrower_,
                address(lender_),
                (netPrincipalToReturnToLender_ > 0 ? _uint256(netPrincipalToReturnToLender_) : 0) + interestAndFees_
            ),
            "ML:ANT:TRANSFER_FAILED"
        );

        platformServiceFeeRate = uint64(IGlobalsLike(globals()).platformServiceFeeRate(lender_.poolManager()));

        if (newPrincipal_ == 0) {
            // NOTE: All the principal has been paid back therefore clear the loan accounting.
            _clearLoanAccounting();
        } else {
            datePaid = _uint40(block.timestamp);

            // NOTE: Accepting new terms always results in the a call and/or impairment being removed.
            delete calledPrincipal;
            delete dateCalled;
            delete dateImpaired;
        }

        lender_.claim(
            netPrincipalToReturnToLender_,
            interest_ + lateInterest_,
            delegateServiceFee_,
            platformServiceFee_,
            paymentDueDate()
        );

        // Principal has increased in the Loan, so Loan pulls funds from Lender.
        if (netPrincipalToReturnToLender_ < 0) {
            require(
                ERC20Helper.transferFrom(fundsAsset_, address(lender_), borrower_, _uint256(netPrincipalToReturnToLender_ * -1)),
                "ML:ANT:TRANSFER_FAILED"
            );
        }
    }

    function makePayment(uint256 principalToReturn_)
        external override whenNotPaused
        returns (
            uint256 interest_,
            uint256 lateInterest_,
            uint256 delegateServiceFee_,
            uint256 platformServiceFee_
        )
    {
        require(dateFunded != 0, "ML:MP:LOAN_INACTIVE");

        uint256 calledPrincipal_;

        ( calledPrincipal_, interest_, lateInterest_, delegateServiceFee_, platformServiceFee_ ) = getPaymentBreakdown(block.timestamp);

        // If the loan is called, the principal being returned must be greater than the portion called.
        require(principalToReturn_ <= principal,        "ML:MP:RETURNING_TOO_MUCH");
        require(principalToReturn_ >= calledPrincipal_, "ML:MP:INSUFFICIENT_FOR_CALL");

        uint256 total_ = principalToReturn_ + interest_ + lateInterest_ + delegateServiceFee_ + platformServiceFee_;

        if (principalToReturn_ == principal) {
            _clearLoanAccounting();
            emit PrincipalReturned(principalToReturn_, 0);
        } else {
            datePaid = _uint40(block.timestamp);

            // NOTE: Making a payment always results in the a call and/or impairment being removed.
            delete calledPrincipal;
            delete dateCalled;
            delete dateImpaired;

            if (principalToReturn_ != 0) {
                emit PrincipalReturned(principalToReturn_, principal -= principalToReturn_);
            }
        }

        address lender_         = lender;
        uint40  paymentDueDate_ = paymentDueDate();

        emit PaymentMade(
            lender_,
            principalToReturn_,
            interest_,
            lateInterest_,
            delegateServiceFee_,
            platformServiceFee_,
            paymentDueDate_,
            defaultDate()
        );

        require(ERC20Helper.transferFrom(fundsAsset, msg.sender, lender_, total_), "ML:MP:TRANSFER_FROM_FAILED");

        ILenderLike(lender_).claim(
            _int256(principalToReturn_),
            interest_ + lateInterest_,
            delegateServiceFee_,
            platformServiceFee_,
            paymentDueDate_
        );
    }

    function setPendingBorrower(address pendingBorrower_) external override whenNotPaused onlyBorrower {
        require(IGlobalsLike(globals()).isBorrower(pendingBorrower_), "ML:SPB:INVALID_BORROWER");

        emit PendingBorrowerSet(pendingBorrower = pendingBorrower_);
    }

    /**************************************************************************************************************************************/
    /*** Lend Functions                                                                                                                 ***/
    /**************************************************************************************************************************************/

    function acceptLender() external override whenNotPaused {
        require(msg.sender == pendingLender, "ML:AL:NOT_PENDING_LENDER");

        delete pendingLender;

        emit LenderAccepted(lender = msg.sender);
    }

    function callPrincipal(uint256 principalToReturn_)
        external override whenNotPaused onlyLender
        returns (uint40 paymentDueDate_, uint40 defaultDate_)
    {
        require(dateFunded != 0,                                            "ML:C:LOAN_INACTIVE");
        require(principalToReturn_ != 0 && principalToReturn_ <= principal, "ML:C:INVALID_AMOUNT");

        dateCalled = _uint40(block.timestamp);

        emit PrincipalCalled(
            calledPrincipal = principalToReturn_,
            paymentDueDate_ = paymentDueDate(),
            defaultDate_    = defaultDate()
        );
    }

    function fund() external override whenNotPaused onlyLender returns (uint256 fundsLent_, uint40 paymentDueDate_, uint40 defaultDate_) {
        require(dateFunded == 0, "ML:F:LOAN_ACTIVE");
        require(principal != 0,  "ML:F:LOAN_CLOSED");

        dateFunded = _uint40(block.timestamp);

        emit Funded(
            fundsLent_      = principal,
            paymentDueDate_ = paymentDueDate(),
            defaultDate_    = defaultDate()
        );

        require(ERC20Helper.transferFrom(fundsAsset, msg.sender, borrower, fundsLent_), "ML:F:TRANSFER_FROM_FAILED");
    }

    function impair() external override whenNotPaused onlyLender returns (uint40 paymentDueDate_, uint40 defaultDate_) {
        require(dateFunded != 0, "ML:I:LOAN_INACTIVE");

        // NOTE: Impairing an already-impaired loan simply updates the `dateImpaired`, which can push the due date further.
        dateImpaired = _uint40(block.timestamp);

        emit Impaired(
            paymentDueDate_ = paymentDueDate(),
            defaultDate_    = defaultDate()
        );
    }

    function proposeNewTerms(address refinancer_, uint256 deadline_, bytes[] calldata calls_)
        external override whenNotPaused onlyLender returns (bytes32 refinanceCommitment_)
    {
        require(dateFunded != 0,                                                    "ML:PNT:LOAN_INACTIVE");
        require(block.timestamp <= deadline_,                                       "ML:PNT:INVALID_DEADLINE");
        require(IGlobalsLike(globals()).isInstanceOf("OT_REFINANCER", refinancer_), "ML:PNT:INVALID_REFINANCER");
        require(calls_.length > 0,                                                  "ML:PNT:EMPTY_CALLS");

        emit NewTermsProposed(
            refinanceCommitment = refinanceCommitment_ = _getRefinanceCommitment(refinancer_, deadline_, calls_),
            refinancer_,
            deadline_,
            calls_
        );
    }

    function removeCall() external override whenNotPaused onlyLender returns (uint40 paymentDueDate_, uint40 defaultDate_) {
        require(dateCalled != 0, "ML:RC:NOT_CALLED");

        delete dateCalled;
        delete calledPrincipal;

        emit CallRemoved(
            paymentDueDate_ = paymentDueDate(),
            defaultDate_    = defaultDate()
        );
    }

    function removeImpairment() external override whenNotPaused onlyLender returns (uint40 paymentDueDate_, uint40 defaultDate_) {
        require(dateImpaired != 0, "ML:RI:NOT_IMPAIRED");

        delete dateImpaired;

        emit ImpairmentRemoved(
            paymentDueDate_ = paymentDueDate(),
            defaultDate_    = defaultDate()
        );
    }

    function repossess(address destination_) external override whenNotPaused onlyLender returns (uint256 fundsRepossessed_) {
        require(isInDefault(), "ML:R:NOT_IN_DEFAULT");

        _clearLoanAccounting();

        address fundsAsset_ = fundsAsset;

        emit Repossessed(
            fundsRepossessed_ = IERC20(fundsAsset_).balanceOf(address(this)),
            destination_
        );

        // Either there are no funds to repossess, or the transfer of the funds succeeds.
        require((fundsRepossessed_ == 0) || ERC20Helper.transfer(fundsAsset_, destination_, fundsRepossessed_), "ML:R:TRANSFER_FAILED");
    }

    function setPendingLender(address pendingLender_) external override whenNotPaused onlyLender {
        emit PendingLenderSet(pendingLender = pendingLender_);
    }

    /**************************************************************************************************************************************/
    /*** Miscellaneous Functions                                                                                                        ***/
    /**************************************************************************************************************************************/

    function rejectNewTerms(address refinancer_, uint256 deadline_, bytes[] calldata calls_)
        external override whenNotPaused returns (bytes32 refinanceCommitment_)
    {
        require((msg.sender == borrower) || (msg.sender == lender), "ML:RNT:NO_AUTH");

        require(
            refinanceCommitment == (refinanceCommitment_ = _getRefinanceCommitment(refinancer_, deadline_, calls_)),
            "ML:RNT:COMMITMENT_MISMATCH"
        );

        delete refinanceCommitment;

        emit NewTermsRejected(refinanceCommitment_, refinancer_, deadline_, calls_);
    }

    function skim(address token_, address destination_) external override whenNotPaused returns (uint256 skimmed_) {
        require(destination_ != address(0), "ML:S:ZERO_ADDRESS");

        address governor_ = IGlobalsLike(globals()).governor();

        require(msg.sender == governor_ || msg.sender == borrower, "ML:S:NO_AUTH");

        skimmed_ = IERC20(token_).balanceOf(address(this));

        require(skimmed_ != 0, "ML:S:NO_TOKEN_TO_SKIM");

        emit Skimmed(token_, skimmed_, destination_);

        require(ERC20Helper.transfer(token_, destination_, skimmed_), "ML:S:TRANSFER_FAILED");
    }

    /**************************************************************************************************************************************/
    /*** View Functions                                                                                                                 ***/
    /**************************************************************************************************************************************/

    function defaultDate() public view override returns (uint40 paymentDefaultDate_) {
        ( uint40 callDefaultDate_, uint40 impairedDefaultDate_, uint40 normalPaymentDueDate_ ) = _defaultDates();

        paymentDefaultDate_ = _minDate(callDefaultDate_, impairedDefaultDate_, normalPaymentDueDate_);
    }

    function factory() external view override returns (address factory_) {
        return _factory();
    }

    function getPaymentBreakdown(uint256 timestamp_)
        public view override returns (
            uint256 principal_,
            uint256 interest_,
            uint256 lateInterest_,
            uint256 delegateServiceFee_,
            uint256 platformServiceFee_
        )
    {
        uint40 startDate_ = _maxDate(datePaid, dateFunded);  // Timestamp when new interest starts accruing.

        // Return all zeros if the loan has not been funded yet or if the given timestamp is not greater than the start date.
        if (startDate_ == 0 || timestamp_ <= startDate_) return ( calledPrincipal, 0, 0, 0, 0 );

        uint40 paymentDueDate_ = paymentDueDate();

        // "Current" interval and late interval respectively.
        ( uint32 interval_, uint32 lateInterval_ ) =
            ( _uint32(timestamp_ - startDate_), timestamp_ > paymentDueDate_ ? _uint32(timestamp_ - paymentDueDate_) : 0 );

        ( interest_, lateInterest_, delegateServiceFee_, platformServiceFee_ ) = _getPaymentBreakdown(
            principal,
            interestRate,
            lateInterestPremiumRate,
            lateFeeRate,
            delegateServiceFeeRate,
            platformServiceFeeRate,
            interval_,
            lateInterval_
        );

        principal_ = calledPrincipal;
    }

    function globals() public view override returns (address globals_) {
        globals_ = IMapleProxyFactoryLike(_factory()).mapleGlobals();
    }

    function implementation() external view override returns (address implementation_) {
        return _implementation();
    }

    function isCalled() public view override returns (bool isCalled_) {
        isCalled_ = dateCalled != 0;
    }

    function isImpaired() public view override returns (bool isImpaired_) {
        isImpaired_ = dateImpaired != 0;
    }

    function isInDefault() public view override returns (bool isInDefault_) {
        uint40 defaultDate_ = defaultDate();

        isInDefault_ = (defaultDate_ != 0) && (block.timestamp > defaultDate_);
    }

    function paymentDueDate() public view override returns (uint40 paymentDueDate_) {
        ( uint40 callDueDate_, uint40 impairedDueDate_, uint40 normalDueDate_ ) = _dueDates();

        paymentDueDate_ = _minDate(callDueDate_, impairedDueDate_, normalDueDate_);
    }

    /**************************************************************************************************************************************/
    /*** Internal Helper Functions                                                                                                      ***/
    /**************************************************************************************************************************************/

    /// @dev Clears all state variables to end a loan, but keep borrower and lender withdrawal functionality intact.
    function _clearLoanAccounting() internal {
        delete refinanceCommitment;

        delete gracePeriod;
        delete noticePeriod;
        delete paymentInterval;

        delete dateCalled;
        delete dateFunded;
        delete dateImpaired;
        delete datePaid;

        delete calledPrincipal;
        delete principal;

        delete delegateServiceFeeRate;
        delete interestRate;
        delete lateFeeRate;
        delete lateInterestPremiumRate;
        delete platformServiceFeeRate;
    }

    /**************************************************************************************************************************************/
    /*** Internal View Functions                                                                                                        ***/
    /**************************************************************************************************************************************/

    function _defaultDates() internal view returns (uint40 callDefaultDate_, uint40 impairedDefaultDate_, uint40 normalDefaultDate_) {
        ( uint40 callDueDate_, uint40 impairedDueDate_, uint40 normalDueDate_ ) = _dueDates();

        callDefaultDate_     = _getCallDefaultDate(callDueDate_);
        impairedDefaultDate_ = _getImpairedDefaultDate(impairedDueDate_, gracePeriod);
        normalDefaultDate_   = _getNormalDefaultDate(normalDueDate_, gracePeriod);
    }

    function _dueDates() internal view returns (uint40 callDueDate_, uint40 impairedDueDate_, uint40 normalDueDate_) {
        callDueDate_     = _getCallDueDate(dateCalled, noticePeriod);
        impairedDueDate_ = _getImpairedDueDate(dateImpaired);
        normalDueDate_   = _getNormalDueDate(dateFunded, datePaid, paymentInterval);
    }

    function _getRefinanceCommitment(address refinancer_, uint256 deadline_, bytes[] calldata calls_)
        internal pure returns (bytes32 refinanceCommitment_)
    {
        return keccak256(abi.encode(refinancer_, deadline_, calls_));
    }

    function _revertIfNotBorrower() internal view {
        require(msg.sender == borrower, "ML:NOT_BORROWER");
    }

    function _revertIfNotLender() internal view {
        require(msg.sender == lender, "ML:NOT_LENDER");
    }

    function _revertIfPaused() internal view {
        require(!IGlobalsLike(globals()).isFunctionPaused(msg.sig), "ML:PAUSED");
    }

    /**************************************************************************************************************************************/
    /*** Internal Pure Functions                                                                                                        ***/
    /**************************************************************************************************************************************/

    function _getCallDefaultDate(uint40 callDueDate_) internal pure returns (uint40 defaultDate_) {
        defaultDate_ = callDueDate_;
    }

    function _getCallDueDate(uint40 dateCalled_, uint32 noticePeriod_) internal pure returns (uint40 dueDate_) {
        dueDate_ = dateCalled_ != 0 ? dateCalled_ + noticePeriod_ : 0;
    }

    function _getImpairedDefaultDate(uint40 impairedDueDate_, uint32 gracePeriod_) internal pure returns (uint40 defaultDate_) {
        defaultDate_ = impairedDueDate_ != 0 ? impairedDueDate_ + gracePeriod_ : 0;
    }

    function _getImpairedDueDate(uint40 dateImpaired_) internal pure returns (uint40 dueDate_) {
        dueDate_ = dateImpaired_ != 0 ? dateImpaired_: 0;
    }

    function _getNormalDefaultDate(uint40 normalDueDate_, uint32 gracePeriod_) internal pure returns (uint40 defaultDate_) {
        defaultDate_ = normalDueDate_ != 0 ? normalDueDate_ + gracePeriod_ : 0;
    }

    function _getNormalDueDate(uint40 dateFunded_, uint40 datePaid_, uint32 paymentInterval_) internal pure returns (uint40 dueDate_) {
        uint40 paidOrFundedDate_ = _maxDate(dateFunded_, datePaid_);

        dueDate_ = paidOrFundedDate_ != 0 ? paidOrFundedDate_ + paymentInterval_ : 0;
    }

    /// @dev Returns an amount by applying an annualized and scaled interest rate, to a principal, over an interval of time.
    function _getPaymentBreakdown(
        uint256 principal_,
        uint256 interestRate_,
        uint256 lateInterestPremiumRate_,
        uint256 lateFeeRate_,
        uint256 delegateServiceFeeRate_,
        uint256 platformServiceFeeRate_,
        uint32  interval_,
        uint32  lateInterval_
    )
        internal pure returns (uint256 interest_, uint256 lateInterest_, uint256 delegateServiceFee_, uint256 platformServiceFee_)
    {
        interest_           = _getProRatedAmount(principal_, interestRate_,           interval_);
        delegateServiceFee_ = _getProRatedAmount(principal_, delegateServiceFeeRate_, interval_);
        platformServiceFee_ = _getProRatedAmount(principal_, platformServiceFeeRate_, interval_);

        if (lateInterval_ == 0) return (interest_, 0, delegateServiceFee_, platformServiceFee_);

        lateInterest_ =
            _getProRatedAmount(principal_, lateInterestPremiumRate_, lateInterval_) +
            ((principal_ * lateFeeRate_) / HUNDRED_PERCENT);
    }

    function _getProRatedAmount(uint256 amount_, uint256 rate_, uint32 interval_) internal pure returns (uint256 proRatedAmount_) {
        proRatedAmount_ = (amount_ * rate_ * interval_) / (365 days * HUNDRED_PERCENT);
    }

    function _int256(uint256 input_) internal pure returns (int256 output_) {
        require(input_ <= uint256(type(int256).max), "ML:UINT256_CAST");
        output_ = int256(input_);
    }

    function _maxDate(uint40 a_, uint40 b_) internal pure returns (uint40 max_) {
        max_ = a_ == 0 ? b_ : (b_ == 0 ? a_ : (a_ > b_ ? a_ : b_));
    }

    function _minDate(uint40 a_, uint40 b_) internal pure returns (uint40 min_) {
        min_ = a_ == 0 ? b_ : (b_ == 0 ? a_ : (a_ < b_ ? a_ : b_));
    }

    function _minDate(uint40 a_, uint40 b_, uint40 c_) internal pure returns (uint40 min_) {
        min_ = _minDate(a_, _minDate(b_, c_));
    }

    function _uint32(uint256 input_) internal pure returns (uint32 output_) {
        require(input_ <= type(uint32).max, "ML:UINT256_OOB_FOR_UINT32");
        output_ = uint32(input_);
    }

    function _uint40(uint256 input_) internal pure returns (uint40 output_) {
        require(input_ <= type(uint40).max, "ML:UINT256_OOB_FOR_UINT40");
        output_ = uint40(input_);
    }

    function _uint256(int256 input_) internal pure returns (uint256 output_) {
        require(input_ >= 0, "ML:INT256_CAST");
        output_ = uint256(input_);
    }

}
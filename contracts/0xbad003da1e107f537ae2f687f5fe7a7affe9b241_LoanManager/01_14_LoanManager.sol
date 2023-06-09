// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.7;

import { ERC20Helper }           from "../modules/erc20-helper/src/ERC20Helper.sol";
import { IMapleProxyFactory }    from "../modules/maple-proxy-factory/contracts/interfaces/IMapleProxyFactory.sol";
import { MapleProxiedInternals } from "../modules/maple-proxy-factory/contracts/MapleProxiedInternals.sol";

import { ILoanManager }                                                from "./interfaces/ILoanManager.sol";
import { IGlobalsLike, ILoanFactoryLike, ILoanLike, IPoolManagerLike } from "./interfaces/Interfaces.sol";

import { LoanManagerStorage } from "./LoanManagerStorage.sol";

/*

    ██╗      ██████╗  █████╗ ███╗   ██╗    ███╗   ███╗ █████╗ ███╗   ██╗ █████╗  ██████╗ ███████╗██████╗
    ██║     ██╔═══██╗██╔══██╗████╗  ██║    ████╗ ████║██╔══██╗████╗  ██║██╔══██╗██╔════╝ ██╔════╝██╔══██╗
    ██║     ██║   ██║███████║██╔██╗ ██║    ██╔████╔██║███████║██╔██╗ ██║███████║██║  ███╗█████╗  ██████╔╝
    ██║     ██║   ██║██╔══██║██║╚██╗██║    ██║╚██╔╝██║██╔══██║██║╚██╗██║██╔══██║██║   ██║██╔══╝  ██╔══██╗
    ███████╗╚██████╔╝██║  ██║██║ ╚████║    ██║ ╚═╝ ██║██║  ██║██║ ╚████║██║  ██║╚██████╔╝███████╗██║  ██║
    ╚══════╝ ╚═════╝ ╚═╝  ╚═╝╚═╝  ╚═══╝    ╚═╝     ╚═╝╚═╝  ╚═╝╚═╝  ╚═══╝╚═╝  ╚═╝ ╚═════╝ ╚══════╝╚═╝  ╚═╝

*/

contract LoanManager is ILoanManager, MapleProxiedInternals, LoanManagerStorage {

    uint256 public override constant HUNDRED_PERCENT = 1e6;   // 100.0000%
    uint256 public override constant PRECISION       = 1e27;

    /**************************************************************************************************************************************/
    /*** Modifiers                                                                                                                      ***/
    /**************************************************************************************************************************************/

    modifier isLoan(address loan_) {
        _revertIfNotLoan(loan_);
        _;
    }

    modifier nonReentrant() {
        require(_locked == 1, "LM:LOCKED");

        _locked = 2;

        _;

        _locked = 1;
    }

    modifier onlyPoolDelegate() {
        _revertIfNotPoolDelegate();
        _;
    }

    modifier whenNotPaused() {
        _revertIfPaused();
        _;
    }

    /**************************************************************************************************************************************/
    /*** Upgradeability Functions                                                                                                       ***/
    /**************************************************************************************************************************************/

    function migrate(address migrator_, bytes calldata arguments_) external override whenNotPaused {
        require(msg.sender == _factory(),        "LM:M:NOT_FACTORY");
        require(_migrate(migrator_, arguments_), "LM:M:FAILED");
    }

    function setImplementation(address implementation_) external override whenNotPaused {
        require(msg.sender == _factory(), "LM:SI:NOT_FACTORY");

        _setImplementation(implementation_);
    }

    function upgrade(uint256 version_, bytes calldata arguments_) external override whenNotPaused {
        IGlobalsLike globals_ = IGlobalsLike(_globals());

        if (msg.sender == _poolDelegate()) {
            require(globals_.isValidScheduledCall(msg.sender, address(this), "LM:UPGRADE", msg.data), "LM:U:INVALID_SCHED_CALL");

            globals_.unscheduleCall(msg.sender, "LM:UPGRADE", msg.data);
        } else {
            require(msg.sender == globals_.securityAdmin(), "LM:U:NO_AUTH");
        }

        emit Upgraded(version_, arguments_);

        IMapleProxyFactory(_factory()).upgradeInstance(version_, arguments_);
    }

    /**************************************************************************************************************************************/
    /*** Loan Funding and Refinancing Functions                                                                                         ***/
    /**************************************************************************************************************************************/

    function fund(address loan_) external override whenNotPaused nonReentrant onlyPoolDelegate {
        address      factory_ = ILoanLike(loan_).factory();
        IGlobalsLike globals_ = IGlobalsLike(_globals());

        require(globals_.isInstanceOf("OT_LOAN_FACTORY", factory_),    "LM:F:INVALID_LOAN_FACTORY");
        require(ILoanFactoryLike(factory_).isLoan(loan_),              "LM:F:INVALID_LOAN_INSTANCE");
        require(globals_.isBorrower(ILoanLike(loan_).borrower()), "LM:F:INVALID_BORROWER");

        uint256 principal_ = ILoanLike(loan_).principal();

        require(principal_ != 0, "LM:F:LOAN_NOT_ACTIVE");

        _prepareFundsForLoan(loan_, principal_);

        ( uint256 fundsLent_, , ) = ILoanLike(loan_).fund();

        require(fundsLent_ == principal_, "LM:F:FUNDING_MISMATCH");

        _updatePrincipalOut(_int256(fundsLent_));

        Payment memory payment_ = _addPayment(loan_);

        _updateInterestAccounting(0, _int256(payment_.issuanceRate));
    }

    function proposeNewTerms(address loan_, address refinancer_, uint256 deadline_, bytes[] calldata calls_)
        external override whenNotPaused onlyPoolDelegate isLoan(loan_)
    {
        ILoanLike(loan_).proposeNewTerms(refinancer_, deadline_, calls_);
    }

    function rejectNewTerms(address loan_, address refinancer_, uint256 deadline_, bytes[] calldata calls_)
        external override whenNotPaused onlyPoolDelegate isLoan(loan_)
    {
        ILoanLike(loan_).rejectNewTerms(refinancer_, deadline_, calls_);
    }

    /**************************************************************************************************************************************/
    /*** Loan Payment Claim Function                                                                                                    ***/
    /**************************************************************************************************************************************/

    function claim(
        int256  principal_,
        uint256 interest_,
        uint256 delegateServiceFee_,
        uint256 platformServiceFee_,
        uint40  nextPaymentDueDate_
    )
        external override whenNotPaused isLoan(msg.sender) nonReentrant
    {
        uint256 principalRemaining_ = ILoanLike(msg.sender).principal();

        // Either a next payment and remaining principal exists, or neither exist and principal is returned.
        require(
            (nextPaymentDueDate_ > 0 && principalRemaining_ > 0) ||                          // First given it's most likely.
            ((nextPaymentDueDate_ == 0) && (principalRemaining_ == 0) && (principal_ > 0)),
            "LM:C:INVALID"
        );

        // Calculate the original principal to correctly account for removing `unrealizedLosses` when removing the impairment.
        uint256 originalPrincipal_ = uint256(_int256(principalRemaining_) + principal_);

        _accountForLoanImpairmentRemoval(msg.sender, originalPrincipal_);

        // Transfer the funds from the loan to the `pool`, `poolDelegate`, and `mapleTreasury`.
        _distributeClaimedFunds(msg.sender, principal_, interest_, delegateServiceFee_, platformServiceFee_);

        // If principal is changing, update `principalOut`.
        // If principal is positive, it is being repaid, so `principalOut` is decremented.
        // If principal is negative, it is being taken from the Pool, so `principalOut` is incremented.
        if (principal_ != 0) {
            _updatePrincipalOut(-principal_);
        }

        // Remove the payment and cache the struct.
        Payment memory claimedPayment_ = _removePayment(msg.sender);

        int256 accountedInterestAdjustment_
            = -_int256(_getIssuance(claimedPayment_.issuanceRate, block.timestamp - claimedPayment_.startDate));

        // If no new payment to track, update accounting and account for discrepancies in paid interest vs accrued interest since the
        // payment's start date, and exit.
        if (nextPaymentDueDate_ == 0) {
            return _updateInterestAccounting(accountedInterestAdjustment_, -_int256(claimedPayment_.issuanceRate));
        }

        if (principal_ < 0) {
            address borrower_ = ILoanLike(msg.sender).borrower();

            require(IGlobalsLike(_globals()).isBorrower(borrower_), "LM:C:INVALID_BORROWER");

            _prepareFundsForLoan(msg.sender, _uint256(-principal_));
        }

        // Track the new payment.
        Payment memory nextPayment_ = _addPayment(msg.sender);

        // Update accounting and account for discrepancies in paid interest vs accrued interest since the payment's start date, and exit.
        _updateInterestAccounting(accountedInterestAdjustment_, _int256(nextPayment_.issuanceRate) - _int256(claimedPayment_.issuanceRate));
    }

    /**************************************************************************************************************************************/
    /*** Loan Call Functions                                                                                                            ***/
    /**************************************************************************************************************************************/

    function callPrincipal(address loan_, uint256 principal_) external override whenNotPaused onlyPoolDelegate isLoan(loan_) {
        ILoanLike(loan_).callPrincipal(principal_);
    }

    function removeCall(address loan_) external override whenNotPaused onlyPoolDelegate isLoan(loan_) {
        ILoanLike(loan_).removeCall();
    }

    /**************************************************************************************************************************************/
    /*** Loan Impairment Functions                                                                                                      ***/
    /**************************************************************************************************************************************/

    function impairLoan(address loan_) external override whenNotPaused isLoan(loan_) {
        bool isGovernor_ = msg.sender == _governor();

        require(isGovernor_ || msg.sender == _poolDelegate(), "LM:IL:NO_AUTH");

        ILoanLike(loan_).impair();

        if (isGovernor_) {
            _accountForLoanImpairmentAsGovernor(loan_);
        } else {
            _accountForLoanImpairment(loan_);
        }
    }

    function removeLoanImpairment(address loan_) external override whenNotPaused isLoan(loan_) {
        ( , bool impairedByGovernor_ ) = _accountForLoanImpairmentRemoval(loan_, ILoanLike(loan_).principal());

        require(msg.sender == _governor() || (!impairedByGovernor_ && msg.sender == _poolDelegate()), "LM:RLI:NO_AUTH");

        ILoanLike(loan_).removeImpairment();
    }

    /**************************************************************************************************************************************/
    /*** Loan Default Functions                                                                                                         ***/
    /**************************************************************************************************************************************/

    function triggerDefault(address loan_, address liquidatorFactory_)
        external override returns (bool liquidationComplete_, uint256 remainingLosses_, uint256 unrecoveredPlatformFees_)
    {
        liquidatorFactory_;  // Silence compiler warning.

        ( remainingLosses_, unrecoveredPlatformFees_ ) = triggerDefault(loan_);

        liquidationComplete_ = true;
    }

    function triggerDefault(address loan_)
        public override whenNotPaused isLoan(loan_) returns (uint256 remainingLosses_, uint256 unrecoveredPlatformFees_)
    {
        require(msg.sender == poolManager, "LM:TD:NOT_PM");

        // Note: Always impair before proceeding, this ensures a consistent approach to reduce the `accountedInterest` for the Loan.
        //       If the Loan is already impaired, this will be a no-op and just return the `impairedDate`.
        //       If the Loan is not impaired, the accountedInterest will be updated to block.timestamp,
        //       which will include the total interest due for the Loan.
        uint40 impairedDate_ = _accountForLoanImpairment(loan_);

        ( , uint256 interest_, uint256 lateInterest_, , uint256 platformServiceFee_ ) = ILoanLike(loan_).getPaymentBreakdown(impairedDate_);

        uint256 principal_ = ILoanLike(loan_).principal();

        interest_ += lateInterest_;

        // Pull any `fundsAsset` in loan into LM.
        uint256 recoveredFunds_ = ILoanLike(loan_).repossess(address(this));

        // Distribute the recovered funds (to treasury, pool, and borrower) and determine the losses, if any, that must still be realized.
        (
            remainingLosses_,
            unrecoveredPlatformFees_
        ) = _distributeLiquidationFunds(loan_, principal_, interest_, platformServiceFee_, recoveredFunds_);

        // Remove the payment and cache the struct.
        Payment memory payment_ = _removePayment(loan_);

        // NOTE: This is the amount of interest accounted for, before the loan's impairment,
        //       that is still in the aggregate `accountedInterest` and offset in `unrealizedLosses`
        //       The original `impairedDate` is always used over the current `impairedDate` on the Loan,
        //       this ensures the interest calculated for `unrealizedLosses` matches the original impairment calculation.
        uint256 accountedImpairedInterest_ = _getIssuance(payment_.issuanceRate, impairedDate_ - payment_.startDate);

        // The payment's interest until the `impairedDate` must be deducted from `accountedInterest`, thus realizing the interest loss.
        // The unrealized losses incurred due to the impairment must be deducted from the global `unrealizedLosses`.
        // The loan's principal must be deducted from `principalOut`, thus realizing the principal loss.
        _updateInterestAccounting(-_int256(accountedImpairedInterest_), 0);
        _updateUnrealizedLosses(-_int256(principal_ + accountedImpairedInterest_));
        _updatePrincipalOut(-_int256(principal_));

        delete impairmentFor[loan_];
    }

    /**************************************************************************************************************************************/
    /*** Internal Functions                                                                                                             ***/
    /**************************************************************************************************************************************/

    function _addPayment(address loan_) internal returns (Payment memory payment_) {
        uint256 platformManagementFeeRate_ = IGlobalsLike(_globals()).platformManagementFeeRate(poolManager);
        uint256 delegateManagementFeeRate_ = IPoolManagerLike(poolManager).delegateManagementFeeRate();
        uint256 managementFeeRate_         = platformManagementFeeRate_ + delegateManagementFeeRate_;

        // NOTE: If combined fee is greater than 100%, then cap delegate fee and clamp management fee.
        if (managementFeeRate_ > HUNDRED_PERCENT) {
            delegateManagementFeeRate_ = HUNDRED_PERCENT - platformManagementFeeRate_;
            managementFeeRate_         = HUNDRED_PERCENT;
        }

        uint256 paymentDueDate_ = ILoanLike(loan_).paymentDueDate();
        uint256 dueInterest_    = _getNetInterest(loan_, paymentDueDate_, managementFeeRate_);

        // NOTE: Can assume `paymentDueDate_ > block.timestamp` and interest at `block.timestamp` is 0 because payments are only added when
        //         - loans are funded, or
        //         - payments are claimed, resulting in a new payment.
        uint256 paymentIssuanceRate_ = (dueInterest_ * PRECISION) / (paymentDueDate_ - block.timestamp);

        paymentFor[loan_] = payment_ = Payment({
            platformManagementFeeRate: _uint24(platformManagementFeeRate_),
            delegateManagementFeeRate: _uint24(delegateManagementFeeRate_),
            startDate:                 _uint40(block.timestamp),
            issuanceRate:              _uint168(paymentIssuanceRate_)
        });

        emit PaymentAdded(
            loan_,
            platformManagementFeeRate_,
            delegateManagementFeeRate_,
            paymentDueDate_,
            paymentIssuanceRate_
        );
    }

    function _accountForLoanImpairment(address loan_, bool isGovernor_) internal returns (uint40 impairedDate_) {
        impairedDate_ = impairmentFor[loan_].impairedDate;

        // NOTE: Impairing an already-impaired loan simply updates the `dateImpaired` of the loan, which can push the due date further,
        //       however, the `impairedDate` in the struct should not be updated since it defines the moment when accounting for the loan's
        //       payment was paused, and is needed to restore accounting for the eventual removal of the impairment, or the default.
        if (impairedDate_ != 0) return impairedDate_;

        Payment memory payment_ = paymentFor[loan_];

        impairmentFor[loan_] = Impairment(impairedDate_ = _uint40(block.timestamp), isGovernor_);

        // Account for all interest until now (including this payment's), then remove payment's `issuanceRate` from global `issuanceRate`.
        _updateInterestAccounting(0, -_int256(payment_.issuanceRate));

        uint256 principal_ = ILoanLike(loan_).principal();

        // Add the payment's entire interest until now (negating above), and the loan's principal, to unrealized losses.
        _updateUnrealizedLosses(_int256(principal_ + _getIssuance(payment_.issuanceRate, block.timestamp - payment_.startDate)));
    }

    function _accountForLoanImpairment(address loan_) internal returns (uint40 impairedDate_) {
        impairedDate_ = _accountForLoanImpairment(loan_, false);
    }

    function _accountForLoanImpairmentAsGovernor(address loan_) internal returns (uint40 impairedDate_) {
        impairedDate_ = _accountForLoanImpairment(loan_, true);
    }

    function _accountForLoanImpairmentRemoval(address loan_, uint256 originalPrincipal_) internal returns (uint40 impairedDate_, bool impairedByGovernor_) {
        Impairment memory impairment_ = impairmentFor[loan_];

        impairedDate_       = impairment_.impairedDate;
        impairedByGovernor_ = impairment_.impairedByGovernor;

        if (impairedDate_ == 0) return ( impairedDate_, impairedByGovernor_ );

        delete impairmentFor[loan_];

        Payment memory payment_ = paymentFor[loan_];

        // Subtract the payment's entire interest until it's impairment date, and the loan's principal, from unrealized losses.
        _updateUnrealizedLosses(-_int256(originalPrincipal_ + _getIssuance(payment_.issuanceRate, impairedDate_ - payment_.startDate)));

        // Account for all interest until now, adjusting for payment's interest between its impairment date and now,
        // then add payment's `issuanceRate` to the global `issuanceRate`.
        // NOTE: Upon impairment, for payment's interest between its start date and its impairment date were accounted for.
        _updateInterestAccounting(
            _int256(_getIssuance(payment_.issuanceRate, block.timestamp - impairedDate_)),
            _int256(payment_.issuanceRate)
        );
    }

    function _removePayment(address loan_) internal returns (Payment memory payment_) {
        payment_ = paymentFor[loan_];

        delete paymentFor[loan_];

        emit PaymentRemoved(loan_);
    }

    function _updateInterestAccounting(int256 accountedInterestAdjustment_, int256 issuanceRateAdjustment_) internal {
        // NOTE: Order of operations is important as `accruedInterest()` depends on the pre-adjusted `issuanceRate` and `domainStart`.
        accountedInterest = _uint112(_max(_int256(accountedInterest + accruedInterest()) + accountedInterestAdjustment_, 0));
        domainStart       = _uint40(block.timestamp);
        issuanceRate      = _uint256(_max(_int256(issuanceRate) + issuanceRateAdjustment_, 0));

        emit AccountingStateUpdated(issuanceRate, accountedInterest);
    }

    function _updatePrincipalOut(int256 principalOutAdjustment_) internal {
        emit PrincipalOutUpdated(principalOut = _uint128(_max(_int256(principalOut) + principalOutAdjustment_, 0)));
    }

    function _updateUnrealizedLosses(int256 lossesAdjustment_) internal {
        emit UnrealizedLossesUpdated(unrealizedLosses = _uint128(_max(_int256(unrealizedLosses) + lossesAdjustment_, 0)));
    }

    /**************************************************************************************************************************************/
    /*** Funds Distribution Functions                                                                                                   ***/
    /**************************************************************************************************************************************/

    function _distributeClaimedFunds(
        address loan_,
        int256  principal_,
        uint256 interest_,
        uint256 delegateServiceFee_,
        uint256 platformServiceFee_
    )
        internal
    {
        Payment memory payment_ = paymentFor[loan_];

        uint256 delegateManagementFee_ = _getRatedAmount(interest_, payment_.delegateManagementFeeRate);
        uint256 platformManagementFee_ = _getRatedAmount(interest_, payment_.platformManagementFeeRate);

        // If the coverage is not sufficient move the delegate service fee to the platform and remove the delegate management fee.
        if (!IPoolManagerLike(poolManager).hasSufficientCover()) {
            platformServiceFee_ += delegateServiceFee_;

            delegateServiceFee_    = 0;
            delegateManagementFee_ = 0;
        }

        uint256 netInterest_ = interest_ - (platformManagementFee_ + delegateManagementFee_);

        principal_ = principal_ > int256(0) ? principal_ : int256(0);

        emit ClaimedFundsDistributed(
            loan_,
            uint256(principal_),
            interest_,
            delegateManagementFee_,
            delegateServiceFee_,
            platformManagementFee_,
            platformServiceFee_
        );

        address fundsAsset_ = fundsAsset;

        require(_transfer(fundsAsset_, _pool(),         uint256(principal_) + netInterest_),           "LM:DCF:TRANSFER_P");
        require(_transfer(fundsAsset_, _poolDelegate(), delegateServiceFee_ + delegateManagementFee_), "LM:DCF:TRANSFER_PD");
        require(_transfer(fundsAsset_, _treasury(),     platformServiceFee_ + platformManagementFee_), "LM:DCF:TRANSFER_MT");
    }

    function _distributeLiquidationFunds(
        address loan_,
        uint256 principal_,
        uint256 interest_,
        uint256 platformServiceFee_,
        uint256 recoveredFunds_
    )
        internal returns (uint256 remainingLosses_, uint256 unrecoveredPlatformFees_)
    {
        Payment memory payment_ = paymentFor[loan_];

        uint256 platformManagementFee_ = _getRatedAmount(interest_, payment_.platformManagementFeeRate);
        uint256 delegateManagementFee_ = _getRatedAmount(interest_, payment_.delegateManagementFeeRate);

        uint256 netInterest_ = interest_ - (platformManagementFee_ + delegateManagementFee_);
        uint256 platformFee_ = platformServiceFee_ + platformManagementFee_;

        uint256 toTreasury_ = _min(recoveredFunds_, platformFee_);

        unrecoveredPlatformFees_ = platformFee_ - toTreasury_;

        recoveredFunds_ -= toTreasury_;

        uint256 toPool_ = _min(recoveredFunds_, principal_ + netInterest_);

        remainingLosses_ = principal_ + netInterest_ - toPool_;

        recoveredFunds_ -= toPool_;

        emit ExpectedClaim(loan_, principal_, netInterest_, platformManagementFee_, platformServiceFee_);

        emit LiquidatedFundsDistributed(loan_, recoveredFunds_, toPool_, toTreasury_);

        // NOTE: Cannot cache `fundsAsset` due to "Stack too deep" issue.
        require(_transfer(fundsAsset, ILoanLike(loan_).borrower(), recoveredFunds_), "LM:DLF:TRANSFER_B");
        require(_transfer(fundsAsset, _pool(),                     toPool_),         "LM:DLF:TRANSFER_P");
        require(_transfer(fundsAsset, _treasury(),                 toTreasury_),     "LM:DLF:TRANSFER_MT");
    }

    function _prepareFundsForLoan(address loan_, uint256 amount_) internal {
        // Request funds from pool manager.
        IPoolManagerLike(poolManager).requestFunds(address(this), amount_);

        // Approve the loan to use these funds.
        require(ERC20Helper.approve(fundsAsset, loan_, amount_), "LM:PFFL:APPROVE_FAILED");
    }

    function _transfer(address asset_, address to_, uint256 amount_) internal returns (bool success_) {
        success_ = (to_ != address(0)) && ((amount_ == 0) || ERC20Helper.transfer(asset_, to_, amount_));
    }

    /**************************************************************************************************************************************/
    /*** Internal Loan Accounting Helper Functions                                                                                      ***/
    /**************************************************************************************************************************************/

    function _getIssuance(uint256 issuanceRate_, uint256 interval_) internal pure returns (uint256 issuance_) {
        issuance_ = (issuanceRate_ * interval_) / PRECISION;
    }

    function _getNetInterest(address loan_, uint256 timestamp_, uint256 managementFeeRate_) internal view returns (uint256 netInterest_) {
        ( , uint256 interest_, , , ) = ILoanLike(loan_).getPaymentBreakdown(timestamp_);

        netInterest_ = _getNetInterest(interest_, managementFeeRate_);
    }

    function _getNetInterest(uint256 interest_, uint256 feeRate_) internal pure returns (uint256 netInterest_) {
        // NOTE: This ensures that `netInterest_ == interest_ - fee_`, since absolutes are subtracted, not rates.
        netInterest_ = interest_ - _getRatedAmount(interest_, feeRate_);
    }

    function _getRatedAmount(uint256 amount_, uint256 rate_) internal pure returns (uint256 ratedAmount_) {
        ratedAmount_ = (amount_ * rate_) / HUNDRED_PERCENT;
    }

    /**************************************************************************************************************************************/
    /*** Loan Manager View Functions                                                                                                    ***/
    /**************************************************************************************************************************************/

    function accruedInterest() public view override returns (uint256 accruedInterest_) {
        uint256 issuanceRate_ = issuanceRate;

        accruedInterest_ = issuanceRate_ == 0 ? 0 : _getIssuance(issuanceRate_, block.timestamp - domainStart);
    }

    function assetsUnderManagement() public view virtual override returns (uint256 assetsUnderManagement_) {
        assetsUnderManagement_ = principalOut + accountedInterest + accruedInterest();
    }

    /**************************************************************************************************************************************/
    /*** Protocol Address View Functions                                                                                                ***/
    /**************************************************************************************************************************************/

    function factory() external view override returns (address factory_) {
        factory_ = _factory();
    }

    function implementation() external view override returns (address implementation_) {
        implementation_ = _implementation();
    }

    /**************************************************************************************************************************************/
    /*** Internal View Functions                                                                                                        ***/
    /**************************************************************************************************************************************/

    function _globals() internal view returns (address globals_) {
        globals_ = IMapleProxyFactory(_factory()).mapleGlobals();
    }

    function _governor() internal view returns (address governor_) {
        governor_ = IGlobalsLike(_globals()).governor();
    }

    function _pool() internal view returns (address pool_) {
        pool_ = IPoolManagerLike(poolManager).pool();
    }

    function _poolDelegate() internal view returns (address poolDelegate_) {
        poolDelegate_ = IPoolManagerLike(poolManager).poolDelegate();
    }

    function _revertIfNotLoan(address loan_) internal view {
        require(paymentFor[loan_].startDate != 0, "LM:NOT_LOAN");
    }

    function _revertIfNotPoolDelegate() internal view {
        require(msg.sender == _poolDelegate(), "LM:NOT_PD");
    }

    function _revertIfPaused() internal view {
        require(!IGlobalsLike(_globals()).isFunctionPaused(msg.sig), "LM:PAUSED");
    }

    function _treasury() internal view returns (address treasury_) {
        treasury_ = IGlobalsLike(_globals()).mapleTreasury();
    }

    /**************************************************************************************************************************************/
    /*** Internal Pure Utility Functions                                                                                                ***/
    /**************************************************************************************************************************************/

    function _int256(uint256 input_) internal pure returns (int256 output_) {
        require(input_ <= uint256(type(int256).max), "LM:UINT256_OOB_FOR_INT256");
        output_ = int256(input_);
    }

    function _max(int256 a_, int256 b_) internal pure returns (int256 maximum_) {
        maximum_ = a_ > b_ ? a_ : b_;
    }

    function _min(uint256 a_, uint256 b_) internal pure returns (uint256 minimum_) {
        minimum_ = a_ < b_ ? a_ : b_;
    }

    function _uint24(uint256 input_) internal pure returns (uint24 output_) {
        require(input_ <= type(uint24).max, "LM:UINT256_OOB_FOR_UINT24");
        output_ = uint24(input_);
    }

    function _uint40(uint256 input_) internal pure returns (uint40 output_) {
        require(input_ <= type(uint40).max, "LM:UINT256_OOB_FOR_UINT40");
        output_ = uint40(input_);
    }

    function _uint112(int256 input_) internal pure returns (uint112 output_) {
        require(input_ <= int256(uint256(type(uint112).max)) && input_ >= 0, "LM:INT256_OOB_FOR_UINT112");
        output_ = uint112(uint256(input_));
    }

    function _uint128(int256 input_) internal pure returns (uint128 output_) {
        require(input_ <= int256(uint256(type(uint128).max)) && input_ >= 0, "LM:INT256_OOB_FOR_UINT128");
        output_ = uint128(uint256(input_));
    }

    function _uint168(uint256 input_) internal pure returns (uint168 output_) {
        require(input_ <= type(uint168).max, "LM:UINT256_OOB_FOR_UINT168");
        output_ = uint168(input_);
    }

    function _uint168(int256 input_) internal pure returns (uint168 output_) {
        require(input_ <= int256(uint256(type(uint168).max)) && input_ >= 0, "LM:INT256_OOB_FOR_UINT168");
        output_ = uint168(uint256(input_));
    }

    function _uint256(int256 input_) internal pure returns (uint256 output_) {
        require(input_ >= 0, "LM:INT256_OOB_FOR_UINT256");
        output_ = uint256(input_);
    }

}
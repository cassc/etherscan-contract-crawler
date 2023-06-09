// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.7;

import { ERC20Helper }           from "../modules/erc20-helper/src/ERC20Helper.sol";
import { MapleProxiedInternals } from "../modules/maple-proxy-factory/contracts/MapleProxiedInternals.sol";

import { ILoanManager } from "./interfaces/ILoanManager.sol";

import {
    IERC20Like,
    ILiquidatorLike,
    ILoanFactoryLike,
    IMapleGlobalsLike,
    IMapleLoanLike,
    IMapleProxyFactoryLike,
    IPoolManagerLike
} from "./interfaces/Interfaces.sol";

import { LoanManagerStorage } from "./proxy/LoanManagerStorage.sol";

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
    uint256 public override constant PRECISION       = 1e30;

    /**************************************************************************************************************************************/
    /*** Modifiers                                                                                                                      ***/
    /**************************************************************************************************************************************/

    modifier nonReentrant() {
        require(_locked == 1, "LM:LOCKED");

        _locked = 2;

        _;

        _locked = 1;
    }

    modifier onlyFactory() {
        _revertIfNotFactory();
        _;
    }

    modifier onlyPoolDelegate() {
        _revertIfNotPoolDelegate();
        _;
    }

    modifier onlyPoolDelegateOrGovernor() {
        _revertIfNotPoolDelegateOrGovernor();
        _;
    }

    modifier onlyPoolManager() {
        _revertIfNotPoolManager();
        _;
    }

    modifier whenNotPaused() {
        _revertIfPaused();
        _;
    }

    /**************************************************************************************************************************************/
    /*** Upgradeability Functions                                                                                                       ***/
    /**************************************************************************************************************************************/

    function migrate(address migrator_, bytes calldata arguments_) external override whenNotPaused onlyFactory {
        require(_migrate(migrator_, arguments_), "LM:M:FAILED");
    }

    function setImplementation(address implementation_) external override whenNotPaused onlyFactory {
       _setImplementation(implementation_);
    }

    function upgrade(uint256 version_, bytes calldata arguments_) external override whenNotPaused {
        IMapleGlobalsLike globals_ = IMapleGlobalsLike(_globals());

        if (msg.sender == poolDelegate()) {
            require(globals_.isValidScheduledCall(msg.sender, address(this), "LM:UPGRADE", msg.data), "LM:U:INV_SCHED_CALL");

            globals_.unscheduleCall(msg.sender, "LM:UPGRADE", msg.data);
        } else {
            require(msg.sender == globals_.securityAdmin(), "LM:U:NO_AUTH");
        }

        emit Upgraded(version_, arguments_);

        IMapleProxyFactoryLike(_factory()).upgradeInstance(version_, arguments_);
    }

    /**************************************************************************************************************************************/
    /*** Collateral Liquidation Administrative Functions                                                                                ***/
    /**************************************************************************************************************************************/

    function setAllowedSlippage(address collateralAsset_, uint256 allowedSlippage_)
        external override whenNotPaused onlyPoolDelegateOrGovernor
    {
        require(allowedSlippage_ <= HUNDRED_PERCENT, "LM:SAS:INV_SLIPPAGE");

        emit AllowedSlippageSet(collateralAsset_, allowedSlippageFor[collateralAsset_] = allowedSlippage_);
    }

    function setMinRatio(address collateralAsset_, uint256 minRatio_) external override whenNotPaused onlyPoolDelegateOrGovernor {
        emit MinRatioSet(collateralAsset_, minRatioFor[collateralAsset_] = minRatio_);
    }

    /**************************************************************************************************************************************/
    /*** Manual Accounting Update Function                                                                                              ***/
    /**************************************************************************************************************************************/

    function updateAccounting() external override whenNotPaused onlyPoolDelegateOrGovernor {
        _advanceGlobalPaymentAccounting();

        _updateIssuanceParams(issuanceRate, accountedInterest);
    }

    /**************************************************************************************************************************************/
    /*** Loan Funding and Refinancing Functions                                                                                         ***/
    /**************************************************************************************************************************************/

    function acceptNewTerms(
        address          loan_,
        address          refinancer_,
        uint256          deadline_,
        bytes[] calldata calls_,
        uint256          principalIncrease_
    )
        external override nonReentrant whenNotPaused onlyPoolDelegate
    {
        _advanceGlobalPaymentAccounting();

        // NOTE: Verification that the loan payment exists is done in `_handlePreviousPaymentAccounting()`.
        uint256 previousRate_      = _handlePreviousPaymentAccounting(loan_);
        uint256 previousPrincipal_ = IMapleLoanLike(loan_).principal();

        _skimFundsFromLoan(loan_);

        if (principalIncrease_ > 0) {
            require(IMapleGlobalsLike(_globals()).isBorrower(IMapleLoanLike(loan_).borrower()), "LM:ANT:INVALID_BORROWER");
            IPoolManagerLike(poolManager).requestFunds(loan_, principalIncrease_);
        }

        // Perform the refinancing, updating the loan state.
        IMapleLoanLike(loan_).acceptNewTerms(refinancer_, deadline_, calls_);

        emit PrincipalOutUpdated(principalOut = principalOut + _uint128(IMapleLoanLike(loan_).principal()) - _uint128(previousPrincipal_));

        // NOTE: Since acceptNewTerms starts the payment interval from block.timestamp,
        // no logic is needed to account for interest in the incoming interval.
        // Update the vesting state an then set the new issuance rate take into account the cessation of the previous rate
        // and the commencement of the new rate for this payment.
        // NOTE: `_queueNextPayment` returns the `newRate`.
        _updateIssuanceParams(
            issuanceRate + _queueNextPayment(loan_, block.timestamp, IMapleLoanLike(loan_).nextPaymentDueDate()) - previousRate_,
            accountedInterest
        );
    }

    function fund(address loan_) external override nonReentrant whenNotPaused onlyPoolDelegate {
        ILoanFactoryLike  factory_ = ILoanFactoryLike(IMapleLoanLike(loan_).factory());
        IMapleGlobalsLike globals_ = IMapleGlobalsLike(_globals());

        require(globals_.isInstanceOf("FT_LOAN_FACTORY", address(factory_)), "LM:F:INV_LOAN_FACTORY");
        require(factory_.isLoan(loan_),                                      "LM:F:INV_LOAN_INSTANCE");
        require(globals_.isBorrower(IMapleLoanLike(loan_).borrower()),       "LM:F:INV_BORROWER");
        require(IMapleLoanLike(loan_).paymentsRemaining() != 0,              "LM:F:LOAN_INACTIVE");

        _advanceGlobalPaymentAccounting();

        uint256 principal_ = IMapleLoanLike(loan_).principalRequested();

        _skimFundsFromLoan(loan_);
        IPoolManagerLike(poolManager).requestFunds(loan_, principal_);
        IMapleLoanLike(loan_).fundLoan();

        emit PrincipalOutUpdated(principalOut += _uint128(principal_));

        // Add new issuance rate from queued payment to aggregate issuance rate.
        _updateIssuanceParams(
            issuanceRate + _queueNextPayment(loan_, block.timestamp, IMapleLoanLike(loan_).nextPaymentDueDate()),
            accountedInterest
        );
    }

    function rejectNewTerms(
        address          loan_,
        address          refinancer_,
        uint256          deadline_,
        bytes[] calldata calls_
    ) external override whenNotPaused onlyPoolDelegate {
        IMapleLoanLike(loan_).rejectNewTerms(refinancer_, deadline_, calls_);
    }

    /**************************************************************************************************************************************/
    /*** Loan Payment Claim Function                                                                                                    ***/
    /**************************************************************************************************************************************/

    function claim(
        uint256 principal_,
        uint256 interest_,
        uint256 previousPaymentDueDate_,
        uint256 nextPaymentDueDate_
    )
        external override nonReentrant whenNotPaused
    {
        // 1. Advance the global accounting.
        //    - Update `domainStart` to the current `block.timestamp`.
        //    - Update `accountedInterest` to account all accrued interest since last update.
        _advanceGlobalPaymentAccounting();

        // 2. Transfer the funds from the loan to the `pool`, `poolDelegate`, and `mapleTreasury`.
        _distributeClaimedFunds(msg.sender, principal_, interest_);

        // 3. If principal has been paid back, decrement `principalOut`.
        if (principal_ != 0) {
            emit PrincipalOutUpdated(principalOut -= _uint128(principal_));
        }

        // NOTE: Verification that the loan payment exists is done in `_handlePreviousPaymentAccounting()`.
        // 4. Update the accounting based on the payment that was just made.
        uint256 previousRate_ = _handlePreviousPaymentAccounting(msg.sender);

        // 5. If there is no next payment for this loan, update the global accounting and exit.
        //    - Delete the paymentId from the `paymentIdOf` mapping since there is no next payment.
        if (nextPaymentDueDate_ == 0) {
            delete paymentIdOf[msg.sender];
            _updateIssuanceParams(issuanceRate - previousRate_, accountedInterest);
            return;
        }

        // 6. Calculate the start date of the next loan payment.
        //    - If the previous payment is on time or early, the start date is the current `block.timestamp`,
        //      and the `issuanceRate` will be calculated over the interval from `block.timestamp` to the next payment due date.
        //    - If the payment is late, the start date will be the previous payment due date,
        //      and the `issuanceRate` will be calculated over the loan's exact payment interval.
        // 7. Queue the next payment for the loan.
        //    - Add the payment to the sorted list.
        //    - Update the `paymentIdOf` mapping.
        //    - Update the `payments` mapping with all of the relevant new payment info.
        uint256 newRate_ = _queueNextPayment(msg.sender, _min(block.timestamp, previousPaymentDueDate_), nextPaymentDueDate_);

        // 8a. If the payment is early, the `accountedInterest` is already fully up to date.
        //      In this case, the `issuanceRate` is the only variable that needs to be updated.
        if (block.timestamp <= previousPaymentDueDate_) {
            _updateIssuanceParams(issuanceRate + newRate_ - previousRate_, accountedInterest);
            return;
        }

        // 8b. If the payment is late, the `issuanceRate` from the previous payment has already been removed from the global `issuanceRate`.
        //     - Update the global `issuanceRate` to account for the new payments `issuanceRate`.
        //     - Update the `accountedInterest` to represent the interest that has accrued from the `previousPaymentDueDate` to the current
        //       `block.timestamp`.
        //     Payment `issuanceRate` is used for this calculation as the issuance has occurred in isolation and entirely in the past.
        //     All interest from the aggregate issuance rate has already been accounted for in `_advanceGlobalPaymentAccounting`.
        if (block.timestamp <= nextPaymentDueDate_) {
            _updateIssuanceParams(
                issuanceRate + newRate_,
                accountedInterest + _uint112((block.timestamp - previousPaymentDueDate_) * newRate_ / PRECISION)
            );
            return;
        }

        // 8c. If the current timestamp is greater than the RESULTING `nextPaymentDueDate`, then the next payment must be
        //     FULLY accounted for, and the new payment must be removed from the sorted list.
        //     Payment `issuanceRate` is used for this calculation as the issuance has occurred in isolation and entirely in the past.
        //     All interest from the aggregate issuance rate has already been accounted for in `_advanceGlobalPaymentAccounting`.
        ( uint256 accountedInterestIncrease_, ) = _accountToEndOfPayment(
            paymentIdOf[msg.sender],
            newRate_,
            previousPaymentDueDate_,
            nextPaymentDueDate_
        );

        _updateIssuanceParams(
            issuanceRate,
            accountedInterest + _uint112(accountedInterestIncrease_)
        );
    }

    /**************************************************************************************************************************************/
    /*** Loan Impairment Functions                                                                                                      ***/
    /**************************************************************************************************************************************/

    function impairLoan(address loan_) external override whenNotPaused onlyPoolDelegateOrGovernor {
        require(!IMapleLoanLike(loan_).isImpaired(), "LM:IL:IMPAIRED");

        // NOTE: Must get payment info prior to advancing payment accounting, because that will set issuance rate to 0.
        uint256 paymentId_ = paymentIdOf[loan_];

        require(paymentId_ != 0, "LM:IL:NOT_LOAN");

        PaymentInfo memory paymentInfo_ = payments[paymentId_];

        _advanceGlobalPaymentAccounting();

        _removePaymentFromList(paymentId_);

        // NOTE: Use issuance rate from payment info in storage, because it would have been set to zero and accounted for already if late.
        _updateIssuanceParams(issuanceRate - payments[paymentId_].issuanceRate, accountedInterest);

        ( uint256 netInterest_, uint256 netLateInterest_, uint256 platformFees_ ) = _getDefaultInterestAndFees(loan_, paymentInfo_);

        uint256 principal_ = IMapleLoanLike(loan_).principal();

        liquidationInfo[loan_] = LiquidationInfo({
            triggeredByGovernor: msg.sender == governor(),
            principal:           _uint128(principal_),
            interest:            _uint120(netInterest_),
            lateInterest:        netLateInterest_,
            platformFees:        _uint96(platformFees_),
            liquidator:          address(0)
        });

        emit UnrealizedLossesUpdated(unrealizedLosses += _uint128(principal_ + netInterest_));

        IMapleLoanLike(loan_).impairLoan();
    }

    function removeLoanImpairment(address loan_) external override nonReentrant whenNotPaused {
        LiquidationInfo memory liquidationInfo_ = liquidationInfo[loan_];

        require(
            msg.sender == governor() ||
            (!liquidationInfo_.triggeredByGovernor && msg.sender == poolDelegate()),
            "LM:RLI:NO_AUTH"
        );

        require(block.timestamp <= IMapleLoanLike(loan_).originalNextPaymentDueDate(), "LM:RLI:PAST_DATE");

        _advanceGlobalPaymentAccounting();

        uint24 paymentId_ = paymentIdOf[loan_];

        require(paymentId_ != 0, "LM:RLI:NOT_LOAN");

        PaymentInfo memory paymentInfo_ = payments[paymentId_];

        _revertLoanImpairment(liquidationInfo_);

        delete liquidationInfo[loan_];
        delete payments[paymentId_];

        payments[paymentIdOf[loan_] = _addPaymentToList(paymentInfo_.paymentDueDate)] = paymentInfo_;

        // Discretely update missing interest as if payment was always part of the list.
        _updateIssuanceParams(
            issuanceRate + paymentInfo_.issuanceRate,
            accountedInterest + _uint112(
                _getPaymentAccruedInterest(
                    paymentInfo_.startDate,
                    block.timestamp,
                    paymentInfo_.issuanceRate,
                    paymentInfo_.refinanceInterest
                )
            )
        );

        IMapleLoanLike(loan_).removeLoanImpairment();
    }

    /**************************************************************************************************************************************/
    /*** Loan Default Functions                                                                                                         ***/
    /**************************************************************************************************************************************/

    function finishCollateralLiquidation(address loan_)
        external override nonReentrant whenNotPaused onlyPoolManager returns (uint256 remainingLosses_, uint256 platformFees_)
    {
        require(!isLiquidationActive(loan_), "LM:FCL:LIQ_ACTIVE");

        _advanceGlobalPaymentAccounting();

        // Philosophy for this function is triggerDefault should figure out all the details,
        // and finish should use that info and execute the liquidation and accounting updates.
        LiquidationInfo memory liquidationInfo_ = liquidationInfo[loan_];

        require(liquidationInfo_.liquidator != address(0), "LM:FCL:NOT_LIQUIDATED");

        // Reduce principal out, since it has been accounted for in the liquidation.
        emit PrincipalOutUpdated(principalOut -= liquidationInfo_.principal);

        remainingLosses_ = liquidationInfo_.principal + liquidationInfo_.interest + liquidationInfo_.lateInterest;
        platformFees_    = liquidationInfo_.platformFees;

        // Realize the loss following the liquidation.
        emit UnrealizedLossesUpdated(unrealizedLosses -= _uint128(liquidationInfo_.principal + liquidationInfo_.interest));

        address fundsAsset_     = fundsAsset;
        uint256 recoveredFunds_ = IERC20Like(fundsAsset_).balanceOf(liquidationInfo_.liquidator);

        delete liquidationInfo[loan_];

        _compareAndSubtractAccountedInterest(liquidationInfo_.interest);

        // Reduce accounted interest by the interest portion of the shortfall, as the loss has been realized,
        // and therefore this interest has been accounted for.
        // Don't reduce by late interest, since we never account for this interest in the issuance rate, only via discrete updates.
        _updateIssuanceParams(issuanceRate, accountedInterest);

        if (recoveredFunds_ == 0) return ( remainingLosses_, platformFees_ );

        ILiquidatorLike(liquidationInfo_.liquidator).pullFunds(fundsAsset_, address(this), recoveredFunds_);

        ( remainingLosses_, platformFees_ ) = _distributeLiquidationFunds(loan_, recoveredFunds_, platformFees_, remainingLosses_);
    }

    function triggerDefault(address loan_, address liquidatorFactory_)
        external override whenNotPaused onlyPoolManager returns (bool liquidationComplete_, uint256 remainingLosses_, uint256 platformFees_)
    {
        uint256 paymentId_ = paymentIdOf[loan_];

        require(paymentId_ != 0, "LM:TD:NOT_LOAN");

        // NOTE: Must get payment info prior to advancing payment accounting, because that will set issuance rate to 0.
        PaymentInfo memory paymentInfo_ = payments[paymentId_];

        // NOTE: This will cause this payment to be removed from the list, so no need to remove it explicitly afterwards.
        _advanceGlobalPaymentAccounting();

        uint256 netInterest_;
        uint256 netLateInterest_;

        bool isImpaired_ = IMapleLoanLike(loan_).isImpaired();

        ( netInterest_, netLateInterest_, platformFees_ ) = isImpaired_
            ? _getInterestAndFeesFromLiquidationInfo(loan_)
            : _getDefaultInterestAndFees(loan_, paymentInfo_);

        address collateralAsset_ = IMapleLoanLike(loan_).collateralAsset();

        if (IERC20Like(collateralAsset_ ).balanceOf(loan_) == 0 || collateralAsset_ == fundsAsset) {
            ( remainingLosses_, platformFees_ ) = _handleNonLiquidatingRepossession(loan_, platformFees_, netInterest_, netLateInterest_);
            return ( true, remainingLosses_, platformFees_ );
        }

        ( address liquidator_, uint256 principal_ ) = _handleLiquidatingRepossession(loan_, liquidatorFactory_, netInterest_);

        if (isImpaired_) {
            liquidationInfo[loan_].liquidator = liquidator_;
        } else {
            liquidationInfo[loan_] = LiquidationInfo({
                triggeredByGovernor: false,
                principal:           _uint128(principal_),
                interest:            _uint120(netInterest_),
                lateInterest:        netLateInterest_,
                platformFees:        _uint96(platformFees_),
                liquidator:          liquidator_
            });
        }
    }

    /**************************************************************************************************************************************/
    /*** Internal Payment Accounting Functions                                                                                          ***/
    /**************************************************************************************************************************************/

    // Advance payments in previous domains to "catch up" to current state.
    function _accountToEndOfPayment(uint256 paymentId_, uint256 issuanceRate_, uint256 intervalStart_, uint256 intervalEnd_)
        internal returns (uint256 accountedInterestIncrease_, uint256 issuanceRateReduction_)
    {
        PaymentInfo memory payment_ = payments[paymentId_];

        // Remove the payment from the linked list so the next payment can be used as the shortest timestamp.
        // NOTE: This keeps the payment accounting info intact so it can be accounted for when the payment is claimed.
        _removePaymentFromList(paymentId_);

        issuanceRateReduction_ = payment_.issuanceRate;

        // Update accounting between timestamps and set last updated to the domainEnd.
        // Reduce the issuanceRate for the payment.
        accountedInterestIncrease_ = (intervalEnd_ - intervalStart_) * issuanceRate_ / PRECISION;

        // Remove issuanceRate as it is deducted from global issuanceRate.
        payments[paymentId_].issuanceRate = 0;
    }

    function _deletePayment(address loan_) internal {
        delete payments[paymentIdOf[loan_]];
        delete paymentIdOf[loan_];
    }

    function _handlePreviousPaymentAccounting(address loan_) internal returns (uint256 previousRate_) {
        LiquidationInfo memory liquidationInfo_ = liquidationInfo[loan_];

        uint256 paymentId_ = paymentIdOf[loan_];

        require(paymentId_ != 0, "LM:HPPA:NOT_LOAN");

        PaymentInfo memory paymentInfo_ = payments[paymentId_];

        // Remove the payment from the mapping once cached to memory.
        delete payments[paymentId_];

        emit PaymentRemoved(loan_, paymentId_);

        // If a payment has been made against a loan that was impaired, reverse the impairment accounting.
        if (liquidationInfo_.principal != 0) {
            _revertLoanImpairment(liquidationInfo_);  // NOTE: Don't set the previous rate since it will always be zero.
            delete liquidationInfo[loan_];
            return 0;
        }

        // If a payment has been made late, its interest has already been fully accounted through `_advanceGlobalPaymentAccounting` logic.
        // It also has been removed from the sorted list, and its `issuanceRate` has been removed from the global `issuanceRate`.
        // The only accounting that must be done is to update the `accountedInterest` to account for the payment being made.
        if (block.timestamp > paymentInfo_.paymentDueDate) {
            _compareAndSubtractAccountedInterest(paymentInfo_.incomingNetInterest + paymentInfo_.refinanceInterest);
            return 0;
        }

        // If a payment has been made on time, handle the payment accounting.
        // - Remove the payment from the sorted list.
        // - Reduce the `accountedInterest` by the value represented by the payment info.
        _removePaymentFromList(paymentId_);

        previousRate_ = paymentInfo_.issuanceRate;

        // If the amount of interest claimed is greater than the amount accounted for, set to zero.
        // Discrepancy between accounted and actual is always captured by balance change in the pool from the claimed interest.
        // Reduce the AUM by the amount of interest that was represented for this payment.
        _compareAndSubtractAccountedInterest(
            ((block.timestamp - paymentInfo_.startDate) * previousRate_ / PRECISION) +
            paymentInfo_.refinanceInterest
        );
    }

    function _queueNextPayment(address loan_, uint256 startDate_, uint256 nextPaymentDueDate_) internal returns (uint256 newRate_) {
        uint256 platformManagementFeeRate_ = IMapleGlobalsLike(_globals()).platformManagementFeeRate(poolManager);
        uint256 delegateManagementFeeRate_ = IPoolManagerLike(poolManager).delegateManagementFeeRate();
        uint256 managementFeeRate_         = platformManagementFeeRate_ + delegateManagementFeeRate_;

        // NOTE: If combined fee is greater than 100%, then cap delegate fee and clamp management fee.
        if (managementFeeRate_ > HUNDRED_PERCENT) {
            delegateManagementFeeRate_ = HUNDRED_PERCENT - platformManagementFeeRate_;
            managementFeeRate_         = HUNDRED_PERCENT;
        }

        ( , uint256[3] memory interest_, ) = IMapleLoanLike(loan_).getNextPaymentDetailedBreakdown();

        newRate_ = (_getNetInterest(interest_[0], managementFeeRate_) * PRECISION) / (nextPaymentDueDate_ - startDate_);

        uint256 paymentId_ = paymentIdOf[loan_] = _addPaymentToList(_uint48(nextPaymentDueDate_));  // Add the payment to the sorted list.

        uint256 netRefinanceInterest_ = _getNetInterest(interest_[2], managementFeeRate_);

        // NOTE: Use issuanceRate to capture rounding errors.
        payments[paymentId_] = PaymentInfo({
            platformManagementFeeRate: _uint24(platformManagementFeeRate_),
            delegateManagementFeeRate: _uint24(delegateManagementFeeRate_),
            startDate:                 _uint48(startDate_),
            paymentDueDate:            _uint48(nextPaymentDueDate_),
            incomingNetInterest:       _uint128(newRate_ * (nextPaymentDueDate_ - startDate_) / PRECISION),
            refinanceInterest:         _uint128(netRefinanceInterest_),
            issuanceRate:              newRate_
        });

        // Update the accounted interest to reflect what is present in the loan.
        accountedInterest += _uint112(netRefinanceInterest_);

        emit PaymentAdded(
            loan_,
            paymentId_,
            platformManagementFeeRate_,
            delegateManagementFeeRate_,
            startDate_,
            nextPaymentDueDate_,
            netRefinanceInterest_,
            newRate_
        );
    }

    function _revertLoanImpairment(LiquidationInfo memory liquidationInfo_) internal {
        _compareAndSubtractAccountedInterest(liquidationInfo_.interest);
        unrealizedLosses -= _uint128(liquidationInfo_.principal + liquidationInfo_.interest);

        emit UnrealizedLossesUpdated(unrealizedLosses);
    }

    /**************************************************************************************************************************************/
    /*** Internal Loan Repossession Functions                                                                                           ***/
    /**************************************************************************************************************************************/

    function _handleLiquidatingRepossession(address loan_, address liquidatorFactory_, uint256 netInterest_)
        internal returns (address liquidator_, uint256 principal_)
    {
        principal_ = IMapleLoanLike(loan_).principal();

        liquidator_ = IMapleProxyFactoryLike(liquidatorFactory_).createInstance(
            abi.encode(address(this), IMapleLoanLike(loan_).collateralAsset(), fundsAsset), bytes32(bytes20(address(loan_)))
        );

        _updateIssuanceParams(issuanceRate, accountedInterest);

        if (!IMapleLoanLike(loan_).isImpaired()) {
            // Impair the pool with the default amount.
            // NOTE: Don't include fees in unrealized losses, because this is not to be passed onto the LPs.
            //       Only collateral and cover can cover the fees.
            emit UnrealizedLossesUpdated(unrealizedLosses += _uint128(principal_ + netInterest_));
        }

        // NOTE: Need to to this after the `isImpaired` check, since `repossess` will unset it.
        ( uint256 collateralRepossessed_, ) = IMapleLoanLike(loan_).repossess(liquidator_);

        ILiquidatorLike(liquidator_).setCollateralRemaining(collateralRepossessed_);

        _deletePayment(loan_);
    }

    function _handleNonLiquidatingRepossession(address loan_, uint256 platformFees_, uint256 netInterest_, uint256 netLateInterest_)
        internal returns (uint256 remainingLosses_, uint256 updatedPlatformFees_)
    {
        uint256 principal_ = IMapleLoanLike(loan_).principal();

        // Reduce principal out, since it has been accounted for in the liquidation.
        emit PrincipalOutUpdated(principalOut -= _uint128(principal_));

        // Calculate the late interest if a late payment was made.
        remainingLosses_ = principal_ + netInterest_ + netLateInterest_;

        if (IMapleLoanLike(loan_).isImpaired()) {
            // Remove unrealized losses that `impairLoan` previously accounted for.
            emit UnrealizedLossesUpdated(unrealizedLosses -= _uint128(principal_ + netInterest_));
            delete liquidationInfo[loan_];
        }

        // Pull any fundsAsset in loan into LM.
        ( uint256 recoveredCollateral_, uint256 recoveredFundsAsset_ ) = IMapleLoanLike(loan_).repossess(address(this));

        // If there's collateral, it must be equal to funds asset, so we just sum them.
        uint256 recoveredFunds_ = recoveredCollateral_ + recoveredFundsAsset_;

        // If any funds recovered, disburse them to relevant accounts and update return variables.
        ( remainingLosses_, updatedPlatformFees_ ) = recoveredFunds_ == 0
            ? (remainingLosses_, platformFees_)
            : _distributeLiquidationFunds(loan_, recoveredFunds_, platformFees_, remainingLosses_);

        _compareAndSubtractAccountedInterest(netInterest_);

        // Reduce accounted interest by the interest portion of the shortfall, as the loss has been realized,
        // and therefore this interest has been accounted for.
        // Don't reduce by late interest, since we never account for this interest in the issuance rate, only via discrete updates.
        // NOTE: Don't reduce issuance rate by payments's issuance rate since it was done in `_advanceGlobalPaymentAccounting`.
        _updateIssuanceParams(issuanceRate, accountedInterest);

        _deletePayment(loan_);
    }

    /**************************************************************************************************************************************/
    /*** Internal Funds Distribution Functions                                                                                          ***/
    /**************************************************************************************************************************************/

    function _distributeClaimedFunds(address loan_, uint256 principal_, uint256 interest_) internal {
        uint256 paymentId_ = paymentIdOf[loan_];

        require(paymentId_ != 0, "LM:DCF:NOT_LOAN");

        uint256 platformFee_ = interest_ * payments[paymentId_].platformManagementFeeRate / HUNDRED_PERCENT;

        uint256 delegateFee_ = IPoolManagerLike(poolManager).hasSufficientCover()
            ? interest_ * payments[paymentId_].delegateManagementFeeRate / HUNDRED_PERCENT
            : 0;

        uint256 netInterest_ = interest_ - platformFee_ - delegateFee_;

        emit ManagementFeesPaid(loan_, delegateFee_, platformFee_);
        emit FundsDistributed(loan_, principal_, netInterest_);

        address fundsAsset_ = fundsAsset;

        require(_transfer(fundsAsset_, _pool(),        principal_ + netInterest_),  "LM:DCF:TRANSFER_P");
        require(_transfer(fundsAsset_, poolDelegate(), delegateFee_),               "LM:DCF:TRANSFER_PD");
        require(_transfer(fundsAsset_, _treasury(),    platformFee_),               "LM:DCF:TRANSFER_MT");
    }

    function _distributeLiquidationFunds(address loan_, uint256 recoveredFunds_, uint256 platformFees_, uint256 remainingLosses_)
        internal returns (uint256 updatedRemainingLosses_, uint256 updatedPlatformFees_)
    {
        uint256 toTreasury_ = _min(recoveredFunds_, platformFees_);

        recoveredFunds_ -= toTreasury_;

        updatedPlatformFees_ = (platformFees_ -= toTreasury_);

        uint256 toPool_ = _min(recoveredFunds_, remainingLosses_);

        recoveredFunds_ -= toPool_;

        updatedRemainingLosses_ = (remainingLosses_ -= toPool_);

        address fundsAsset_ = fundsAsset;

        require(_transfer(fundsAsset_, IMapleLoanLike(loan_).borrower(), recoveredFunds_), "LM:DLF:TRANSFER_B");
        require(_transfer(fundsAsset_, _pool(),                          toPool_),         "LM:DLF:TRANSFER_P");
        require(_transfer(fundsAsset_, _treasury(),                      toTreasury_),     "LM:DLF:TRANSFER_MT");
    }

    function _skimFundsFromLoan(address loan_) internal {
        address fundsAsset_ = fundsAsset;

        if (IMapleLoanLike(loan_).getUnaccountedAmount(fundsAsset_) == 0) return;

        // Transfer all unaccounted assets from the loan to the pool.
        IMapleLoanLike(loan_).skim(fundsAsset_, IPoolManagerLike(poolManager).pool());
    }

    function _transfer(address asset_, address to_, uint256 amount_) internal returns (bool success_) {
        success_ = (to_ != address(0)) && ((amount_ == 0) || ERC20Helper.transfer(asset_, to_, amount_));
    }

    /**************************************************************************************************************************************/
    /*** Internal Standard Procedure Update Functions                                                                                   ***/
    /**************************************************************************************************************************************/

    function _advanceGlobalPaymentAccounting() internal {
        uint256 domainEnd_ = domainEnd;

        uint256 accountedInterest_;

        // If the earliest payment in the list is in the past, then the payment accounting must be retroactively updated.
        if (domainEnd_ != 0 && block.timestamp > domainEnd_) {
            uint256 paymentId_ = paymentWithEarliestDueDate;

            // Cache variables for looping.
            uint256 domainStart_  = domainStart;
            uint256 issuanceRate_ = issuanceRate;

            // Advance payment accounting in previous domains to "catch up" to current state.
            while (block.timestamp > domainEnd_) {
                uint256 next_ = sortedPayments[paymentId_].next;

                // 1. Calculate the interest that has accrued over the domain period in the past (domainEnd - domainStart).
                // 2. Remove the earliest payment from the list
                // 3. Return the `issuanceRate` reduction (the payment's `issuanceRate`).
                // 4. Return the `accountedInterest` increase (the amount of interest accrued over the domain).
                (
                    uint256 accountedInterestIncrease_,
                    uint256 issuanceRateReduction_
                ) = _accountToEndOfPayment(paymentId_, issuanceRate_, domainStart_, domainEnd_);

                // Update cached aggregate values for updating the global state.
                accountedInterest_ += accountedInterestIncrease_;
                issuanceRate_      -= issuanceRateReduction_;

                // Update the domain start and end.
                // - Set the domain start to the previous domain end.
                // - Set the domain end to the next earliest payment.
                //   - If this value is still in the past, this loop will continue.
                domainStart_ = domainEnd_;
                domainEnd_ = paymentWithEarliestDueDate == 0
                    ? _uint48(block.timestamp)
                    : payments[paymentWithEarliestDueDate].paymentDueDate;

                // If the end of the list has been reached, exit the loop.
                if ((paymentId_ = next_) == 0) break;
            }

            // Update global accounting to reflect the changes made in the loop.
            domainStart  = _uint48(domainStart_);
            domainEnd    = _uint48(domainEnd_);
            issuanceRate = issuanceRate_;
        }

        // Update the accounted interest to the current timestamp, and update the domainStart to the current timestamp.
        accountedInterest += _uint112(accountedInterest_ + accruedInterest());
        domainStart        = _uint48(block.timestamp);
    }

    function _updateIssuanceParams(uint256 issuanceRate_, uint112 accountedInterest_) internal {
        uint256 earliestPayment_ = paymentWithEarliestDueDate;

        // If there are no more payments in the list, set domain end to block.timestamp, otherwise, set it to the next upcoming payment.
        emit IssuanceParamsUpdated(
            domainEnd         = earliestPayment_ == 0 ? _uint48(block.timestamp) : payments[earliestPayment_].paymentDueDate,
            issuanceRate      = issuanceRate_,
            accountedInterest = accountedInterest_
        );
    }

    /**************************************************************************************************************************************/
    /*** Internal Loan Accounting Helper Functions                                                                                      ***/
    /**************************************************************************************************************************************/

    function _compareAndSubtractAccountedInterest(uint256 amount_) internal {
        // Rounding errors accrue in `accountedInterest` when loans are late and the issuance rate is used to calculate
        // the interest more often to increment than to decrement.
        // When this is the case, the underflow is prevented on the last decrement by using the minimum of the two values below.
        accountedInterest -= _uint112(_min(accountedInterest, amount_));
    }

    function _getAccruedAmount(uint256 totalAccruingAmount_, uint256 startTime_, uint256 endTime_, uint256 currentTime_)
        internal pure returns (uint256 accruedAmount_)
    {
        accruedAmount_ = totalAccruingAmount_ * (currentTime_ - startTime_) / (endTime_ - startTime_);
    }

    function _getDefaultInterestAndFees(address loan_, PaymentInfo memory paymentInfo_)
        internal view returns (uint256 netInterest_, uint256 netLateInterest_, uint256 platformFees_)
    {
        // Calculate the accrued interest on the payment using IR to capture rounding errors.
        // Accrue the interest only up to the current time if the payment due date has not been reached yet.
        netInterest_ =
            paymentInfo_.issuanceRate == 0
                ? paymentInfo_.incomingNetInterest + paymentInfo_.refinanceInterest
                : _getPaymentAccruedInterest({
                    startTime_:           paymentInfo_.startDate,
                    endTime_:             _min(paymentInfo_.paymentDueDate, block.timestamp),
                    paymentIssuanceRate_: paymentInfo_.issuanceRate,
                    refinanceInterest_:   paymentInfo_.refinanceInterest
                });

        ( , uint256[3] memory grossInterest_, uint256[2] memory serviceFees_ ) = IMapleLoanLike(loan_).getNextPaymentDetailedBreakdown();

        uint256 grossLateInterest_ = grossInterest_[1];

        netLateInterest_ = _getNetInterest(
            grossLateInterest_,
            paymentInfo_.platformManagementFeeRate + paymentInfo_.delegateManagementFeeRate
        );

        // Calculate the platform management and service fees.
        uint256 platformManagementFees_ =
            ((grossInterest_[0] + grossLateInterest_ + grossInterest_[2]) * paymentInfo_.platformManagementFeeRate) / HUNDRED_PERCENT;

        // If the payment is early, scale back the management fees pro-rata based on the current timestamp.
        if (grossLateInterest_ == 0) {
            platformManagementFees_ = _getAccruedAmount(
                platformManagementFees_,
                paymentInfo_.startDate,
                paymentInfo_.paymentDueDate,
                block.timestamp
            );
        }

        platformFees_ = platformManagementFees_ + serviceFees_[1];
    }

    function _getInterestAndFeesFromLiquidationInfo(address loan_)
        internal view returns (uint256 netInterest_, uint256 netLateInterest_, uint256 platformFees_)
    {
        LiquidationInfo memory liquidationInfo_ = liquidationInfo[loan_];

        netInterest_     = liquidationInfo_.interest;
        netLateInterest_ = liquidationInfo_.lateInterest;
        platformFees_    = liquidationInfo_.platformFees;
    }

    function _getNetInterest(uint256 interest_, uint256 feeRate_) internal pure returns (uint256 netInterest_) {
        netInterest_ = interest_ * (HUNDRED_PERCENT - feeRate_) / HUNDRED_PERCENT;
    }

    function _getPaymentAccruedInterest(uint256 startTime_, uint256 endTime_, uint256 paymentIssuanceRate_, uint256 refinanceInterest_)
        internal pure returns (uint256 accruedInterest_)
    {
        accruedInterest_ = (endTime_ - startTime_) * paymentIssuanceRate_ / PRECISION + refinanceInterest_;
    }

    /**************************************************************************************************************************************/
    /*** Internal Payment Sorting Functions                                                                                             ***/
    /**************************************************************************************************************************************/

    function _addPaymentToList(uint48 paymentDueDate_) internal returns (uint24 paymentId_) {
        paymentId_ = ++paymentCounter;

        uint24 current_ = uint24(0);
        uint24 next_    = paymentWithEarliestDueDate;

        // Starting from the earliest payment, while the paymentDueDate is greater than the next payment in the list, keep iterating.
        while (next_ != 0 && paymentDueDate_ >= sortedPayments[next_].paymentDueDate) {
            current_ = next_;
            next_    = sortedPayments[current_].next;
        }

        // If the result is that this is the earliest payment, update the earliest payment pointer.
        // Else set the next pointer of the previous payment to the new id.
        if (current_ != 0) {
            sortedPayments[current_].next = paymentId_;
        } else {
            paymentWithEarliestDueDate = paymentId_;
        }

        // If the result is that this isn't the latest payment, update the previous pointer of the next payment to the new id.
        if (next_ != 0) {
            sortedPayments[next_].previous = paymentId_;
        }

        sortedPayments[paymentId_] = SortedPayment({ previous: current_, next: next_, paymentDueDate: paymentDueDate_ });
    }

    function _removePaymentFromList(uint256 paymentId_) internal {
        SortedPayment memory sortedPayment_ = sortedPayments[paymentId_];

        uint24 previous_ = sortedPayment_.previous;
        uint24 next_     = sortedPayment_.next;

        // If removing the earliest payment, update the earliest payment pointer.
        if (paymentWithEarliestDueDate == paymentId_) {
            paymentWithEarliestDueDate = next_;
        }

        // If not the last payment, update the previous pointer of the next payment.
        if (next_ != 0) {
            sortedPayments[next_].previous = previous_;
        }

        // If not the first payment, update the next pointer of the previous payment.
        if (previous_ != 0) {
            sortedPayments[previous_].next = next_;
        }

        delete sortedPayments[paymentId_];
    }

    /**************************************************************************************************************************************/
    /*** Loan Manager View Functions                                                                                                    ***/
    /**************************************************************************************************************************************/

    function accruedInterest() public view override returns (uint256 accruedInterest_) {
        uint256 issuanceRate_ = issuanceRate;

        // NOTE: Exit condition saves gas but also prevents underflow when `domainEnd` is zero.
        //       The explicit check was not added because of the bytecode size being too large.
        if (issuanceRate_ == 0) return uint256(0);

        // If before domain end, use current timestamp.
        accruedInterest_ = issuanceRate_ * (_min(block.timestamp, domainEnd) - domainStart) / PRECISION;
    }

    function assetsUnderManagement() public view virtual override returns (uint256 assetsUnderManagement_) {
        assetsUnderManagement_ = principalOut + accountedInterest + accruedInterest();
    }

    function getExpectedAmount(address collateralAsset_, uint256 swapAmount_) public view override returns (uint256 returnAmount_) {
        IMapleGlobalsLike globals_ = IMapleGlobalsLike(_globals());

        uint256 collateralAssetDecimals_ = uint256(10) ** uint256(IERC20Like(collateralAsset_).decimals());

        uint256 oracleAmount_ =
            swapAmount_
                * globals_.getLatestPrice(collateralAsset_)                  // Convert from `fromAsset` value.
                * uint256(10) ** uint256(IERC20Like(fundsAsset).decimals())  // Convert to `toAsset` decimal precision.
                * (HUNDRED_PERCENT - allowedSlippageFor[collateralAsset_])   // Multiply by allowed slippage basis points
                / globals_.getLatestPrice(fundsAsset)                        // Convert to `toAsset` value.
                / collateralAssetDecimals_                                   // Convert from `fromAsset` decimal precision.
                / HUNDRED_PERCENT;                                           // Divide basis points for slippage.

        uint256 minRatioAmount_ = (swapAmount_ * minRatioFor[collateralAsset_]) / collateralAssetDecimals_;

        returnAmount_ = oracleAmount_ > minRatioAmount_ ? oracleAmount_ : minRatioAmount_;
    }

    function isLiquidationActive(address loan_) public view override returns (bool isActive_) {
        address liquidatorAddress_ = liquidationInfo[loan_].liquidator;

        isActive_ = (liquidatorAddress_ != address(0)) && (ILiquidatorLike(liquidatorAddress_).collateralRemaining() != uint256(0));
    }

    /**************************************************************************************************************************************/
    /*** Protocol Address View Functions                                                                                                ***/
    /**************************************************************************************************************************************/

    function factory() external view override returns (address factory_) {
        factory_ = _factory();
    }

    function governor() public view returns (address governor_) {
        governor_ = IMapleGlobalsLike(_globals()).governor();
    }

    function implementation() external view override returns (address implementation_) {
        implementation_ = _implementation();
    }

    function poolDelegate() public view returns (address poolDelegate_) {
        poolDelegate_ = IPoolManagerLike(poolManager).poolDelegate();
    }

    /**************************************************************************************************************************************/
    /*** Internal View Functions                                                                                                        ***/
    /**************************************************************************************************************************************/

    function _globals() internal view returns (address globals_) {
        globals_ = IMapleProxyFactoryLike(_factory()).mapleGlobals();
    }

    function _pool() internal view returns (address pool_) {
        pool_ = IPoolManagerLike(poolManager).pool();
    }

    function _revertIfNotFactory() internal view {
        require(msg.sender == _factory(), "LM:NOT_FACTORY");
    }

    function _revertIfNotPoolDelegate() internal view {
        require(msg.sender == poolDelegate(), "LM:NOT_PD");
    }

    function _revertIfNotPoolDelegateOrGovernor() internal view {
        require(msg.sender == poolDelegate() || msg.sender == governor(), "LM:NOT_PD_OR_GOV");
    }

    function _revertIfNotPoolManager() internal view {
        require(msg.sender == poolManager, "LM:NOT_PM");
    }

    function _revertIfPaused() internal view {
        require(!IMapleGlobalsLike(_globals()).isFunctionPaused(msg.sig), "LM:PAUSED");
    }

    function _treasury() internal view returns (address treasury_) {
        treasury_ = IMapleGlobalsLike(_globals()).mapleTreasury();
    }

    /**************************************************************************************************************************************/
    /*** Internal Pure Utility Functions                                                                                                ***/
    /**************************************************************************************************************************************/

    function _min(uint256 a_, uint256 b_) internal pure returns (uint256 minimum_) {
        minimum_ = a_ < b_ ? a_ : b_;
    }

    function _uint24(uint256 input_) internal pure returns (uint24 output_) {
        require(input_ <= type(uint24).max, "LM:UINT24");
        output_ = uint24(input_);
    }

    function _uint48(uint256 input_) internal pure returns (uint48 output_) {
        require(input_ <= type(uint48).max, "LM:UINT48");
        output_ = uint48(input_);
    }

    function _uint96(uint256 input_) internal pure returns (uint96 output_) {
        require(input_ <= type(uint96).max, "LM:UINT96");
        output_ = uint96(input_);
    }

    function _uint112(uint256 input_) internal pure returns (uint112 output_) {
        require(input_ <= type(uint112).max, "LM:UINT112");
        output_ = uint112(input_);
    }

    function _uint120(uint256 input_) internal pure returns (uint120 output_) {
        require(input_ <= type(uint120).max, "LM:UINT120");
        output_ = uint120(input_);
    }

    function _uint128(uint256 input_) internal pure returns (uint128 output_) {
        require(input_ <= type(uint128).max, "LM:UINT128");
        output_ = uint128(input_);
    }

}
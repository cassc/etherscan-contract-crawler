// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.8.19;

import {IERC20Metadata} from "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import {Initializable} from "@openzeppelin/contracts/proxy/utils/Initializable.sol";
import {SafeCast} from "@openzeppelin/contracts/utils/math/SafeCast.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {Constants} from "../Constants.sol";
import {DataTypesPeerToPool} from "./DataTypesPeerToPool.sol";
import {Errors} from "../Errors.sol";
import {IFactory} from "./interfaces/IFactory.sol";
import {IFundingPoolImpl} from "./interfaces/IFundingPoolImpl.sol";
import {ILoanProposalImpl} from "./interfaces/ILoanProposalImpl.sol";
import {IMysoTokenManager} from "../interfaces/IMysoTokenManager.sol";

/**
 * Loan Proposal Process:
 *
 * 1) Arranger initiates the loan proposal
 *    - Function: factory.createLoanProposal()
 *
 * 2) Arranger adjusts loan terms
 *    - Function: loanProposal.lockLoanTerms()
 *    - NOTE: This triggers a cool-off period during which the arranger cannot modify loan terms.
 *    - Lenders can subscribe or unsubscribe at any time during this phase.
 *      - Functions: fundingPool.subscribe(), fundingPool.unsubscribe()
 *
 * 3) Arranger (or borrower) finalizes the loan terms
 *    3.1) This action triggers a subscribe/unsubscribe grace period, during which lenders can still subscribe/unsubscribe.
 *         - Functions: fundingPool.subscribe(), fundingPool.unsubscribe()
 *    3.2) After the grace period, a loan execution grace period begins.
 *
 * 4) Borrower finalizes the loan terms and transfers collateral within the loan execution grace period.
 *    - Function: loanProposal.finalizeLoanTermsAndTransferColl()
 *    - NOTE: This must be done within the loan execution grace period.
 *
 * 5) The loan proposal execution can be triggered by anyone, concluding the process.
 */
contract LoanProposalImpl is Initializable, ILoanProposalImpl {
    using SafeERC20 for IERC20Metadata;

    mapping(uint256 => uint256) public totalConvertedSubscriptionsPerIdx; // denominated in loan Token
    mapping(uint256 => uint256) public collTokenConverted;
    DataTypesPeerToPool.DynamicLoanProposalData public dynamicData;
    DataTypesPeerToPool.StaticLoanProposalData public staticData;
    uint256 public lastLoanTermsUpdateTime;
    uint256 internal _totalSubscriptionsThatClaimedOnDefault;
    mapping(address => mapping(uint256 => bool))
        internal _lenderExercisedConversion;
    mapping(address => mapping(uint256 => bool))
        internal _lenderClaimedRepayment;
    mapping(address => bool) internal _lenderClaimedCollateralOnDefault;
    DataTypesPeerToPool.LoanTerms internal _loanTerms;
    mapping(uint256 => uint256) internal _loanTokenRepaid;

    constructor() {
        _disableInitializers();
    }

    function initialize(
        address _factory,
        address _arranger,
        address _fundingPool,
        address _collToken,
        address _whitelistAuthority,
        uint256 _arrangerFee,
        uint256 _unsubscribeGracePeriod,
        uint256 _conversionGracePeriod,
        uint256 _repaymentGracePeriod
    ) external initializer {
        if (_arrangerFee > Constants.MAX_ARRANGER_FEE) {
            revert Errors.InvalidFee();
        }
        if (
            _unsubscribeGracePeriod < Constants.MIN_UNSUBSCRIBE_GRACE_PERIOD ||
            _unsubscribeGracePeriod > Constants.MAX_UNSUBSCRIBE_GRACE_PERIOD ||
            _conversionGracePeriod < Constants.MIN_CONVERSION_GRACE_PERIOD ||
            _repaymentGracePeriod < Constants.MIN_REPAYMENT_GRACE_PERIOD ||
            _conversionGracePeriod + _repaymentGracePeriod >
            Constants.MAX_CONVERSION_AND_REPAYMENT_GRACE_PERIOD
        ) {
            revert Errors.InvalidGracePeriod();
        }
        // @dev: staticData struct fields don't change after initialization
        staticData.factory = _factory;
        staticData.fundingPool = _fundingPool;
        staticData.collToken = _collToken;
        staticData.arranger = _arranger;
        if (_whitelistAuthority != address(0)) {
            staticData.whitelistAuthority = _whitelistAuthority;
        }
        staticData.unsubscribeGracePeriod = _unsubscribeGracePeriod;
        staticData.conversionGracePeriod = _conversionGracePeriod;
        staticData.repaymentGracePeriod = _repaymentGracePeriod;
        // @dev: dynamicData struct fields are overwritten later when converting from
        // relative to absolute amounts
        dynamicData.arrangerFee = _arrangerFee;
        dynamicData.protocolFee = IFactory(_factory).protocolFee();
    }

    function updateLoanTerms(
        DataTypesPeerToPool.LoanTerms calldata newLoanTerms
    ) external {
        _checkIsAuthorizedSender(staticData.arranger);
        DataTypesPeerToPool.LoanStatus status = dynamicData.status;
        if (
            status != DataTypesPeerToPool.LoanStatus.WITHOUT_LOAN_TERMS &&
            status != DataTypesPeerToPool.LoanStatus.IN_NEGOTIATION
        ) {
            revert Errors.InvalidActionForCurrentStatus();
        }
        // @dev: enforce loan-terms-update-cool-off-period to prevent borrower from being spammed by frequent
        // loan proposal updates, which otherwise could create friction for borrower when trying to lock in terms
        if (
            block.timestamp <
            lastLoanTermsUpdateTime +
                Constants.LOAN_TERMS_UPDATE_COOL_OFF_PERIOD
        ) {
            revert Errors.WaitForLoanTermsCoolOffPeriod();
        }
        if (
            newLoanTerms.minTotalSubscriptions == 0 ||
            newLoanTerms.minTotalSubscriptions >
            newLoanTerms.maxTotalSubscriptions
        ) {
            revert Errors.InvalidSubscriptionRange();
        }
        address fundingPool = staticData.fundingPool;
        _repaymentScheduleCheck(
            newLoanTerms.minTotalSubscriptions,
            newLoanTerms.repaymentSchedule
        );
        uint256 totalSubscriptions = IFundingPoolImpl(fundingPool)
            .totalSubscriptions(address(this));
        if (totalSubscriptions > newLoanTerms.maxTotalSubscriptions) {
            revert Errors.InvalidMaxTotalSubscriptions();
        }
        _loanTerms = newLoanTerms;
        if (status != DataTypesPeerToPool.LoanStatus.IN_NEGOTIATION) {
            dynamicData.status = DataTypesPeerToPool.LoanStatus.IN_NEGOTIATION;
        }
        lastLoanTermsUpdateTime = block.timestamp;
        emit LoanTermsProposed(newLoanTerms);
    }

    function lockLoanTerms(uint256 _loanTermsUpdateTime) external {
        if (
            msg.sender != staticData.arranger &&
            msg.sender != _loanTerms.borrower
        ) {
            revert Errors.InvalidSender();
        }
        _checkStatus(DataTypesPeerToPool.LoanStatus.IN_NEGOTIATION);
        // @dev: check if "remaining" time until first due date is "sufficiently"
        // far enough in the future
        if (
            _loanTerms.repaymentSchedule[0].dueTimestamp <
            block.timestamp +
                staticData.unsubscribeGracePeriod +
                Constants.LOAN_EXECUTION_GRACE_PERIOD +
                Constants.MIN_TIME_UNTIL_FIRST_DUE_DATE
        ) {
            revert Errors.FirstDueDateTooCloseOrPassed();
        }
        if (_loanTermsUpdateTime != lastLoanTermsUpdateTime) {
            revert Errors.InconsistentLastLoanTermsUpdateTime();
        }
        dynamicData.loanTermsLockedTime = block.timestamp;
        dynamicData.status = DataTypesPeerToPool.LoanStatus.LOAN_TERMS_LOCKED;

        emit LoanTermsLocked();
    }

    function finalizeLoanTermsAndTransferColl(
        uint256 expectedTransferFee,
        bytes calldata mysoTokenManagerData
    ) external {
        _checkIsAuthorizedSender(_loanTerms.borrower);
        // revert if loan terms are locked or lender cutoff time hasn't passed yet
        if (
            dynamicData.status !=
            DataTypesPeerToPool.LoanStatus.LOAN_TERMS_LOCKED ||
            block.timestamp < _lenderInOrOutCutoffTime() ||
            block.timestamp >
            _lenderInOrOutCutoffTime() + Constants.LOAN_EXECUTION_GRACE_PERIOD
        ) {
            revert Errors.InvalidActionForCurrentStatus();
        }
        address fundingPool = staticData.fundingPool;
        uint256 totalSubscriptions = IFundingPoolImpl(fundingPool)
            .totalSubscriptions(address(this));
        DataTypesPeerToPool.LoanTerms memory _unfinalizedLoanTerms = _loanTerms;
        if (totalSubscriptions < _unfinalizedLoanTerms.minTotalSubscriptions) {
            revert Errors.FellShortOfTotalSubscriptionTarget();
        }

        dynamicData.status = DataTypesPeerToPool.LoanStatus.READY_TO_EXECUTE;
        // note: now that final subscription amounts are known, convert relative values
        // to absolute, i.e.:
        // i) loanTokenDue from relative (e.g., 25% of final loan amount) to absolute (e.g., 25 USDC),
        // ii) collTokenDueIfConverted from relative (e.g., convert every
        // 1 loanToken for 8 collToken) to absolute (e.g., 200 collToken)
        (
            DataTypesPeerToPool.LoanTerms memory _finalizedLoanTerms,
            uint256[2] memory collAmounts,
            uint256[2] memory fees
        ) = getAbsoluteLoanTerms(
                _unfinalizedLoanTerms,
                totalSubscriptions,
                IERC20Metadata(IFundingPoolImpl(fundingPool).depositToken())
                    .decimals()
            );
        for (uint256 i; i < _finalizedLoanTerms.repaymentSchedule.length; ) {
            _loanTerms.repaymentSchedule[i].loanTokenDue = _finalizedLoanTerms
                .repaymentSchedule[i]
                .loanTokenDue;
            _loanTerms
                .repaymentSchedule[i]
                .collTokenDueIfConverted = _finalizedLoanTerms
                .repaymentSchedule[i]
                .collTokenDueIfConverted;
            unchecked {
                ++i;
            }
        }
        dynamicData.arrangerFee = fees[0];
        dynamicData.protocolFee = fees[1];
        dynamicData.grossLoanAmount = totalSubscriptions;
        dynamicData.finalCollAmountReservedForDefault = collAmounts[0];
        dynamicData.finalCollAmountReservedForConversions = collAmounts[1];
        address mysoTokenManager = IFactory(staticData.factory)
            .mysoTokenManager();
        if (mysoTokenManager != address(0)) {
            IMysoTokenManager(mysoTokenManager).processP2PoolLoanFinalization(
                address(this),
                fundingPool,
                staticData.arranger,
                msg.sender,
                totalSubscriptions,
                mysoTokenManagerData
            );
        }

        // note: final collToken amount that borrower needs to transfer is sum of:
        // 1) amount reserved for lenders in case of default, and
        // 2) amount reserved for lenders in case all convert
        address collToken = staticData.collToken;
        uint256 preBal = IERC20Metadata(collToken).balanceOf(address(this));
        IERC20Metadata(collToken).safeTransferFrom(
            msg.sender,
            address(this),
            collAmounts[0] + collAmounts[1] + expectedTransferFee
        );
        if (
            IERC20Metadata(collToken).balanceOf(address(this)) !=
            preBal + collAmounts[0] + collAmounts[1]
        ) {
            revert Errors.InvalidSendAmount();
        }

        emit LoanTermsAndTransferCollFinalized(
            totalSubscriptions,
            collAmounts,
            fees
        );
    }

    function rollback() external {
        // @dev: cannot be called anymore once finalizeLoanTermsAndTransferColl() called
        _checkStatus(DataTypesPeerToPool.LoanStatus.LOAN_TERMS_LOCKED);
        uint256 totalSubscriptions = IFundingPoolImpl(staticData.fundingPool)
            .totalSubscriptions(address(this));
        uint256 lenderInOrOutCutoffTime = _lenderInOrOutCutoffTime();
        if (
            msg.sender == _loanTerms.borrower ||
            msg.sender == staticData.arranger ||
            (block.timestamp >= lenderInOrOutCutoffTime &&
                totalSubscriptions < _loanTerms.minTotalSubscriptions) ||
            (block.timestamp >=
                lenderInOrOutCutoffTime + Constants.LOAN_EXECUTION_GRACE_PERIOD)
        ) {
            dynamicData.status = DataTypesPeerToPool.LoanStatus.ROLLBACK;
        } else {
            revert Errors.InvalidRollBackRequest();
        }

        emit Rolledback(msg.sender);
    }

    function checkAndUpdateStatus() external {
        _checkIsAuthorizedSender(staticData.fundingPool);
        _checkStatus(DataTypesPeerToPool.LoanStatus.READY_TO_EXECUTE);
        dynamicData.status = DataTypesPeerToPool.LoanStatus.LOAN_DEPLOYED;

        emit LoanDeployed();
    }

    function exerciseConversion() external {
        (, uint256 lenderContribution) = _checkIsLender();
        _checkStatus(DataTypesPeerToPool.LoanStatus.LOAN_DEPLOYED);
        uint256 repaymentIdx = _checkAndGetCurrRepaymentIdx();
        mapping(uint256 => bool)
            storage lenderExercisedConversionPerRepaymentIdx = _lenderExercisedConversion[
                msg.sender
            ];
        if (lenderExercisedConversionPerRepaymentIdx[repaymentIdx]) {
            revert Errors.AlreadyConverted();
        }
        // must be after when the period of this loan is due, but before borrower can repay
        // note: conversion can be done if blocktime is in the half-open interval of:
        // [dueTimestamp, dueTimestamp + conversionGracePeriod)
        DataTypesPeerToPool.Repayment memory _repayment = _loanTerms
            .repaymentSchedule[repaymentIdx];
        if (
            block.timestamp < _repayment.dueTimestamp ||
            block.timestamp >=
            _repayment.dueTimestamp + staticData.conversionGracePeriod
        ) {
            revert Errors.OutsideConversionTimeWindow();
        }
        uint256 totalConvertedSubscriptions = totalConvertedSubscriptionsPerIdx[
            repaymentIdx
        ];
        uint256 conversionAmount;
        address collToken = staticData.collToken;
        if (
            dynamicData.grossLoanAmount ==
            totalConvertedSubscriptions + lenderContribution
        ) {
            // Note: case where "last lender" converts
            // @dev: use remainder (rather than pro-rata) to mitigate potential rounding errors
            conversionAmount =
                _repayment.collTokenDueIfConverted -
                collTokenConverted[repaymentIdx];
            ++dynamicData.currentRepaymentIdx;
            // @dev: increment repayment idx (no need to do repay with 0 amount)
            if (_loanTerms.repaymentSchedule.length == repaymentIdx + 1) {
                // @dev: if "last lender" converts in last period then send remaining collateral back to borrower
                IERC20Metadata(collToken).safeTransfer(
                    _loanTerms.borrower,
                    IERC20Metadata(collToken).balanceOf(address(this)) -
                        conversionAmount
                );
            }
        } else {
            // Note: all other cases
            // @dev: distribute collateral token on pro-rata basis
            conversionAmount =
                (_repayment.collTokenDueIfConverted * lenderContribution) /
                dynamicData.grossLoanAmount;
        }
        if (conversionAmount == 0) {
            revert Errors.ZeroConversionAmount();
        }
        collTokenConverted[repaymentIdx] += conversionAmount;
        totalConvertedSubscriptionsPerIdx[repaymentIdx] += lenderContribution;
        lenderExercisedConversionPerRepaymentIdx[repaymentIdx] = true;
        IERC20Metadata(collToken).safeTransfer(msg.sender, conversionAmount);

        emit ConversionExercised(msg.sender, conversionAmount, repaymentIdx);
    }

    function repay(uint256 expectedTransferFee) external {
        _checkIsAuthorizedSender(_loanTerms.borrower);
        _checkStatus(DataTypesPeerToPool.LoanStatus.LOAN_DEPLOYED);
        uint256 repaymentIdx = _checkAndGetCurrRepaymentIdx();
        // must be after when the period of this loan when lenders can convert,
        // but before default period for this period
        // note: repayment can be done in the half-open interval of:
        // [dueTimestamp + conversionGracePeriod, dueTimestamp + conversionGracePeriod + repaymentGracePeriod)
        DataTypesPeerToPool.Repayment memory _repayment = _loanTerms
            .repaymentSchedule[repaymentIdx];
        uint256 currConversionCutoffTime = _repayment.dueTimestamp +
            staticData.conversionGracePeriod;
        uint256 currRepaymentCutoffTime = currConversionCutoffTime +
            staticData.repaymentGracePeriod;
        if (
            (block.timestamp < currConversionCutoffTime) ||
            (block.timestamp >= currRepaymentCutoffTime)
        ) {
            revert Errors.OutsideRepaymentTimeWindow();
        }
        address fundingPool = staticData.fundingPool;
        address loanToken = IFundingPoolImpl(fundingPool).depositToken();
        uint256 collTokenLeftUnconverted = _repayment.collTokenDueIfConverted -
            collTokenConverted[repaymentIdx];
        uint256 remainingLoanTokenDue = (_repayment.loanTokenDue *
            collTokenLeftUnconverted) / _repayment.collTokenDueIfConverted;
        _loanTokenRepaid[repaymentIdx] = remainingLoanTokenDue;
        ++dynamicData.currentRepaymentIdx;

        uint256 preBal = IERC20Metadata(loanToken).balanceOf(address(this));
        if (remainingLoanTokenDue + expectedTransferFee > 0) {
            IERC20Metadata(loanToken).safeTransferFrom(
                msg.sender,
                address(this),
                remainingLoanTokenDue + expectedTransferFee
            );
            if (
                IERC20Metadata(loanToken).balanceOf(address(this)) !=
                remainingLoanTokenDue + preBal
            ) {
                revert Errors.InvalidSendAmount();
            }
        }

        // if final repayment, send all remaining coll token back to borrower
        // else send only unconverted coll token back to borrower
        address collToken = staticData.collToken;
        uint256 collSendAmount = _loanTerms.repaymentSchedule.length ==
            repaymentIdx + 1
            ? IERC20Metadata(collToken).balanceOf(address(this))
            : collTokenLeftUnconverted;
        if (collSendAmount > 0) {
            IERC20Metadata(collToken).safeTransfer(msg.sender, collSendAmount);
        }

        emit Repaid(remainingLoanTokenDue, collSendAmount, repaymentIdx);
    }

    function claimRepayment(uint256 repaymentIdx) external {
        (address fundingPool, uint256 lenderContribution) = _checkIsLender();
        // the currentRepaymentIdx (initially 0) gets incremented on repay or if all lenders converted for given period;
        // hence any `repaymentIdx` smaller than `currentRepaymentIdx` will always map to a valid repayment claim
        if (repaymentIdx >= dynamicData.currentRepaymentIdx) {
            revert Errors.RepaymentIdxTooLarge();
        }
        DataTypesPeerToPool.LoanStatus status = dynamicData.status;
        if (
            status != DataTypesPeerToPool.LoanStatus.LOAN_DEPLOYED &&
            status != DataTypesPeerToPool.LoanStatus.DEFAULTED
        ) {
            revert Errors.InvalidActionForCurrentStatus();
        }
        // note: users can claim as soon as repaid, no need to check _getRepaymentCutoffTime(...)
        mapping(uint256 => bool)
            storage lenderClaimedRepaymentPerRepaymentIdx = _lenderClaimedRepayment[
                msg.sender
            ];
        if (
            lenderClaimedRepaymentPerRepaymentIdx[repaymentIdx] ||
            _lenderExercisedConversion[msg.sender][repaymentIdx]
        ) {
            revert Errors.AlreadyClaimed();
        }
        // repaid amount for that period split over those who didn't convert in that period
        uint256 subscriptionsEntitledToRepayment = dynamicData.grossLoanAmount -
            totalConvertedSubscriptionsPerIdx[repaymentIdx];
        uint256 claimAmount = (_loanTokenRepaid[repaymentIdx] *
            lenderContribution) / subscriptionsEntitledToRepayment;
        lenderClaimedRepaymentPerRepaymentIdx[repaymentIdx] = true;
        IERC20Metadata(IFundingPoolImpl(fundingPool).depositToken())
            .safeTransfer(msg.sender, claimAmount);

        emit RepaymentClaimed(msg.sender, claimAmount, repaymentIdx);
    }

    function markAsDefaulted() external {
        _checkStatus(DataTypesPeerToPool.LoanStatus.LOAN_DEPLOYED);
        // this will check if loan has been fully repaid yet in this instance
        // note: loan can be marked as defaulted if no repayment and blocktime is in half-open interval of:
        // [dueTimestamp + conversionGracePeriod + repaymentGracePeriod, infty)
        uint256 repaymentIdx = _checkAndGetCurrRepaymentIdx();
        if (block.timestamp < _getRepaymentCutoffTime(repaymentIdx)) {
            revert Errors.NoDefault();
        }
        dynamicData.status = DataTypesPeerToPool.LoanStatus.DEFAULTED;
        emit LoanDefaulted();
    }

    function claimDefaultProceeds() external {
        _checkStatus(DataTypesPeerToPool.LoanStatus.DEFAULTED);
        (, uint256 lenderContribution) = _checkIsLender();
        if (_lenderClaimedCollateralOnDefault[msg.sender]) {
            revert Errors.AlreadyClaimed();
        }
        uint256 lastPeriodIdx = dynamicData.currentRepaymentIdx;
        address collToken = staticData.collToken;
        uint256 totalSubscriptions = dynamicData.grossLoanAmount;
        uint256 stillToBeConvertedCollTokens = _loanTerms
            .repaymentSchedule[lastPeriodIdx]
            .collTokenDueIfConverted - collTokenConverted[lastPeriodIdx];

        // if only some lenders converted, then split 'stillToBeConvertedCollTokens'
        // fairly among lenders who didn't already convert in default period to not
        // put them at an unfair disadvantage
        uint256 totalUnconvertedSubscriptionsFromLastIdx = totalSubscriptions -
            totalConvertedSubscriptionsPerIdx[lastPeriodIdx];
        uint256 totalCollTokenClaim;
        if (!_lenderExercisedConversion[msg.sender][lastPeriodIdx]) {
            totalCollTokenClaim =
                (stillToBeConvertedCollTokens * lenderContribution) /
                totalUnconvertedSubscriptionsFromLastIdx;
            collTokenConverted[lastPeriodIdx] += totalCollTokenClaim;
            totalConvertedSubscriptionsPerIdx[
                lastPeriodIdx
            ] += lenderContribution;
            _lenderExercisedConversion[msg.sender][lastPeriodIdx] = true;
        }
        // determine pro-rata share on remaining non-conversion related collToken balance
        totalCollTokenClaim +=
            ((IERC20Metadata(collToken).balanceOf(address(this)) -
                stillToBeConvertedCollTokens) * lenderContribution) /
            (totalSubscriptions - _totalSubscriptionsThatClaimedOnDefault);
        if (totalCollTokenClaim == 0) {
            revert Errors.AlreadyClaimed();
        }
        _lenderClaimedCollateralOnDefault[msg.sender] = true;
        _totalSubscriptionsThatClaimedOnDefault += lenderContribution;
        IERC20Metadata(collToken).safeTransfer(msg.sender, totalCollTokenClaim);

        emit DefaultProceedsClaimed(msg.sender);
    }

    function loanTerms()
        external
        view
        returns (DataTypesPeerToPool.LoanTerms memory)
    {
        return _loanTerms;
    }

    function canUnsubscribe() external view returns (bool) {
        return
            canSubscribe() ||
            dynamicData.status == DataTypesPeerToPool.LoanStatus.ROLLBACK;
    }

    function canSubscribe() public view returns (bool) {
        DataTypesPeerToPool.LoanStatus status = dynamicData.status;
        return (status == DataTypesPeerToPool.LoanStatus.IN_NEGOTIATION ||
            (status == DataTypesPeerToPool.LoanStatus.LOAN_TERMS_LOCKED &&
                block.timestamp < _lenderInOrOutCutoffTime()));
    }

    function getAbsoluteLoanTerms(
        DataTypesPeerToPool.LoanTerms memory _tmpLoanTerms,
        uint256 totalSubscriptions,
        uint256 loanTokenDecimals
    )
        public
        view
        returns (
            DataTypesPeerToPool.LoanTerms memory,
            uint256[2] memory collAmounts,
            uint256[2] memory fees
        )
    {
        uint256 _arrangerFee = (dynamicData.arrangerFee * totalSubscriptions) /
            Constants.BASE;
        uint256 _protocolFee = (dynamicData.protocolFee * totalSubscriptions) /
            Constants.BASE;
        uint256 _finalCollAmountReservedForDefault = (totalSubscriptions *
            _tmpLoanTerms.collPerLoanToken) / (10 ** loanTokenDecimals);
        // note: convert relative terms into absolute values, i.e.:
        // i) loanTokenDue relative to grossLoanAmount (e.g., 25% of final loan amount),
        // ii) collTokenDueIfConverted relative to loanTokenDue (e.g., convert every
        // 1 loanToken for 8 collToken)
        uint256 _finalCollAmountReservedForConversions;
        for (uint256 i; i < _tmpLoanTerms.repaymentSchedule.length; ) {
            _tmpLoanTerms.repaymentSchedule[i].loanTokenDue = SafeCast
                .toUint128(
                    (totalSubscriptions *
                        _tmpLoanTerms.repaymentSchedule[i].loanTokenDue) /
                        Constants.BASE
                );
            _tmpLoanTerms
                .repaymentSchedule[i]
                .collTokenDueIfConverted = SafeCast.toUint128(
                (_tmpLoanTerms.repaymentSchedule[i].loanTokenDue *
                    _tmpLoanTerms
                        .repaymentSchedule[i]
                        .collTokenDueIfConverted) / (10 ** loanTokenDecimals)
            );
            _finalCollAmountReservedForConversions += _tmpLoanTerms
                .repaymentSchedule[i]
                .collTokenDueIfConverted;
            unchecked {
                ++i;
            }
        }
        return (
            _tmpLoanTerms,
            [
                _finalCollAmountReservedForDefault,
                _finalCollAmountReservedForConversions
            ],
            [_arrangerFee, _protocolFee]
        );
    }

    function _checkAndGetCurrRepaymentIdx()
        internal
        view
        returns (uint256 currRepaymentIdx)
    {
        // @dev: currentRepaymentIdx increments on every repay or if all lenders converted in a given period;
        // if and only if loan was fully repaid, then currentRepaymentIdx == _loanTerms.repaymentSchedule.length
        currRepaymentIdx = dynamicData.currentRepaymentIdx;
        if (currRepaymentIdx == _loanTerms.repaymentSchedule.length) {
            revert Errors.LoanIsFullyRepaid();
        }
    }

    function _lenderInOrOutCutoffTime() internal view returns (uint256) {
        return
            dynamicData.loanTermsLockedTime + staticData.unsubscribeGracePeriod;
    }

    function _repaymentScheduleCheck(
        uint256 minTotalSubscriptions,
        DataTypesPeerToPool.Repayment[] memory repaymentSchedule
    ) internal view {
        uint256 repaymentScheduleLen = repaymentSchedule.length;
        if (
            repaymentScheduleLen == 0 ||
            repaymentScheduleLen > Constants.MAX_REPAYMENT_SCHEDULE_LENGTH
        ) {
            revert Errors.InvalidRepaymentScheduleLength();
        }
        // @dev: assuming loan terms are directly locked, then loan can get executed earliest after:
        // block.timestamp + unsubscribeGracePeriod + Constants.LOAN_EXECUTION_GRACE_PERIOD
        if (
            repaymentSchedule[0].dueTimestamp <
            block.timestamp +
                staticData.unsubscribeGracePeriod +
                Constants.LOAN_EXECUTION_GRACE_PERIOD +
                Constants.MIN_TIME_UNTIL_FIRST_DUE_DATE
        ) {
            revert Errors.FirstDueDateTooCloseOrPassed();
        }
        // @dev: the minimum time required between due dates is
        // max{ MIN_TIME_BETWEEN_DUE_DATES, conversion + repayment grace period }
        uint256 minTimeBetweenDueDates = _getConversionAndRepaymentGracePeriod();
        minTimeBetweenDueDates = minTimeBetweenDueDates >
            Constants.MIN_TIME_BETWEEN_DUE_DATES
            ? minTimeBetweenDueDates
            : Constants.MIN_TIME_BETWEEN_DUE_DATES;
        for (uint256 i; i < repaymentScheduleLen; ) {
            if (
                SafeCast.toUint128(
                    (repaymentSchedule[i].loanTokenDue *
                        minTotalSubscriptions) / Constants.BASE
                ) == 0
            ) {
                revert Errors.LoanTokenDueIsZero();
            }
            if (
                i > 0 &&
                repaymentSchedule[i].dueTimestamp <
                repaymentSchedule[i - 1].dueTimestamp + minTimeBetweenDueDates
            ) {
                revert Errors.InvalidDueDates();
            }
            unchecked {
                ++i;
            }
        }
    }

    function _getRepaymentCutoffTime(
        uint256 repaymentIdx
    ) internal view returns (uint256 repaymentCutoffTime) {
        repaymentCutoffTime =
            _loanTerms.repaymentSchedule[repaymentIdx].dueTimestamp +
            _getConversionAndRepaymentGracePeriod();
    }

    function _getConversionAndRepaymentGracePeriod()
        internal
        view
        returns (uint256)
    {
        return
            staticData.conversionGracePeriod + staticData.repaymentGracePeriod;
    }

    function _checkIsAuthorizedSender(address authorizedSender) internal view {
        if (msg.sender != authorizedSender) {
            revert Errors.InvalidSender();
        }
    }

    function _checkIsLender()
        internal
        view
        returns (address fundingPool, uint256 lenderContribution)
    {
        fundingPool = staticData.fundingPool;
        lenderContribution = IFundingPoolImpl(fundingPool).subscriptionAmountOf(
            address(this),
            msg.sender
        );
        if (lenderContribution == 0) {
            revert Errors.InvalidSender();
        }
    }

    function _checkStatus(DataTypesPeerToPool.LoanStatus status) internal view {
        if (dynamicData.status != status) {
            revert Errors.InvalidActionForCurrentStatus();
        }
    }
}
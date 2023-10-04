// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.8.19;

import {DataTypesPeerToPool} from "../DataTypesPeerToPool.sol";

interface ILoanProposalImpl {
    event LoanTermsProposed(DataTypesPeerToPool.LoanTerms loanTerms);
    event LoanTermsLocked();
    event LoanTermsAndTransferCollFinalized(
        uint256 grossLoanAmount,
        uint256[2] collAmounts,
        uint256[2] fees
    );
    event Rolledback(address sender);
    event LoanDeployed();
    event ConversionExercised(
        address indexed sender,
        uint256 amount,
        uint256 repaymentIdx
    );
    event RepaymentClaimed(
        address indexed sender,
        uint256 amount,
        uint256 repaymentIdx
    );
    event Repaid(
        uint256 remainingLoanTokenDue,
        uint256 collTokenLeftUnconverted,
        uint256 repaymentIdx
    );
    event LoanDefaulted();
    event DefaultProceedsClaimed(address indexed sender);

    /**
     * @notice Initializes loan proposal
     * @param _factory Address of the factory contract from which proposal is created
     * @param _arranger Address of the arranger of the proposal
     * @param _fundingPool Address of the funding pool to be used to source liquidity, if successful
     * @param _collToken Address of collateral token to be used in loan
     * @param _whitelistAuthority Address of whitelist authority who can manage the lender whitelist (optional)
     * @param _arrangerFee Arranger fee in percent (where 100% = BASE)
     * @param _unsubscribeGracePeriod The unsubscribe grace period, i.e., after a loan gets accepted by the borrower 
     lenders can still unsubscribe for this time period before being locked-in
     * @param _conversionGracePeriod The grace period during which lenders can convert
     * @param _repaymentGracePeriod The grace period during which borrowers can repay
     */
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
    ) external;

    /**
     * @notice Propose new loan terms
     * @param newLoanTerms The new loan terms
     * @dev Can only be called by the arranger
     */
    function updateLoanTerms(
        DataTypesPeerToPool.LoanTerms calldata newLoanTerms
    ) external;

    /**
     * @notice Lock loan terms
     * @param loanTermsUpdateTime The timestamp at which loan terms are locked
     * @dev Can only be called by the arranger or borrower
     */
    function lockLoanTerms(uint256 loanTermsUpdateTime) external;

    /**
     * @notice Finalize the loan terms and transfer final collateral amount
     * @param expectedTransferFee The expected transfer fee (if any) of the collateral token
     * @param mysoTokenManagerData Data to be passed to MysoTokenManager
     * @dev Can only be called by the borrower
     */
    function finalizeLoanTermsAndTransferColl(
        uint256 expectedTransferFee,
        bytes calldata mysoTokenManagerData
    ) external;

    /**
     * @notice Rolls back the loan proposal
     * @dev Can be called by borrower during the unsubscribe grace period or by anyone in case the total totalSubscriptions fell below the minTotalSubscriptions
     */
    function rollback() external;

    /**
     * @notice Checks and updates the status of the loan proposal from 'READY_TO_EXECUTE' to 'LOAN_DEPLOYED'
     * @dev Can only be called by funding pool in conjunction with executing the loan proposal and settling amounts, i.e., sending loan amount to borrower and fees
     */
    function checkAndUpdateStatus() external;

    /**
     * @notice Allows lenders to exercise their conversion right for given repayment period
     * @dev Can only be called by entitled lenders and during conversion grace period of given repayment period
     */
    function exerciseConversion() external;

    /**
     * @notice Allows borrower to repay
     * @param expectedTransferFee The expected transfer fee (if any) of the loan token
     * @dev Can only be called by borrower and during repayment grace period of given repayment period. If borrower doesn't repay in time the loan can be marked as defaulted and borrowers loses control over pledged collateral. Note that the repayment amount can be lower than the loanTokenDue if lenders convert (potentially 0 if all convert, in which case borrower still needs to call the repay function to not default). Also note that on repay any unconverted collateral token reserved for conversions for that period get transferred back to borrower.
     */
    function repay(uint256 expectedTransferFee) external;

    /**
     * @notice Allows lenders to claim any repayments for given repayment period
     * @param repaymentIdx the given repayment period index
     * @dev Can only be called by entitled lenders and if they didn't make use of their conversion right
     */
    function claimRepayment(uint256 repaymentIdx) external;

    /**
     * @notice Marks loan proposal as defaulted
     * @dev Can be called by anyone but only if borrower failed to repay during repayment grace period
     */
    function markAsDefaulted() external;

    /**
     * @notice Allows lenders to claim default proceeds
     * @dev Can only be called if borrower defaulted and loan proposal was marked as defaulted; default proceeds are whatever is left in collateral token in loan proposal contract; proceeds are splitted among all lenders taking into account any conversions lenders already made during the default period.
     */
    function claimDefaultProceeds() external;

    /**
     * @notice Returns the amount of subscriptions that converted for given repayment period
     * @param repaymentIdx The respective repayment index of given period
     * @return The total amount of subscriptions that converted for given repayment period
     */
    function totalConvertedSubscriptionsPerIdx(
        uint256 repaymentIdx
    ) external view returns (uint256);

    /**
     * @notice Returns the amount of collateral tokens that were converted during given repayment period
     * @param repaymentIdx The respective repayment index of given period
     * @return The total amount of collateral tokens that were converted during given repayment period
     */
    function collTokenConverted(
        uint256 repaymentIdx
    ) external view returns (uint256);

    /**
     * @notice Returns core dynamic data for given loan proposal
     * @return arrangerFee The arranger fee, which initially is expressed in relative terms (i.e., 100% = BASE) and once the proposal gets finalized is in absolute terms (e.g., 1000 USDC)
     * @return grossLoanAmount The final loan amount, which initially is zero and gets set once the proposal gets finalized
     * @return finalCollAmountReservedForDefault The final collateral amount reserved for default case, which initially is zero and gets set once the proposal gets finalized.
     * @return finalCollAmountReservedForConversions The final collateral amount reserved for lender conversions, which initially is zero and gets set once the proposal gets finalized
     * @return loanTermsLockedTime The timestamp when loan terms got locked in, which initially is zero and gets set once the proposal gets finalized
     * @return currentRepaymentIdx The current repayment index, which gets incremented on every repay
     * @return status The current loan proposal status.
     * @return protocolFee The protocol fee, which initially is expressed in relative terms (i.e., 100% = BASE) and once the proposal gets finalized is in absolute terms (e.g., 1000 USDC). Note that the relative protocol fee is locked in at the time when the proposal is first created
     * @dev Note that finalCollAmountReservedForDefault is a lower bound for the collateral amount that lenders can claim in case of a default. This means that in case all lenders converted and the borrower defaults then this amount will be distributed as default recovery value on a pro-rata basis to lenders. In the other case where no lenders converted then finalCollAmountReservedForDefault plus finalCollAmountReservedForConversions will be available as default recovery value for lenders, hence finalCollAmountReservedForDefault is a lower bound for a lender's default recovery value.
     */
    function dynamicData()
        external
        view
        returns (
            uint256 arrangerFee,
            uint256 grossLoanAmount,
            uint256 finalCollAmountReservedForDefault,
            uint256 finalCollAmountReservedForConversions,
            uint256 loanTermsLockedTime,
            uint256 currentRepaymentIdx,
            DataTypesPeerToPool.LoanStatus status,
            uint256 protocolFee
        );

    /**
     * @notice Returns core static data for given loan proposal
     * @return factory The address of the factory contract from which the proposal was created
     * @return fundingPool The address of the funding pool from which lenders can subscribe, and from which 
     -upon acceptance- the final loan amount gets sourced
     * @return collToken The address of the collateral token to be provided by the borrower
     * @return arranger The address of the arranger of the proposal
     * @return whitelistAuthority Addresses of the whitelist authority who can manage a lender whitelist (optional)
     * @return unsubscribeGracePeriod Unsubscribe grace period until which lenders can unsubscribe after a loan 
     proposal got accepted by the borrower
     * @return conversionGracePeriod Conversion grace period during which lenders can convert, i.e., between 
     [dueTimeStamp, dueTimeStamp+conversionGracePeriod]
     * @return repaymentGracePeriod Repayment grace period during which borrowers can repay, i.e., between 
     [dueTimeStamp+conversionGracePeriod, dueTimeStamp+conversionGracePeriod+repaymentGracePeriod]
     */
    function staticData()
        external
        view
        returns (
            address factory,
            address fundingPool,
            address collToken,
            address arranger,
            address whitelistAuthority,
            uint256 unsubscribeGracePeriod,
            uint256 conversionGracePeriod,
            uint256 repaymentGracePeriod
        );

    /**
     * @notice Returns the timestamp of when loan terms were last updated
     * @return lastLoanTermsUpdateTime The timestamp when the loan terms were last updated
     */
    function lastLoanTermsUpdateTime()
        external
        view
        returns (uint256 lastLoanTermsUpdateTime);

    /**
     * @notice Returns the current loan terms
     * @return The current loan terms
     */
    function loanTerms()
        external
        view
        returns (DataTypesPeerToPool.LoanTerms memory);

    /**
     * @notice Returns flag indicating whether lenders can currently unsubscribe from loan proposal
     * @return Flag indicating whether lenders can currently unsubscribe from loan proposal
     */
    function canUnsubscribe() external view returns (bool);

    /**
     * @notice Returns flag indicating whether lenders can currently subscribe to loan proposal
     * @return Flag indicating whether lenders can currently subscribe to loan proposal
     */
    function canSubscribe() external view returns (bool);

    /**
     * @notice Returns indicative final loan terms
     * @param _tmpLoanTerms The current (or assumed) relative loan terms
     * @param totalSubscriptions The current (or assumed) total subscription amount
     * @param loanTokenDecimals The loan token decimals
     * @return loanTerms The loan terms in absolute terms
     * @return collAmounts Array containing collateral amount reserved for default and for conversions
     * @return fees Array containing arranger fee and protocol fee
     */
    function getAbsoluteLoanTerms(
        DataTypesPeerToPool.LoanTerms memory _tmpLoanTerms,
        uint256 totalSubscriptions,
        uint256 loanTokenDecimals
    )
        external
        view
        returns (
            DataTypesPeerToPool.LoanTerms memory loanTerms,
            uint256[2] memory collAmounts,
            uint256[2] memory fees
        );
}
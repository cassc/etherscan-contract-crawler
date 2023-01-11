// SPDX-License-Identifier: GPL-3.0

pragma solidity 0.8.17;

interface IBasePool {
    event NewSubPool(
        address loanCcyToken,
        address collCcyToken,
        uint256 loanTenor,
        uint256 maxLoanPerColl,
        uint256 r1,
        uint256 r2,
        uint256 liquidityBnd1,
        uint256 liquidityBnd2,
        uint256 minLoan,
        uint256 creatorFee
    );
    event AddLiquidity(
        address indexed lp,
        uint256 amount,
        uint256 newLpShares,
        uint256 totalLiquidity,
        uint256 totalLpShares,
        uint256 earliestRemove,
        uint256 indexed loanIdx,
        uint256 indexed referralCode
    );
    event RemoveLiquidity(
        address indexed lp,
        uint256 amount,
        uint256 removedLpShares,
        uint256 totalLiquidity,
        uint256 totalLpShares,
        uint256 indexed loanIdx
    );
    event Borrow(
        address indexed borrower,
        uint256 loanIdx,
        uint256 collateral,
        uint256 loanAmount,
        uint256 repaymentAmount,
        uint256 totalLpShares,
        uint256 indexed expiry,
        uint256 indexed referralCode
    );
    event Rollover(
        address indexed borrower,
        uint256 loanIdx,
        uint256 collateral,
        uint256 loanAmount,
        uint256 repaymentAmount,
        uint256 totalLpShares,
        uint256 indexed expiry
    );
    event ClaimFromAggregated(
        address indexed lp,
        uint256 fromLoanIdx,
        uint256 toLoanIdx,
        uint256 repayments,
        uint256 collateral
    );
    event Claim(
        address indexed lp,
        uint256[] loanIdxs,
        uint256 repayments,
        uint256 collateral
    );
    event Repay(
        address indexed borrower,
        uint256 loanIdx,
        uint256 repaymentAmountAfterFees
    );
    event Reinvest(
        address indexed lp,
        uint256 repayments,
        uint256 newLpShares,
        uint256 earliestRemove,
        uint256 indexed loanIdx
    );
    event ApprovalUpdate(
        address ownerOrBeneficiary,
        address sender,
        uint256 _packedApprovals
    );

    enum ApprovalTypes {
        REPAY,
        ROLLOVER,
        ADD_LIQUIDITY,
        REMOVE_LIQUIDITY,
        CLAIM
    }

    struct LpInfo {
        // lower bound loan idx (incl.) from which LP is entitled to claim; gets updated with every claim
        uint32 fromLoanIdx;
        // timestamp from which on LP is allowed to remove liquidity
        uint32 earliestRemove;
        // current share pointer to indicate which sharesOverTime element to be used fromLoanIdx until loanIdxsWhereSharesChanged[currSharePtr] or, if
        // out-of-bounds, until global loan idx
        uint32 currSharePtr;
        // array of len n, with elements representing number of sharesOverTime and new elements being added for consecutive adding/removing of liquidity
        uint256[] sharesOverTime;
        // array of len n-1, with elements representing upper bound loan idx bounds (excl.); LP can claim until loanIdxsWhereSharesChanged[i] with
        // sharesOverTime[i]; and if index i is out-of-bounds of loanIdxsWhereSharesChanged[] then LP can claim up until latest loan idx with sharesOverTime[i]
        uint256[] loanIdxsWhereSharesChanged;
    }

    struct LoanInfo {
        // repayment amount due (post potential fees) to reclaim collateral
        uint128 repayment;
        // reclaimable collateral amount
        uint128 collateral;
        // number of shares for which repayment, respectively collateral, needs to be split
        uint128 totalLpShares;
        // timestamp until repayment is possible and after which borrower forfeits collateral
        uint32 expiry;
        // flag whether loan was repaid or not
        bool repaid;
    }

    struct AggClaimsInfo {
        // aggregated repayment amount
        uint128 repayments;
        // aggregated collateral amount
        uint128 collateral;
    }

    /**
     * @notice Function which adds to an LPs current position
     * @dev This function will update loanIdxsWhereSharesChanged only if not
     * the first add. If address on behalf of is not sender, then sender must have permission.
     * @param _onBehalfOf Recipient of the LP shares
     * @param _sendAmount Amount of loan currency LP wishes to deposit
     * @param _deadline Last timestamp after which function will revert
     * @param _referralCode Will possibly be used later to reward referrals
     */
    function addLiquidity(
        address _onBehalfOf,
        uint128 _sendAmount,
        uint256 _deadline,
        uint256 _referralCode
    ) external;

    /**
     * @notice Function which removes shares from an LPs
     * @dev This function will update loanIdxsWhereSharesChanged and
     * shareOverTime arrays in lpInfo. If address on behalf of is not
     * sender, then sender must have permission to remove on behalf of owner.
     * @param _onBehalfOf Owner of the LP shares
     * @param numSharesRemove Amount of LP shares to remove
     */
    function removeLiquidity(
        address _onBehalfOf,
        uint128 numSharesRemove
    ) external;

    /**
     * @notice Function which allows borrowing from the pool
     * @param _onBehalf Will become owner of the loan
     * @param _sendAmount Amount of collateral currency sent by borrower
     * @param _minLoan Minimum loan currency amount acceptable to borrower
     * @param _maxRepay Maximum allowable loan currency amount borrower is willing to repay
     * @param _deadline Timestamp after which transaction will be void
     * @param _referralCode Code for later possible rewards in referral program
     */
    function borrow(
        address _onBehalf,
        uint128 _sendAmount,
        uint128 _minLoan,
        uint128 _maxRepay,
        uint256 _deadline,
        uint256 _referralCode
    ) external;

    /**
     * @notice Function which allows repayment of a loan
     * @dev The sent amount of loan currency must be sufficient to account
     * for any fees on transfer (if any)
     * @param _loanIdx Index of the loan to be repaid
     * @param _recipient Address that will receive the collateral transfer
     * @param _sendAmount Amount of loan currency sent for repayment.
     */
    function repay(
        uint256 _loanIdx,
        address _recipient,
        uint128 _sendAmount
    ) external;

    /**
     * @notice Function which allows repayment of a loan and roll over into new loan
     * @dev The old loan gets repaid and then a new loan with a new loan Id is taken out.
     * No actual transfers are made other than the interest
     * @param _loanIdx Index of the loan to be repaid
     * @param _minLoanLimit Minimum amount of loan currency acceptable from new loan.
     * @param _maxRepayLimit Maximum allowable loan currency amount borrower for new loan.
     * @param _deadline Timestamp after which transaction will be void
     * @param _sendAmount Amount of loan currency borrower needs to send to pay difference in repayment and loan amount
     */
    function rollOver(
        uint256 _loanIdx,
        uint128 _minLoanLimit,
        uint128 _maxRepayLimit,
        uint256 _deadline,
        uint128 _sendAmount
    ) external;

    /**
     * @notice Function which handles individual claiming by LPs
     * @dev This function is more expensive, but needs to be used when LP
     * changes position size in the middle of smallest aggregation block
     * or if LP wants to claim some of the loans before the expiry time
     * of the last loan in the aggregation block. _loanIdxs must be increasing array.
     * If address on behalf of is not sender, then sender must have permission to claim.
     * As well if reinvestment ootion is chosen, sender must have permission to add liquidity
     * @param _onBehalfOf LP address which is owner or has approved sender to claim on their behalf (and possibly reinvest)
     * @param _loanIdxs Loan indices on which LP wants to claim
     * @param _isReinvested Flag for if LP wants claimed loanCcy to be re-invested
     * @param _deadline Deadline if reinvestment occurs. (If no reinvestment, this is ignored)
     */
    function claim(
        address _onBehalfOf,
        uint256[] calldata _loanIdxs,
        bool _isReinvested,
        uint256 _deadline
    ) external;

    /**
     * @notice Function will update the share pointer for the LP
     * @dev This function will allow an LP to skip his pointer ahead but
     * caution should be used since once an LP has updated their from index
     * they lose all rights to any outstanding claims before that from index
     * @param _newSharePointer New location of the LP's current share pointer
     */
    function overrideSharePointer(uint256 _newSharePointer) external;

    /**
     * @notice Function which handles aggregate claiming by LPs
     * @dev This function is much more efficient, but can only be used when LPs position size did not change
     * over the entire interval LP would like to claim over. _aggIdxs must be increasing array.
     * the first index of _aggIdxs is the from loan index to start aggregation, the rest of the
     * indices are the end loan indexes of the intervals he wants to claim.
     * If address on behalf of is not sender, then sender must have permission to claim.
     * As well if reinvestment option is chosen, sender must have permission to add liquidity
     * @param _onBehalfOf LP address which is owner or has approved sender to claim on their behalf (and possibly reinvest)
     * @param _aggIdxs From index and end indices of the aggregation that LP wants to claim
     * @param _isReinvested Flag for if LP wants claimed loanCcy to be re-invested
     * @param _deadline Deadline if reinvestment occurs. (If no reinvestment, this is ignored)
     */
    function claimFromAggregated(
        address _onBehalfOf,
        uint256[] calldata _aggIdxs,
        bool _isReinvested,
        uint256 _deadline
    ) external;

    /**
     * @notice Function which sets approval for another to perform a certain function on sender's behalf
     * @param _approvee This address is being given approval for the action(s) by the current sender
     * @param _packedApprovals Packed boolean flags to set which actions are approved or not approved,
     * where e.g. "00001" refers to ApprovalTypes.Repay (=0) and "10000" to ApprovalTypes.Claim (=4)
     */
    function setApprovals(address _approvee, uint256 _packedApprovals) external;

    /**
     * @notice Function which proposes a new pool creator address
     * @param _newAddr Address that is being proposed as new pool creator
     */
    function proposeNewCreator(address _newAddr) external;

    /**
     * @notice Function to claim proposed creator role
     */
    function claimCreator() external;

    /**
     * @notice Function which gets all LP info
     * @dev fromLoanIdx = 0 can be utilized for checking if someone had been an LP in the pool
     * @param _lpAddr Address for which LP info is being retrieved
     * @return fromLoanIdx Lower bound loan idx (incl.) from which LP is entitled to claim
     * @return earliestRemove Earliest timestamp from which LP is allowed to remove liquidity
     * @return currSharePtr Current pointer for the shares over time array
     * @return sharesOverTime Array with elements representing number of LP shares for their past and current positions
     * @return loanIdxsWhereSharesChanged Array with elements representing upper loan idx bounds (excl.), where LP can claim
     */
    function getLpInfo(
        address _lpAddr
    )
        external
        view
        returns (
            uint32 fromLoanIdx,
            uint32 earliestRemove,
            uint32 currSharePtr,
            uint256[] memory sharesOverTime,
            uint256[] memory loanIdxsWhereSharesChanged
        );

    /**
     * @notice Function which returns rate parameters need for interest rate calculation
     * @dev This function can be used to get parameters needed for interest rate calculations
     * @return _liquidityBnd1 Amount of liquidity the pool needs to end the reciprocal (hyperbola)
     * range and start "target" range
     * @return _liquidityBnd2 Amount of liquidity the pool needs to end the "target" range and start flat rate
     * @return _r1 Rate that is used at start of target range
     * @return _r2 Minimum rate at end of target range. This is minimum allowable rate
     */
    function getRateParams()
        external
        view
        returns (
            uint256 _liquidityBnd1,
            uint256 _liquidityBnd2,
            uint256 _r1,
            uint256 _r2
        );

    /**
     * @notice Function which returns pool information
     * @dev This function can be used to get pool information
     * @return _loanCcyToken Loan currency
     * @return _collCcyToken Collateral currency
     * @return _maxLoanPerColl Maximum loan amount per pledged collateral unit
     * @return _minLoan Minimum loan size
     * @return _loanTenor Loan tenor
     * @return _totalLiquidity Total liquidity available for loans
     * @return _totalLpShares Total LP shares
     * @return _baseAggrBucketSize Base aggregation level
     * @return _loanIdx Loan index for the next incoming loan
     */
    function getPoolInfo()
        external
        view
        returns (
            address _loanCcyToken,
            address _collCcyToken,
            uint256 _maxLoanPerColl,
            uint256 _minLoan,
            uint256 _loanTenor,
            uint256 _totalLiquidity,
            uint256 _totalLpShares,
            uint256 _baseAggrBucketSize,
            uint256 _loanIdx
        );

    /**
     * @notice Function which calculates loan terms
     * @param _inAmountAfterFees Amount of collateral currency after fees are deducted
     * @return loanAmount Amount of loan currency to be trasnferred to the borrower
     * @return repaymentAmount Amount of loan currency borrower must repay to reclaim collateral
     * @return pledgeAmount Amount of collateral currency borrower retrieves upon repayment
     * @return _creatorFee Amount of collateral currency to be transferred to treasury
     * @return _totalLiquidity The total liquidity of the pool (pre-borrow) that is available for new loans
     */
    function loanTerms(
        uint128 _inAmountAfterFees
    )
        external
        view
        returns (
            uint128 loanAmount,
            uint128 repaymentAmount,
            uint128 pledgeAmount,
            uint256 _creatorFee,
            uint256 _totalLiquidity
        );

    /**
     * @notice Function which returns claims for a given aggregated from and to index and amount of sharesOverTime
     * @dev This function is called internally, but also can be used by other protocols so has some checks
     * which are unnecessary if it was solely an internal function
     * @param _fromLoanIdx Loan index on which he wants to start aggregate claim (must be mod 0 wrt 100)
     * @param _toLoanIdx End loan index of the aggregation
     * @param _shares Amount of sharesOverTime which the LP owned over this given aggregation period
     */
    function getClaimsFromAggregated(
        uint256 _fromLoanIdx,
        uint256 _toLoanIdx,
        uint256 _shares
    ) external view returns (uint256 repayments, uint256 collateral);

    /**
     * @notice Getter which returns the borrower for a given loan idx
     * @param loanIdx The loan idx
     * @return The borrower address
     */
    function loanIdxToBorrower(uint256 loanIdx) external view returns (address);

    /**
     * @notice Function returns if owner or beneficiary has approved a sender address for a given type
     * @param _ownerOrBeneficiary Address which will be owner or beneficiary of transaction if approved
     * @param _sender Address which will be sending request on behalf of _ownerOrBeneficiary
     * @param _approvalType Type of approval requested { REPAY, ROLLOVER, ADD_LIQUIDITY, REMOVE_LIQUIDITY, CLAIM }
     * @return _approved True if approved, false otherwise
     */
    function isApproved(
        address _ownerOrBeneficiary,
        address _sender,
        ApprovalTypes _approvalType
    ) external view returns (bool _approved);
}
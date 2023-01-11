// SPDX-License-Identifier: GPL-3.0

pragma solidity 0.8.17;

import "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {IBasePool} from "./interfaces/IBasePool.sol";

abstract contract BasePool is IBasePool {
    using SafeERC20 for IERC20Metadata;

    error IdenticalLoanAndCollCcy();
    error InvalidZeroAddress();
    error InvalidLoanTenor();
    error InvalidMaxLoanPerColl();
    error InvalidRateParams();
    error InvalidLiquidityBnds();
    error InvalidMinLiquidity();
    error InvalidBaseAggrSize();
    error InvalidFee();
    error PastDeadline();
    error InvalidAddAmount();
    error BeforeEarliestRemove();
    error InsufficientLiquidity();
    error InvalidRemove();
    error LoanTooSmall();
    error LoanBelowLimit();
    error ErroneousLoanTerms();
    error RepaymentAboveLimit();
    error InvalidLoanIdx();
    error UnapprovedSender();
    error InvalidRecipient();
    error InvalidSubAggregation();
    error CannotRepayAfterExpiry();
    error AlreadyRepaid();
    error CannotRepayInSameBlock();
    error InvalidRollOver();
    error InvalidSendAmount();
    error NothingToClaim();
    error MustBeLp();
    error InvalidNewSharePointer();
    error UnentitledFromLoanIdx();
    error LoanIdxsWithChangingShares();
    error NonAscendingLoanIdxs();
    error CannotClaimWithUnsettledLoan();
    error InvalidApprovalAddress();
    error ZeroShareClaim();
    error Invalid();

    uint256 constant MIN_LPING_PERIOD = 120; // in seconds
    uint256 constant BASE = 10 ** 18;
    uint256 constant MAX_FEE = 30 * 10 ** 14; // 30bps, denominated in BASE
    uint256 minLiquidity; // denominated in loanCcy decimals

    address poolCreator;
    address poolCreatorProposal;
    address collCcyToken;
    address loanCcyToken;

    uint128 totalLpShares; // LP shares are denominated and discretized in 1/1000th of minLiquidity
    uint256 loanTenor; // in seconds
    uint256 collTokenDecimals;
    uint256 maxLoanPerColl; // denominated in loanCcy decimals
    uint256 creatorFee; // denominated in BASE
    uint256 totalLiquidity; // denominated in loanCcy decimals
    uint256 loanIdx;
    uint256 r1; // denominated in BASE and w.r.t. tenor (i.e., not annualized)
    uint256 r2; // denominated in BASE and w.r.t. tenor (i.e., not annualized)
    uint256 liquidityBnd1; // denominated in loanCcy decimals
    uint256 liquidityBnd2; // denominated in loanCcy decimals
    uint256 minLoan; // denominated in loanCcy decimals
    uint256 baseAggrBucketSize; // must be a multiple of 100
    mapping(address => LpInfo) addrToLpInfo;
    mapping(address => uint256) lastAddOfTxOrigin;
    mapping(uint256 => LoanInfo) public loanIdxToLoanInfo;
    mapping(uint256 => address) public loanIdxToBorrower;

    mapping(address => mapping(address => mapping(IBasePool.ApprovalTypes => bool)))
        public isApproved;

    mapping(uint256 => AggClaimsInfo) collAndRepayTotalBaseAgg1;
    mapping(uint256 => AggClaimsInfo) collAndRepayTotalBaseAgg2;
    mapping(uint256 => AggClaimsInfo) collAndRepayTotalBaseAgg3;

    constructor(
        address _loanCcyToken,
        address _collCcyToken,
        uint256 _loanTenor,
        uint256 _maxLoanPerColl,
        uint256 _r1,
        uint256 _r2,
        uint256 _liquidityBnd1,
        uint256 _liquidityBnd2,
        uint256 _minLoan,
        uint256 _baseAggrBucketSize,
        uint256 _creatorFee,
        uint256 _minLiquidity
    ) {
        if (_collCcyToken == _loanCcyToken) revert IdenticalLoanAndCollCcy();
        if (_loanCcyToken == address(0) || _collCcyToken == address(0))
            revert InvalidZeroAddress();
        if (_loanTenor < 86400) revert InvalidLoanTenor();
        if (_maxLoanPerColl == 0) revert InvalidMaxLoanPerColl();
        if (_r1 <= _r2 || _r2 == 0) revert InvalidRateParams();
        if (_liquidityBnd2 <= _liquidityBnd1 || _liquidityBnd1 == 0)
            revert InvalidLiquidityBnds();
        // ensure LP shares can be minted based on 1/1000th of minLp discretization
        if (_minLiquidity < 1000) revert InvalidMinLiquidity();
        if (_baseAggrBucketSize < 100 || _baseAggrBucketSize % 100 != 0)
            revert InvalidBaseAggrSize();
        if (_creatorFee > MAX_FEE) revert InvalidFee();
        poolCreator = msg.sender;
        loanCcyToken = _loanCcyToken;
        collCcyToken = _collCcyToken;
        loanTenor = _loanTenor;
        maxLoanPerColl = _maxLoanPerColl;
        r1 = _r1;
        r2 = _r2;
        liquidityBnd1 = _liquidityBnd1;
        liquidityBnd2 = _liquidityBnd2;
        minLoan = _minLoan;
        loanIdx = 1;
        collTokenDecimals = IERC20Metadata(_collCcyToken).decimals();
        baseAggrBucketSize = _baseAggrBucketSize;
        creatorFee = _creatorFee;
        minLiquidity = _minLiquidity;
        emit NewSubPool(
            _loanCcyToken,
            _collCcyToken,
            _loanTenor,
            _maxLoanPerColl,
            _r1,
            _r2,
            _liquidityBnd1,
            _liquidityBnd2,
            _minLoan,
            _creatorFee
        );
    }

    function addLiquidity(
        address _onBehalfOf,
        uint128 _sendAmount,
        uint256 _deadline,
        uint256 _referralCode
    ) external override {
        // verify LP info and eligibility
        checkTimestamp(_deadline);
        checkSenderApproval(_onBehalfOf, IBasePool.ApprovalTypes.ADD_LIQUIDITY);

        uint128 _inAmountAfterFees = _sendAmount -
            getLoanCcyTransferFee(_sendAmount);

        (
            uint256 dust,
            uint256 newLpShares,
            uint32 earliestRemove
        ) = _addLiquidity(_onBehalfOf, _inAmountAfterFees);

        // transfer liquidity
        IERC20Metadata(loanCcyToken).safeTransferFrom(
            msg.sender,
            address(this),
            _sendAmount
        );

        // transfer dust to creator if any
        if (dust > 0) {
            IERC20Metadata(loanCcyToken).safeTransfer(poolCreator, dust);
        }
        // spawn event
        emit AddLiquidity(
            _onBehalfOf,
            _sendAmount,
            newLpShares,
            totalLiquidity,
            totalLpShares,
            earliestRemove,
            loanIdx,
            _referralCode
        );
    }

    // put in number of shares to remove, up to all of them
    function removeLiquidity(
        address _onBehalfOf,
        uint128 numShares
    ) external override {
        delete lastAddOfTxOrigin[_onBehalfOf];
        // verify LP info and eligibility
        checkSenderApproval(
            _onBehalfOf,
            IBasePool.ApprovalTypes.REMOVE_LIQUIDITY
        );

        LpInfo storage lpInfo = addrToLpInfo[_onBehalfOf];
        uint256 shareLength = lpInfo.sharesOverTime.length;
        if (
            shareLength * numShares == 0 ||
            lpInfo.sharesOverTime[shareLength - 1] < numShares
        ) revert InvalidRemove();
        if (block.timestamp < lpInfo.earliestRemove)
            revert BeforeEarliestRemove();
        uint256 _totalLiquidity = totalLiquidity;
        uint128 _totalLpShares = totalLpShares;
        // update state of pool
        uint256 liquidityRemoved = (numShares *
            (_totalLiquidity - minLiquidity)) / _totalLpShares;
        totalLpShares -= numShares;
        totalLiquidity = _totalLiquidity - liquidityRemoved;

        // update LP arrays and check for auto increment
        updateLpArrays(lpInfo, numShares, false);

        // transfer liquidity
        IERC20Metadata(loanCcyToken).safeTransfer(msg.sender, liquidityRemoved);
        // spawn event
        emit RemoveLiquidity(
            _onBehalfOf,
            liquidityRemoved,
            numShares,
            totalLiquidity,
            _totalLpShares - numShares,
            loanIdx
        );
    }

    function borrow(
        address _onBehalf,
        uint128 _sendAmount,
        uint128 _minLoanLimit,
        uint128 _maxRepayLimit,
        uint256 _deadline,
        uint256 _referralCode
    ) external override {
        uint256 _timestamp = checkTimestamp(_deadline);
        // check if atomic add and borrow as well as sanity check of onBehalf address
        if (
            lastAddOfTxOrigin[tx.origin] == _timestamp ||
            _onBehalf == address(0)
        ) revert Invalid();
        uint128 _inAmountAfterFees = _sendAmount -
            getCollCcyTransferFee(_sendAmount);
        // get borrow terms and do checks
        (
            uint128 loanAmount,
            uint128 repaymentAmount,
            uint128 pledgeAmount,
            uint32 expiry,
            uint256 _creatorFee,
            uint256 _totalLiquidity
        ) = _borrow(
                _inAmountAfterFees,
                _minLoanLimit,
                _maxRepayLimit,
                _timestamp
            );
        {
            // update pool state
            totalLiquidity = _totalLiquidity - loanAmount;

            uint256 _loanIdx = loanIdx;
            uint128 _totalLpShares = totalLpShares;

            // update loan info
            loanIdxToBorrower[_loanIdx] = _onBehalf;
            LoanInfo memory loanInfo;
            loanInfo.repayment = repaymentAmount;
            loanInfo.totalLpShares = _totalLpShares;
            loanInfo.expiry = expiry;
            loanInfo.collateral = pledgeAmount;
            loanIdxToLoanInfo[_loanIdx] = loanInfo;

            // update aggregations
            updateAggregations(
                _loanIdx,
                pledgeAmount,
                0,
                _totalLpShares,
                false
            );

            // update loan idx counter
            loanIdx = _loanIdx + 1;
        }
        {
            // transfer _sendAmount (not pledgeAmount) in collateral ccy
            IERC20Metadata(collCcyToken).safeTransferFrom(
                msg.sender,
                address(this),
                _sendAmount
            );

            // transfer creator fee to creator in collateral ccy
            IERC20Metadata(collCcyToken).safeTransfer(poolCreator, _creatorFee);

            // transfer loanAmount in loan ccy
            IERC20Metadata(loanCcyToken).safeTransfer(msg.sender, loanAmount);
        }
        // spawn event
        emit Borrow(
            _onBehalf,
            loanIdx - 1,
            pledgeAmount,
            loanAmount,
            repaymentAmount,
            totalLpShares,
            expiry,
            _referralCode
        );
    }

    function repay(
        uint256 _loanIdx,
        address _recipient,
        uint128 _sendAmount
    ) external override {
        // verify loan info and eligibility
        if (_loanIdx == 0 || _loanIdx >= loanIdx) revert InvalidLoanIdx();
        address _loanOwner = loanIdxToBorrower[_loanIdx];

        if (!(_loanOwner == _recipient || msg.sender == _recipient))
            revert InvalidRecipient();
        checkSenderApproval(_loanOwner, IBasePool.ApprovalTypes.REPAY);
        LoanInfo storage loanInfo = loanIdxToLoanInfo[_loanIdx];
        uint256 timestamp = block.timestamp;
        if (timestamp > loanInfo.expiry) revert CannotRepayAfterExpiry();
        if (loanInfo.repaid) revert AlreadyRepaid();
        if (timestamp == loanInfo.expiry - loanTenor)
            revert CannotRepayInSameBlock();
        // update loan info
        loanInfo.repaid = true;
        uint128 _repayment = loanInfo.repayment;

        // transfer repayment amount
        uint128 repaymentAmountAfterFees = checkAndGetSendAmountAfterFees(
            _sendAmount,
            _repayment
        );
        // if repaymentAmountAfterFees was larger then update loan info
        // this ensures the extra repayment goes to the LPs
        if (repaymentAmountAfterFees != _repayment) {
            loanInfo.repayment = repaymentAmountAfterFees;
        }
        uint128 _collateral = loanInfo.collateral;
        uint128 _totalLpShares = loanInfo.totalLpShares;
        // update the aggregation mappings
        updateAggregations(
            _loanIdx,
            _collateral,
            repaymentAmountAfterFees,
            _totalLpShares,
            true
        );

        IERC20Metadata(loanCcyToken).safeTransferFrom(
            msg.sender,
            address(this),
            _sendAmount
        );
        // transfer collateral to _recipient (allows for possible
        // transfer directly to someone other than payer/sender)
        IERC20Metadata(collCcyToken).safeTransfer(_recipient, _collateral);
        // spawn event
        emit Repay(_loanOwner, _loanIdx, repaymentAmountAfterFees);
    }

    function rollOver(
        uint256 _loanIdx,
        uint128 _minLoanLimit,
        uint128 _maxRepayLimit,
        uint256 _deadline,
        uint128 _sendAmount
    ) external override {
        uint256 timestamp = checkTimestamp(_deadline);
        // check if atomic add and rollOver
        if (lastAddOfTxOrigin[tx.origin] == timestamp) revert Invalid();
        // verify loan info and eligibility
        if (_loanIdx == 0 || _loanIdx >= loanIdx) revert InvalidLoanIdx();
        address loanOwner = loanIdxToBorrower[_loanIdx];
        checkSenderApproval(loanOwner, IBasePool.ApprovalTypes.ROLLOVER);
        LoanInfo storage loanInfo = loanIdxToLoanInfo[_loanIdx];
        {
            if (timestamp > loanInfo.expiry) revert CannotRepayAfterExpiry();
            if (loanInfo.repaid) revert AlreadyRepaid();
            if (timestamp == loanInfo.expiry - loanTenor)
                revert CannotRepayInSameBlock();
        }

        uint128 _collateral = loanInfo.collateral;
        // get terms for new borrow
        (
            uint128 loanAmount,
            uint128 repaymentAmount,
            uint128 pledgeAmount,
            uint32 expiry,
            uint256 _creatorFee,
            uint256 _totalLiquidity
        ) = _borrow(_collateral, _minLoanLimit, _maxRepayLimit, _deadline);
        // overwrite _deadline memory variable in order to prevent stack too deep
        // error when emitting repay event
        _deadline = _loanIdx;
        {
            // check roll over cost
            uint128 tmpRepayment = loanInfo.repayment;
            if (loanAmount >= tmpRepayment) revert InvalidRollOver();
            uint128 rollOverCost = tmpRepayment - loanAmount;
            uint128 repaymentAmountAfterFees = checkAndGetSendAmountAfterFees(
                _sendAmount,
                rollOverCost
            ) + loanAmount;
            loanInfo.repayment = repaymentAmountAfterFees;
            // mark previous loan as repaid
            loanInfo.repaid = true;
            // overwrite _maxRepayLimit memory variable in order to prevent stack too deep
            // error when emitting repay event
            _maxRepayLimit = repaymentAmountAfterFees;
        }
        // update the aggregation mapping for repaid loan
        updateAggregations(
            _loanIdx,
            _collateral,
            loanInfo.repayment,
            loanInfo.totalLpShares,
            true
        );
        {
            uint256 currLoanIdx = loanIdx;
            // set new loan info
            loanIdxToBorrower[currLoanIdx] = loanOwner;
            LoanInfo memory loanInfoNew;
            loanInfoNew.expiry = expiry;
            loanInfoNew.totalLpShares = totalLpShares;
            loanInfoNew.repayment = repaymentAmount;
            loanInfoNew.collateral = pledgeAmount;
            loanIdxToLoanInfo[currLoanIdx] = loanInfoNew;
            updateAggregations(
                currLoanIdx,
                pledgeAmount,
                0,
                loanInfoNew.totalLpShares,
                false
            );
            loanIdx = currLoanIdx + 1;
            totalLiquidity = _totalLiquidity - loanAmount;
            // transfer liquidity
            IERC20Metadata(loanCcyToken).safeTransferFrom(
                msg.sender,
                address(this),
                _sendAmount
            );
            // transfer creator fee to pool creator in collateral ccy
            IERC20Metadata(collCcyToken).safeTransfer(poolCreator, _creatorFee);

            // spawn event
            emit Rollover(
                loanOwner,
                currLoanIdx,
                pledgeAmount,
                loanAmount,
                repaymentAmount,
                loanInfoNew.totalLpShares,
                expiry
            );
        }
        emit Repay(loanOwner, _deadline, _maxRepayLimit);
    }

    function claim(
        address _onBehalfOf,
        uint256[] calldata _loanIdxs,
        bool _isReinvested,
        uint256 _deadline
    ) external override {
        // check if reinvested is chosen that deadline is valid and sender can add liquidity on behalf of
        if (_isReinvested) {
            claimReinvestmentCheck(_deadline, _onBehalfOf);
        }
        checkSenderApproval(_onBehalfOf, IBasePool.ApprovalTypes.CLAIM);
        LpInfo storage lpInfo = addrToLpInfo[_onBehalfOf];

        // verify LP info and eligibility
        uint256 loanIdxsLen = _loanIdxs.length;
        // length of sharesOverTime array for LP
        uint256 sharesOverTimeLen = lpInfo.sharesOverTime.length;
        if (loanIdxsLen * sharesOverTimeLen == 0) revert NothingToClaim();
        if (_loanIdxs[0] == 0) revert InvalidLoanIdx();

        (
            uint256 sharesUnchangedUntilLoanIdx,
            uint256 applicableShares
        ) = claimsChecksAndSetters(
                _loanIdxs[0],
                _loanIdxs[loanIdxsLen - 1],
                lpInfo
            );

        // iterate over loans to get claimable amounts
        (uint256 repayments, uint256 collateral) = getClaimsFromList(
            _loanIdxs,
            loanIdxsLen,
            applicableShares
        );

        // update LP's from loan index to prevent double claiming and check share pointer
        checkSharePtrIncrement(
            lpInfo,
            _loanIdxs[loanIdxsLen - 1],
            lpInfo.currSharePtr,
            sharesUnchangedUntilLoanIdx
        );

        claimTransferAndReinvestment(
            _onBehalfOf,
            repayments,
            collateral,
            _isReinvested
        );

        // spawn event
        emit Claim(_onBehalfOf, _loanIdxs, repayments, collateral);
    }

    function overrideSharePointer(uint256 _newSharePointer) external {
        LpInfo storage lpInfo = addrToLpInfo[msg.sender];
        if (lpInfo.fromLoanIdx == 0) revert MustBeLp();
        // check that passed in pointer is greater than current share pointer
        // and less than length of LP's shares over time array
        if (
            _newSharePointer <= lpInfo.currSharePtr ||
            _newSharePointer + 1 > lpInfo.sharesOverTime.length
        ) revert InvalidNewSharePointer();
        lpInfo.currSharePtr = uint32(_newSharePointer);
        lpInfo.fromLoanIdx = uint32(
            lpInfo.loanIdxsWhereSharesChanged[_newSharePointer - 1]
        );
    }

    function claimFromAggregated(
        address _onBehalfOf,
        uint256[] calldata _aggIdxs,
        bool _isReinvested,
        uint256 _deadline
    ) external override {
        // check if reinvested is chosen that deadline is valid and sender can add liquidity on behalf of
        if (_isReinvested) {
            claimReinvestmentCheck(_deadline, _onBehalfOf);
        }
        checkSenderApproval(_onBehalfOf, IBasePool.ApprovalTypes.CLAIM);
        LpInfo storage lpInfo = addrToLpInfo[_onBehalfOf];

        // verify LP info and eligibility
        // length of loanIdxs array LP wants to claim
        uint256 lengthArr = _aggIdxs.length;
        // checks if length loanIds passed in is less than 2 (hence does not make even one valid claim interval)
        // OR if sharesOverTime array is empty.
        if (lpInfo.sharesOverTime.length == 0 || lengthArr < 2)
            revert NothingToClaim();

        (
            uint256 sharesUnchangedUntilLoanIdx,
            uint256 applicableShares
        ) = claimsChecksAndSetters(
                _aggIdxs[0],
                _aggIdxs[lengthArr - 1] - 1,
                lpInfo
            );

        // local variables to track repayments and collateral claimed
        uint256 totalRepayments;
        uint256 totalCollateral;

        // local variables for each iteration's repayments and collateral
        uint256 repayments;
        uint256 collateral;

        // iterate over the length of the passed in array
        for (uint256 counter = 0; counter < lengthArr - 1; ) {
            // make sure input loan indices are strictly increasing
            if (_aggIdxs[counter] >= _aggIdxs[counter + 1])
                revert NonAscendingLoanIdxs();

            // get aggregated claims
            (repayments, collateral) = getClaimsFromAggregated(
                _aggIdxs[counter],
                _aggIdxs[counter + 1],
                applicableShares
            );
            // update total repayment amount and total collateral amount
            totalRepayments += repayments;
            totalCollateral += collateral;

            unchecked {
                //increment local counter
                counter++;
            }
        }

        // update LP's from loan index to prevent double claiming and check share pointer
        checkSharePtrIncrement(
            lpInfo,
            _aggIdxs[lengthArr - 1] - 1,
            lpInfo.currSharePtr,
            sharesUnchangedUntilLoanIdx
        );

        claimTransferAndReinvestment(
            _onBehalfOf,
            totalRepayments,
            totalCollateral,
            _isReinvested
        );
        // spawn event
        emit ClaimFromAggregated(
            _onBehalfOf,
            _aggIdxs[0],
            _aggIdxs[lengthArr - 1],
            totalRepayments,
            totalCollateral
        );
    }

    function setApprovals(
        address _approvee,
        uint256 _packedApprovals
    ) external {
        if (msg.sender == _approvee || _approvee == address(0))
            revert InvalidApprovalAddress();
        _packedApprovals &= 0x1f;
        for (uint256 index = 0; index < 5; ) {
            bool approvalFlag = ((_packedApprovals >> index) & uint256(1)) == 1;
            if (
                isApproved[msg.sender][_approvee][
                    IBasePool.ApprovalTypes(index)
                ] != approvalFlag
            ) {
                isApproved[msg.sender][_approvee][
                    IBasePool.ApprovalTypes(index)
                ] = approvalFlag;
                _packedApprovals |= uint256(1) << 5;
            }
            unchecked {
                index++;
            }
        }
        if (((_packedApprovals >> 5) & uint256(1)) == 1) {
            emit ApprovalUpdate(msg.sender, _approvee, _packedApprovals & 0x1f);
        }
    }

    function proposeNewCreator(address newAddr) external {
        if (msg.sender == poolCreator) {
            poolCreatorProposal = newAddr;
        }
    }

    function claimCreator() external {
        if (msg.sender == poolCreatorProposal) {
            poolCreator = msg.sender;
        }
    }

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
        )
    {
        LpInfo memory lpInfo = addrToLpInfo[_lpAddr];
        fromLoanIdx = lpInfo.fromLoanIdx;
        earliestRemove = lpInfo.earliestRemove;
        currSharePtr = lpInfo.currSharePtr;
        sharesOverTime = lpInfo.sharesOverTime;
        loanIdxsWhereSharesChanged = lpInfo.loanIdxsWhereSharesChanged;
    }

    function getRateParams()
        external
        view
        returns (
            uint256 _liquidityBnd1,
            uint256 _liquidityBnd2,
            uint256 _r1,
            uint256 _r2
        )
    {
        _liquidityBnd1 = liquidityBnd1;
        _liquidityBnd2 = liquidityBnd2;
        _r1 = r1;
        _r2 = r2;
    }

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
        )
    {
        _loanCcyToken = loanCcyToken;
        _collCcyToken = collCcyToken;
        _maxLoanPerColl = maxLoanPerColl;
        _minLoan = minLoan;
        _loanTenor = loanTenor;
        _totalLiquidity = totalLiquidity;
        _totalLpShares = totalLpShares;
        _baseAggrBucketSize = baseAggrBucketSize;
        _loanIdx = loanIdx;
    }

    function loanTerms(
        uint128 _inAmountAfterFees
    )
        public
        view
        returns (
            uint128 loanAmount,
            uint128 repaymentAmount,
            uint128 pledgeAmount,
            uint256 _creatorFee,
            uint256 _totalLiquidity
        )
    {
        // compute terms (as uint256)
        _creatorFee = (_inAmountAfterFees * creatorFee) / BASE;
        uint256 pledge = _inAmountAfterFees - _creatorFee;
        _totalLiquidity = totalLiquidity;
        if (_totalLiquidity <= minLiquidity) revert InsufficientLiquidity();
        uint256 loan = (pledge *
            maxLoanPerColl *
            (_totalLiquidity - minLiquidity)) /
            (pledge *
                maxLoanPerColl +
                (_totalLiquidity - minLiquidity) *
                10 ** collTokenDecimals);
        if (loan < minLoan) revert LoanTooSmall();
        uint256 postLiquidity = _totalLiquidity - loan;
        assert(postLiquidity >= minLiquidity);
        // we use the average rate to calculate the repayment amount
        uint256 avgRate = (getRate(_totalLiquidity) + getRate(postLiquidity)) /
            2;
        // if pre- and post-borrow liquidity are within target liquidity range
        // then the repayment amount exactly matches the amount of integrating the
        // loan size over the infinitesimal rate; else the repayment amount is
        // larger than the amount of integrating loan size over rate;
        uint256 repayment = (loan * (BASE + avgRate)) / BASE;
        // return terms (as uint128)
        assert(uint128(loan) == loan);
        loanAmount = uint128(loan);
        assert(uint128(repayment) == repayment);
        repaymentAmount = uint128(repayment);
        assert(uint128(pledge) == pledge);
        pledgeAmount = uint128(pledge);
        if (repaymentAmount <= loanAmount) revert ErroneousLoanTerms();
    }

    function getClaimsFromAggregated(
        uint256 _fromLoanIdx,
        uint256 _toLoanIdx,
        uint256 _shares
    ) public view returns (uint256 repayments, uint256 collateral) {
        uint256 fromToDiff = _toLoanIdx - _fromLoanIdx;
        uint256 _baseAggrBucketSize = baseAggrBucketSize;
        // expiry check to make sure last loan in aggregation (one prior to _toLoanIdx for bucket) was taken out and expired
        uint32 expiryCheck = loanIdxToLoanInfo[_toLoanIdx - 1].expiry;
        if (expiryCheck == 0 || expiryCheck + 1 > block.timestamp) {
            revert InvalidSubAggregation();
        }
        AggClaimsInfo memory aggClaimsInfo;
        // find which bucket to which the current aggregation belongs and get aggClaimsInfo
        if (
            _toLoanIdx % _baseAggrBucketSize == 0 &&
            fromToDiff == _baseAggrBucketSize
        ) {
            aggClaimsInfo = collAndRepayTotalBaseAgg1[
                _fromLoanIdx / _baseAggrBucketSize + 1
            ];
        } else if (
            _toLoanIdx % (10 * _baseAggrBucketSize) == 0 &&
            fromToDiff == _baseAggrBucketSize * 10
        ) {
            aggClaimsInfo = collAndRepayTotalBaseAgg2[
                (_fromLoanIdx / (_baseAggrBucketSize * 10)) + 1
            ];
        } else if (
            _toLoanIdx % (100 * _baseAggrBucketSize) == 0 &&
            fromToDiff == _baseAggrBucketSize * 100
        ) {
            aggClaimsInfo = collAndRepayTotalBaseAgg3[
                (_fromLoanIdx / (_baseAggrBucketSize * 100)) + 1
            ];
        } else {
            revert InvalidSubAggregation();
        }

        // return repayment and collateral amounts
        repayments = (aggClaimsInfo.repayments * _shares) / BASE;
        collateral = (aggClaimsInfo.collateral * _shares) / BASE;
    }

    /**
     * @notice Function which updates the 3 aggegration levels when claiming
     * @dev This function will subtract collateral and add to repay if _isRepay is true.
     * Otherwise, repayment will be unchanged and collateral will be added
     * @param _loanIdx Loan index used to determine aggregation "bucket" index
     * @param _collateral Amount of collateral to add/subtract from aggregations
     * @param _repayment Amount of loan currency to add to repayments, only if _isRepay is true
     * @param _totalLpShares Amount of LP Shares for given loan, used to divide amounts into units per LP share
     * @param _isRepay Flag which if false only allows adding collateral else subtracts collateral and adds repayments
     */
    function updateAggregations(
        uint256 _loanIdx,
        uint128 _collateral,
        uint128 _repayment,
        uint128 _totalLpShares,
        bool _isRepay
    ) internal {
        uint256 _baseAggFirstIndex = _loanIdx / baseAggrBucketSize + 1;
        uint256 _baseAggSecondIndex = ((_baseAggFirstIndex - 1) / 10) + 1;
        uint256 _baseAggThirdIndex = ((_baseAggFirstIndex - 1) / 100) + 1;

        uint128 collateralUpdate = uint128(
            (_collateral * BASE) / _totalLpShares
        );
        uint128 repaymentUpdate = uint128((_repayment * BASE) / _totalLpShares);

        if (_isRepay) {
            collAndRepayTotalBaseAgg1[_baseAggFirstIndex]
                .collateral -= collateralUpdate;
            collAndRepayTotalBaseAgg2[_baseAggSecondIndex]
                .collateral -= collateralUpdate;
            collAndRepayTotalBaseAgg3[_baseAggThirdIndex]
                .collateral -= collateralUpdate;
            collAndRepayTotalBaseAgg1[_baseAggFirstIndex]
                .repayments += repaymentUpdate;
            collAndRepayTotalBaseAgg2[_baseAggSecondIndex]
                .repayments += repaymentUpdate;
            collAndRepayTotalBaseAgg3[_baseAggThirdIndex]
                .repayments += repaymentUpdate;
        } else {
            collAndRepayTotalBaseAgg1[_baseAggFirstIndex]
                .collateral += collateralUpdate;
            collAndRepayTotalBaseAgg2[_baseAggSecondIndex]
                .collateral += collateralUpdate;
            collAndRepayTotalBaseAgg3[_baseAggThirdIndex]
                .collateral += collateralUpdate;
        }
    }

    /**
     * @notice Function which updates from index and checks if share pointer should be incremented
     * @dev This function will update new from index for LP to last claimed id + 1. If the current
     * share pointer is not at the end of the LP's shares over time array, and if the new from index
     * is equivalent to the index where shares were then added/removed by LP, then increment share pointer.
     * @param _lpInfo Storage struct of LpInfo passed into function
     * @param _lastIdxFromUserInput Last claimable index passed by user into claims
     * @param _currSharePtr Current pointer for shares over time array for LP
     * @param _sharesUnchangedUntilLoanIdx Loan index where the number of shares owned by LP changed.
     */
    function checkSharePtrIncrement(
        LpInfo storage _lpInfo,
        uint256 _lastIdxFromUserInput,
        uint256 _currSharePtr,
        uint256 _sharesUnchangedUntilLoanIdx
    ) internal {
        // update LPs from loan index
        _lpInfo.fromLoanIdx = uint32(_lastIdxFromUserInput) + 1;
        // if current share pointer is not already at end and
        // the last loan claimed was exactly one below the currentToLoanIdx
        // then increment the current share pointer
        if (
            _currSharePtr < _lpInfo.sharesOverTime.length - 1 &&
            _lastIdxFromUserInput + 1 == _sharesUnchangedUntilLoanIdx
        ) {
            unchecked {
                _lpInfo.currSharePtr++;
            }
        }
    }

    /**
     * @notice Function which performs check and possibly updates lpInfo when claiming
     * @dev This function will update first check if the current share pointer for the LP
     * is pointing to a zero value. In that case, pointer will be incremented (since pointless to claim for
     * zero shares) and fromLoanIdx is then updated accordingly from LP's loanIdxWhereSharesChanged array.
     * Other checks are then performed to make sure that LP is entitled to claim from indices sent in.
     * @param _startIndex Start index sent in by user when claiming
     * @param _endIndex Last claimable index passed by user into claims
     * @param _lpInfo Current LpInfo struct passed in as storage
     * @return _sharesUnchangedUntilLoanIdx The index up to which the LP did not change shares
     * @return _applicableShares The number of shares to use in the claiming calculation
     */
    function claimsChecksAndSetters(
        uint256 _startIndex,
        uint256 _endIndex,
        LpInfo storage _lpInfo
    )
        internal
        returns (
            uint256 _sharesUnchangedUntilLoanIdx,
            uint256 _applicableShares
        )
    {
        /*
         * check if reasonable to automatically increment share pointer for intermediate period with zero shares
         * and push fromLoanIdx forward
         * Note: Since there is an offset of length 1 for the sharesOverTime and loanIdxWhereSharesChanged
         * this is why the fromLoanIdx needs to be updated before the current share pointer increments
         **/
        uint256 currSharePtr = _lpInfo.currSharePtr;
        if (_lpInfo.sharesOverTime[currSharePtr] == 0) {
            // if share ptr at end of shares over time array, then LP still has 0 shares and should revert right away
            if (currSharePtr == _lpInfo.sharesOverTime.length - 1)
                revert ZeroShareClaim();
            _lpInfo.fromLoanIdx = uint32(
                _lpInfo.loanIdxsWhereSharesChanged[currSharePtr]
            );
            unchecked {
                currSharePtr = ++_lpInfo.currSharePtr;
            }
        }

        /*
         * first loan index (which is what _fromLoanIdx will become)
         * cannot be less than lpInfo.fromLoanIdx (double-claiming or not entitled since
         * wasn't invested during that time), unless special case of first loan globally
         * and LpInfo.fromLoanIdx is 1
         * Note: This still works for claim, since in that function startIndex !=0 is already
         * checked, so second part is always true in claim function
         **/
        if (
            _startIndex < _lpInfo.fromLoanIdx &&
            !(_startIndex == 0 && _lpInfo.fromLoanIdx == 1)
        ) revert UnentitledFromLoanIdx();

        // infer applicable upper loan idx for which number of shares didn't change
        _sharesUnchangedUntilLoanIdx = currSharePtr ==
            _lpInfo.sharesOverTime.length - 1
            ? loanIdx
            : _lpInfo.loanIdxsWhereSharesChanged[currSharePtr];

        // check passed last loan idx is consistent with constant share interval
        if (_endIndex >= _sharesUnchangedUntilLoanIdx)
            revert LoanIdxsWithChangingShares();

        // get applicable number of shares for pro-rata calculations (given current share pointer position)
        _applicableShares = _lpInfo.sharesOverTime[currSharePtr];
    }

    /**
     * @notice Function which transfers collateral and repayments of claims and reinvests
     * @dev This function will reinvest the loan currency only (and only of course if _isReinvested is true)
     * @param _onBehalfOf LP address which is owner or has approved sender to claim on their behalf (and possibly reinvest)
     * @param _repayments Total repayments (loan currency) after all claims processed
     * @param _collateral Total collateral (collateral currency) after all claims processed
     * @param _isReinvested Flag for if LP wants claimed loanCcy to be re-invested
     */
    function claimTransferAndReinvestment(
        address _onBehalfOf,
        uint256 _repayments,
        uint256 _collateral,
        bool _isReinvested
    ) internal {
        if (_repayments > 0) {
            if (_isReinvested) {
                // allows reinvestment and transfer of any dust from claim functions
                (
                    uint256 dust,
                    uint256 newLpShares,
                    uint32 earliestRemove
                ) = _addLiquidity(_onBehalfOf, _repayments);
                if (dust > 0) {
                    IERC20Metadata(loanCcyToken).safeTransfer(
                        poolCreator,
                        dust
                    );
                }
                // spawn event
                emit Reinvest(
                    _onBehalfOf,
                    _repayments,
                    newLpShares,
                    earliestRemove,
                    loanIdx
                );
            } else {
                IERC20Metadata(loanCcyToken).safeTransfer(
                    msg.sender,
                    _repayments
                );
            }
        }
        // transfer collateral
        if (_collateral > 0) {
            IERC20Metadata(collCcyToken).safeTransfer(msg.sender, _collateral);
        }
    }

    /**
     * @notice Helper function when adding liquidity
     * @dev This function is called by addLiquidity, but also
     * by claimants who would like to reinvest their loanCcy
     * portion of the claim
     * @param _onBehalfOf Recipient of the LP shares
     * @param _inAmountAfterFees Net amount of what was sent by LP minus fees
     * @return dust If no LP shares, dust is any remaining excess liquidity (i.e. minLiquidity and rounding)
     * @return newLpShares Amount of new LP shares to be credited to LP.
     * @return earliestRemove Earliest timestamp from which LP is allowed to remove liquidity
     */
    function _addLiquidity(
        address _onBehalfOf,
        uint256 _inAmountAfterFees
    )
        internal
        returns (uint256 dust, uint256 newLpShares, uint32 earliestRemove)
    {
        uint256 _totalLiquidity = totalLiquidity;
        if (_inAmountAfterFees < minLiquidity / 1000) revert InvalidAddAmount();
        // retrieve lpInfo of sender
        LpInfo storage lpInfo = addrToLpInfo[_onBehalfOf];

        // calculate new lp shares
        if (totalLpShares == 0) {
            dust = _totalLiquidity;
            _totalLiquidity = 0;
            newLpShares = (_inAmountAfterFees * 1000) / minLiquidity;
        } else {
            assert(_totalLiquidity > 0);
            newLpShares =
                (_inAmountAfterFees * totalLpShares) /
                _totalLiquidity;
        }
        if (newLpShares == 0 || uint128(newLpShares) != newLpShares)
            revert InvalidAddAmount();
        totalLpShares += uint128(newLpShares);
        totalLiquidity = _totalLiquidity + _inAmountAfterFees;
        // update LP info
        bool isFirstAddLiquidity = lpInfo.fromLoanIdx == 0;
        if (isFirstAddLiquidity) {
            lpInfo.fromLoanIdx = uint32(loanIdx);
            lpInfo.sharesOverTime.push(newLpShares);
        } else {
            // update both LP arrays and check for auto increment
            updateLpArrays(lpInfo, newLpShares, true);
        }
        earliestRemove = uint32(block.timestamp + MIN_LPING_PERIOD);
        lpInfo.earliestRemove = earliestRemove;
        // keep track of add timestamp per tx origin to check for atomic add and borrows/rollOvers
        lastAddOfTxOrigin[tx.origin] = block.timestamp;
    }

    /**
     * @notice Function which updates array (and possibly array pointer) info
     * @dev There are many different cases depending on if shares over time is length 1,
     * if the LP fromLoanId = loanIdx, if last value of loanIdxsWhereSharesChanged = loanIdx,
     * and possibly on the value of the penultimate shares over time array = newShares...
     * further discussion of all cases is provided in gitbook documentation
     * @param _lpInfo Struct of the info for the current LP
     * @param _newLpShares Amount of new LP shares to add/remove from current LP position
     * @param _add Flag that allows for addition of shares for addLiquidity and subtraction for remove.
     */
    function updateLpArrays(
        LpInfo storage _lpInfo,
        uint256 _newLpShares,
        bool _add
    ) internal {
        uint256 _loanIdx = loanIdx;
        uint256 _originalSharesLen = _lpInfo.sharesOverTime.length;
        uint256 _originalLoanIdxsLen = _originalSharesLen - 1;
        uint256 currShares = _lpInfo.sharesOverTime[_originalSharesLen - 1];
        uint256 newShares = _add
            ? currShares + _newLpShares
            : currShares - _newLpShares;
        bool loanCheck = (_originalLoanIdxsLen > 0 &&
            _lpInfo.loanIdxsWhereSharesChanged[_originalLoanIdxsLen - 1] ==
            _loanIdx);
        // if LP has claimed all possible loans that were taken out (fromLoanIdx = loanIdx)
        if (_lpInfo.fromLoanIdx == _loanIdx) {
            /**
                if shares length has one value, OR
                if loanIdxsWhereSharesChanged array is non empty
                and the last value of the array is equal to current loanId
                then we go ahead and overwrite the lastShares array.
                We do not have to worry about popping array in second case
                because since fromLoanIdx == loanIdx, we know currSharePtr is
                already at end of the array, and therefore can never get stuck
            */
            if (_originalSharesLen == 1 || loanCheck) {
                _lpInfo.sharesOverTime[_originalSharesLen - 1] = newShares;
            }
            /**
            if loanIdxsWhereSharesChanged array is non empty
            and the last value of the array is NOT equal to current loanId
            then we go ahead and push a new value onto both arrays and increment currSharePtr
            we can safely increment share pointer because we know if fromLoanIdx is == loanIdx
            then currSharePtr has to already be length of original shares over time array - 1 and
            we want to keep it at end of the array 
            */
            else {
                pushLpArrays(_lpInfo, newShares, _loanIdx);
                unchecked {
                    _lpInfo.currSharePtr++;
                }
            }
        }
        /**
            fromLoanIdx is NOT equal to loanIdx in this case, but
            loanIdxsWhereSharesChanged array is non empty
            and the last value of the array is equal to current loanId.        
        */
        else if (loanCheck) {
            /**
                The value in the shares array before the last array
                In this case we are going to pop off the last values.
                Since we know that if currSharePtr was at end of array and loan id is still equal to last value
                on the loanIdxsWhereSharesUnchanged array, this would have meant that fromLoanIdx == loanIdx
                and hence, no need to check if currSharePtr needs to decrement
            */
            if (_lpInfo.sharesOverTime[_originalSharesLen - 2] == newShares) {
                _lpInfo.sharesOverTime.pop();
                _lpInfo.loanIdxsWhereSharesChanged.pop();
            }
            // if next to last shares over time value is not same as newShares,
            // then just overwrite last share value
            else {
                _lpInfo.sharesOverTime[_originalSharesLen - 1] = newShares;
            }
        } else {
            // if the previous conditions are not met then push newShares onto shares over time array
            // and push global loan index onto loanIdxsWhereSharesChanged
            pushLpArrays(_lpInfo, newShares, _loanIdx);
        }
    }

    /**
     * @notice Helper function that pushes onto both LP Info arrays
     * @dev This function is called by updateLpArrays function in two cases when both
     * LP Info arrays, sharesOverTime and loanIdxsWhereSharesChanged, are pushed onto
     * @param _lpInfo Struct of the info for the current LP
     * @param _newShares New amount of LP shares pushed onto sharesOverTime array
     * @param _loanIdx Current global loanIdx pushed onto loanIdxsWhereSharesChanged array
     */
    function pushLpArrays(
        LpInfo storage _lpInfo,
        uint256 _newShares,
        uint256 _loanIdx
    ) internal {
        _lpInfo.sharesOverTime.push(_newShares);
        _lpInfo.loanIdxsWhereSharesChanged.push(_loanIdx);
    }

    /**
     * @notice Helper function when user is borrowing
     * @dev This function is called by borrow and rollover
     * @param _inAmountAfterFees Net amount of what was sent by borrower minus fees
     * @param _minLoanLimit Minimum loan currency amount acceptable to borrower
     * @param _maxRepayLimit Maximum allowable loan currency amount borrower is willing to repay
     * @param _timestamp Time that is used to set loan expiry
     * @return loanAmount Amount of loan Ccy given to the borrower
     * @return repaymentAmount Amount of loan Ccy borrower needs to repay to claim collateral
     * @return pledgeAmount Amount of collCcy reclaimable upon repayment
     * @return expiry Timestamp after which loan expires
     * @return _creatorFee Per transaction fee which levied for using the protocol
     * @return _totalLiquidity Updated total liquidity (pre-borrow)
     */
    function _borrow(
        uint128 _inAmountAfterFees,
        uint128 _minLoanLimit,
        uint128 _maxRepayLimit,
        uint256 _timestamp
    )
        internal
        view
        returns (
            uint128 loanAmount,
            uint128 repaymentAmount,
            uint128 pledgeAmount,
            uint32 expiry,
            uint256 _creatorFee,
            uint256 _totalLiquidity
        )
    {
        // get and verify loan terms
        (
            loanAmount,
            repaymentAmount,
            pledgeAmount,
            _creatorFee,
            _totalLiquidity
        ) = loanTerms(_inAmountAfterFees);
        assert(_inAmountAfterFees != 0); // if 0 must have failed in loanTerms(...)
        if (loanAmount < _minLoanLimit) revert LoanBelowLimit();
        if (repaymentAmount > _maxRepayLimit) revert RepaymentAboveLimit();
        expiry = uint32(_timestamp + loanTenor);
    }

    /**
     * @notice Helper function called whenever a function needs to check a deadline
     * @dev This function is called by addLiquidity, borrow, rollover, and if reinvestment on claiming,
     * it will be called by claimReinvestmentCheck
     * @param _deadline Last timestamp after which function will revert
     * @return timestamp Current timestamp passed back to function
     */
    function checkTimestamp(
        uint256 _deadline
    ) internal view returns (uint256 timestamp) {
        timestamp = block.timestamp;
        if (timestamp > _deadline) revert PastDeadline();
    }

    /**
     * @notice Helper function called whenever reinvestment is possible
     * @dev This function is called by claim and claimFromAggregated if reinvestment is desired
     * @param _deadline Last timestamp after which function will revert
     * @param _onBehalfOf Recipient of the reinvested LP shares
     */
    function claimReinvestmentCheck(
        uint256 _deadline,
        address _onBehalfOf
    ) internal view {
        checkTimestamp(_deadline);
        checkSenderApproval(_onBehalfOf, IBasePool.ApprovalTypes.ADD_LIQUIDITY);
    }

    /**
     * @notice Helper function checks if function caller is a valid sender
     * @dev This function is called by addLiquidity, removeLiquidity, repay,
     * rollOver, claim, claimFromAggregated, claimReinvestmentCheck (ADD_LIQUIDITY)
     * @param _ownerOrBeneficiary Address which will be owner or beneficiary of transaction if approved
     * @param _approvalType Type of approval requested { REPAY, ROLLOVER, ADD_LIQUIDITY, REMOVE_LIQUIDITY, CLAIM }
     */
    function checkSenderApproval(
        address _ownerOrBeneficiary,
        IBasePool.ApprovalTypes _approvalType
    ) internal view {
        if (
            !(_ownerOrBeneficiary == msg.sender ||
                isApproved[_ownerOrBeneficiary][msg.sender][_approvalType])
        ) revert UnapprovedSender();
    }

    /**
     * @notice Helper function used by claim function
     * @dev This function is called by claim to check the passed array
     * is valid and return the repayment and collateral amounts
     * @param _loanIdxs Array of loan Idxs over which the LP would like to claim
     * @param arrayLen Length of the loanIdxs array
     * @param _shares The LP shares owned by the LP during the period of the claims
     * @return repayments The amount of loanCcy over claims to which LP is entitled
     * @return collateral The amount of collCcy over claims to which LP is entitled
     */
    function getClaimsFromList(
        uint256[] calldata _loanIdxs,
        uint256 arrayLen,
        uint256 _shares
    ) internal view returns (uint256 repayments, uint256 collateral) {
        // aggregate claims from list
        for (uint256 i = 0; i < arrayLen; ) {
            LoanInfo memory loanInfo = loanIdxToLoanInfo[_loanIdxs[i]];
            if (i > 0) {
                if (_loanIdxs[i] <= _loanIdxs[i - 1])
                    revert NonAscendingLoanIdxs();
            }
            if (loanInfo.repaid) {
                repayments +=
                    (loanInfo.repayment * BASE) /
                    loanInfo.totalLpShares;
            } else if (loanInfo.expiry < block.timestamp) {
                collateral +=
                    (loanInfo.collateral * BASE) /
                    loanInfo.totalLpShares;
            } else {
                revert CannotClaimWithUnsettledLoan();
            }
            unchecked {
                i++;
            }
        }
        // return claims
        repayments = (repayments * _shares) / BASE;
        collateral = (collateral * _shares) / BASE;
    }

    /**
     * @notice Function that returns the pool's rate given _liquidity to calculate
     * a loan's repayment amount.
     * @dev The rate is defined as a piecewise function with 3 ranges:
     * (1) low liquidity range: here the rate is defined as a reciprocal function
     * (2) target liquidity range: here the rate is linear
     * (3) high liquidity range: here the rate is constant
     * @param _liquidity The liquidity level for which the rate shall be calculated
     * @return rate The applicable rate
     */
    function getRate(uint256 _liquidity) internal view returns (uint256 rate) {
        if (_liquidity < liquidityBnd1) {
            rate = (r1 * liquidityBnd1) / _liquidity;
        } else if (_liquidity <= liquidityBnd2) {
            rate =
                r2 +
                ((r1 - r2) * (liquidityBnd2 - _liquidity)) /
                (liquidityBnd2 - liquidityBnd1);
        } else {
            rate = r2;
        }
    }

    /**
     * @notice Function which checks and returns loan ccy send amount after fees
     * @param _sendAmount Amount of loanCcy to be transferred
     * @param lowerBnd Minimum amount which is expected to be received at least
     */
    function checkAndGetSendAmountAfterFees(
        uint128 _sendAmount,
        uint128 lowerBnd
    ) internal view returns (uint128 sendAmountAfterFees) {
        sendAmountAfterFees = _sendAmount - getLoanCcyTransferFee(_sendAmount);
        // check range in case of rounding exact lowerBnd amount
        // cannot be hit; set upper bound to prevent fat finger
        if (
            sendAmountAfterFees < lowerBnd ||
            sendAmountAfterFees > (101 * lowerBnd) / 100
        ) revert InvalidSendAmount();
        return sendAmountAfterFees;
    }

    /**
     * @notice Function which gets fees (if any) on the collCcy
     * @param _transferAmount Amount of collCcy to be transferred
     */
    function getCollCcyTransferFee(
        uint128 _transferAmount
    ) internal view virtual returns (uint128);

    /**
     * @notice Function which gets fees (if any) on the loanCcy
     * @param _transferAmount Amount of loanCcy to be transferred
     */
    function getLoanCcyTransferFee(
        uint128 _transferAmount
    ) internal view virtual returns (uint128);
}
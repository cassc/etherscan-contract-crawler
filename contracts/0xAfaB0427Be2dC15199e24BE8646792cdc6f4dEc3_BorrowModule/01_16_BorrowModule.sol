// SPDX-License-Identifier: bsl-1.1
/**
 * Copyright 2022 Unit Protocol V2: Artem Zakharov ([email protected]).
 */
pragma solidity ^0.8.0;
pragma abicoder v2;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";
import "@openzeppelin/contracts/utils/math/Math.sol";

import "./Auth.sol";
import "./Parameters.sol";
import "./Assets.sol";


contract BorrowModule is IVersioned, Auth, ReentrancyGuard {
    using Parameters for IParametersStorage;
    using Assets for address;
    using EnumerableSet for EnumerableSet.UintSet;

    string public constant VERSION = '0.1.0';

    enum LoanState { WasNotCreated, AuctionStarted, AuctionCancelled, Issued, Finished, Liquidated }

    struct AuctionInfo {
        address borrower;
        uint32 startTS;
        uint16 interestRateMin;
        uint16 interestRateMax;
    }

    struct Loan {
        // slot 256 bits (Nested struct takes up the whole slot. We have to do this since error "Stack too deep..")
        AuctionInfo auctionInfo;

        // slot 240 bits
        LoanState state;
        uint16 durationDays;
        uint32 startTS;
        uint16 interestRate;
        address collateral;
        Assets.AssetType collateralType;

        // slot 256 bits
        uint collateralIdOrAmount;

        // slot 160 bits
        address lender;

        // slot 160 bits
        address debtCurrency;

        // slot 256 bits
        uint debtAmount;
    }

    struct AuctionStartParams {
        uint16 durationDays;

        uint16 interestRateMin;
        uint16 interestRateMax;

        address collateral;
        Assets.AssetType collateralType;
        uint collateralIdOrAmount;

        address debtCurrency;
        uint debtAmount;
    }

    event AuctionStarted(uint indexed loanId, address indexed borrower);
    event AuctionInterestRateMaxUpdated(uint indexed loanId, address indexed borrower, uint16 newInterestRateMax);
    event AuctionCancelled(uint indexed loanId, address indexed borrower);

    event LoanIssued(uint indexed loanId, address indexed lender);
    event LoanRepaid(uint indexed loanId, address indexed borrower);
    event LoanLiquidated(uint indexed loanId, address indexed liquidator);

    uint public constant BASIS_POINTS_IN_1 = 1e4;
    uint public constant MAX_DURATION_DAYS = 365 * 2;

    Loan[] public loans;
    mapping(address => uint[]) public loanIdsByUser;
    EnumerableSet.UintSet private activeAuctions;
    EnumerableSet.UintSet private activeLoans;

    constructor(address _parametersStorage) Auth(_parametersStorage) {}

    function startAuction(AuctionStartParams memory _params) external nonReentrant returns (uint _loanId) {
        require(0 < _params.durationDays &&_params.durationDays <= MAX_DURATION_DAYS, 'UP borrow module: INVALID_LOAN_DURATION');
        require(0 < _params.interestRateMin && _params.interestRateMin <= _params.interestRateMax, 'UP borrow module: INVALID_INTEREST_RATE');
        require(_params.collateral != address(0), 'UP borrow module: INVALID_COLLATERAL');
        require(_params.collateralType != Assets.AssetType.Unknown, 'UP borrow module: INVALID_COLLATERAL_TYPE');
        require(_params.collateralType == Assets.AssetType.ERC721 || _params.collateralIdOrAmount > 0, 'UP borrow module: INVALID_COLLATERAL_AMOUNT');
        require(_params.debtCurrency != address(0) && _params.debtAmount > 0, 'UP borrow module: INVALID_DEBT_CURRENCY');
        _calcTotalDebt(_params.debtAmount, _params.interestRateMax, _params.durationDays); // just check that there is no overflow on total debt

        _loanId = loans.length;
        loans.push(
            Loan(
                AuctionInfo(
                    msg.sender,
                    uint32(block.timestamp),
                    _params.interestRateMin,
                    _params.interestRateMax
                ),

                LoanState.AuctionStarted,
                _params.durationDays,
                0, // startTS
                0, // interestRate
                _params.collateral,
                _params.collateralType,

                _params.collateralIdOrAmount,

                address(0),

                _params.debtCurrency,

                _params.debtAmount
            )
        );

        loanIdsByUser[msg.sender].push(_loanId);
        require(activeAuctions.add(_loanId), 'UP borrow module: BROKEN_STRUCTURE');

        _params.collateral.getFrom(_params.collateralType, msg.sender, address(this), _params.collateralIdOrAmount);

        emit AuctionStarted(_loanId, msg.sender);
    }

    function updateAuctionInterestRateMax(uint _loanId, uint16 _newInterestRateMax) external nonReentrant {
        Loan storage loan = requireLoan(_loanId);
        require(loan.auctionInfo.borrower == msg.sender, 'UP borrow module: AUTH_FAILED');
        require(loan.state == LoanState.AuctionStarted, 'UP borrow module: INVALID_LOAN_STATE');
        require(loan.auctionInfo.startTS + parameters.getAuctionDuration() <= block.timestamp, 'UP borrow module: TOO_EARLY_UPDATE');
        require(_newInterestRateMax > loan.auctionInfo.interestRateMax, 'UP borrow module: NEW_RATE_TOO_SMALL');

        loan.auctionInfo.interestRateMax = _newInterestRateMax;

        emit AuctionInterestRateMaxUpdated(_loanId, msg.sender, _newInterestRateMax);
    }

    function cancelAuction(uint _loanId) external nonReentrant {
        Loan storage loan = requireLoan(_loanId);
        require(loan.auctionInfo.borrower == msg.sender, 'UP borrow module: AUTH_FAILED');

        changeLoanState(loan, LoanState.AuctionCancelled);
        require(activeAuctions.remove(_loanId), 'UP borrow module: BROKEN_STRUCTURE');

        loan.collateral.sendTo(loan.collateralType, loan.auctionInfo.borrower, loan.collateralIdOrAmount);

        emit AuctionCancelled(_loanId, msg.sender);
    }

    /**
     * @dev acceptance after auction ended is allowed
     */
    function accept(uint _loanId) external nonReentrant {
        Loan storage loan = requireLoan(_loanId);

        require(loan.auctionInfo.borrower != msg.sender, 'UP borrow module: OWN_AUCTION');

        changeLoanState(loan, LoanState.Issued);
        require(activeAuctions.remove(_loanId), 'UP borrow module: BROKEN_STRUCTURE');
        require(activeLoans.add(_loanId), 'UP borrow module: BROKEN_STRUCTURE');

        loan.startTS = uint32(block.timestamp);
        loan.lender = msg.sender;
        loan.interestRate =  _calcCurrentInterestRate(loan.auctionInfo.startTS, loan.auctionInfo.interestRateMin, loan.auctionInfo.interestRateMax);

        loanIdsByUser[msg.sender].push(_loanId);

        (uint feeAmount, uint operatorFeeAmount, uint amountWithoutFee) = _calcFeeAmount(loan.debtCurrency, loan.debtAmount);

        loan.debtCurrency.getFrom(Assets.AssetType.ERC20, msg.sender, address(this), loan.debtAmount);
        if (feeAmount > 0) {
            loan.debtCurrency.sendTo(Assets.AssetType.ERC20, parameters.treasury(), feeAmount);
        }
        if (operatorFeeAmount > 0) {
            loan.debtCurrency.sendTo(Assets.AssetType.ERC20, parameters.operatorTreasury(), operatorFeeAmount);
        }
        loan.debtCurrency.sendTo(Assets.AssetType.ERC20, loan.auctionInfo.borrower, amountWithoutFee);

        emit LoanIssued(_loanId, msg.sender);
    }

    /**
     * @notice Repay loan debt. In any time debt + full interest rate for loan period must be repaid.
     * MUST be repaid before loan period end to avoid liquidations. MAY be repaid after loan period end, but before liquidation.
     */
    function repay(uint _loanId) external nonReentrant {
        Loan storage loan = requireLoan(_loanId);
        require(loan.auctionInfo.borrower == msg.sender, 'UP borrow module: AUTH_FAILED');

        changeLoanState(loan, LoanState.Finished);
        require(activeLoans.remove(_loanId), 'UP borrow module: BROKEN_STRUCTURE');

        uint totalDebt = _calcTotalDebt(loan.debtAmount, loan.interestRate, loan.durationDays);
        loan.debtCurrency.getFrom(Assets.AssetType.ERC20, msg.sender, loan.lender, totalDebt);
        loan.collateral.sendTo(loan.collateralType, loan.auctionInfo.borrower, loan.collateralIdOrAmount);

        emit LoanRepaid(_loanId, msg.sender);
    }

    function liquidate(uint _loanId) external nonReentrant {
        Loan storage loan = requireLoan(_loanId);

        changeLoanState(loan, LoanState.Liquidated);
        require(uint(loan.startTS) + uint(loan.durationDays) * 1 days < block.timestamp, 'UP borrow module: LOAN_IS_ACTIVE');
        require(activeLoans.remove(_loanId), 'UP borrow module: BROKEN_STRUCTURE');

        loan.collateral.sendTo(loan.collateralType, loan.lender, loan.collateralIdOrAmount);

        emit LoanLiquidated(_loanId, msg.sender);
    }

    function requireLoan(uint _loanId) internal view returns (Loan storage _loan) {
        require(_loanId < loans.length, 'UP borrow module: INVALID_LOAN_ID');
        _loan = loans[_loanId];
    }

    function changeLoanState(Loan storage _loan, LoanState _newState) internal {
        LoanState currentState = _loan.state;
        if (currentState == LoanState.AuctionStarted) {
            require(_newState == LoanState.AuctionCancelled || _newState == LoanState.Issued, 'UP borrow module: INVALID_LOAN_STATE');
        } else if (currentState == LoanState.Issued) {
            require(_newState == LoanState.Finished || _newState == LoanState.Liquidated, 'UP borrow module: INVALID_LOAN_STATE');
        } else if (currentState == LoanState.AuctionCancelled || currentState == LoanState.Finished || currentState == LoanState.Liquidated) {
            revert('UP borrow module: INVALID_LOAN_STATE');
        } else {
            revert('UP borrow module: BROKEN_LOGIC'); // just to be sure that all states are covered
        }

        _loan.state = _newState;
    }

    //////

    function getLoansCount() external view returns (uint) {
        return loans.length;
    }

    /**
     * @dev may not work on huge amount of loans, in this case use version with limits
     */
    function getLoans() external view returns(Loan[] memory) {
        return loans;
    }

    /**
     * @dev returns empty array with offset >= count
     */
    function getLoansLimited(uint _offset, uint _limit) external view returns(Loan[] memory _loans) {
        uint loansCount = loans.length;
        if (_offset > loansCount) {
            return new Loan[](0);
        }

        uint resultCount = Math.min(loansCount - _offset, _limit);
        _loans = new Loan[](resultCount);
        for (uint i = 0; i < resultCount; i++) {
            _loans[i] = loans[_offset + i];
        }
    }

    //////

    function getActiveAuctionsCount() public view returns (uint) {
        return activeAuctions.length();
    }

    /**
     * @dev may not work on huge amount of loans, in this case use version with limits
     */
    function getActiveAuctions() public view returns (uint[] memory _ids, Loan[] memory _loans) {
        return _getLoansWithIds(activeAuctions);
    }

    /**
     * @dev returns empty arrays with offset >= count
     */
    function getActiveAuctionsLimited(uint _offset, uint _limit) public view returns (uint[] memory _ids, Loan[] memory _loans) {
        return _getLoansWithIdsLimited(activeAuctions, _offset, _limit);
    }

    //////

    function getActiveLoansCount() public view returns (uint) {
        return activeLoans.length();
    }

    /**
     * @dev may not work on huge amount of loans, in this case use version with limits
     */
    function getActiveLoans() public view returns (uint[] memory _ids, Loan[] memory _loans) {
        return _getLoansWithIds(activeLoans);
    }

    /**
     * @dev returns empty arrays with offset >= count
     */
    function getActiveLoansLimited(uint _offset, uint _limit) public view returns (uint[] memory _ids, Loan[] memory _loans) {
        return _getLoansWithIdsLimited(activeLoans, _offset, _limit);
    }

    //////

    function getUserLoansCount(address _user) public view returns (uint) {
        return loanIdsByUser[_user].length;
    }

    /**
     * @dev may not work on huge amount of loans, in this case use version with limits
     */
    function getUserLoans(address _user) external view returns(uint[] memory _ids, Loan[] memory _loans) {
        _ids = loanIdsByUser[_user];
        _loans = new Loan[](_ids.length);
        for (uint i=0; i<_ids.length; i++) {
            _loans[i] = loans[ _ids[i] ];
        }
    }

    /**
     * @dev returns empty arrays with offset >= count
     */
    function getUserLoansLimited(address _user, uint _offset, uint _limit) public view returns (uint[] memory _ids, Loan[] memory _loans) {
        uint loansCount = loanIdsByUser[_user].length;
        if (_offset > loansCount) {
            return (new uint[](0), new Loan[](0));
        }

        uint resultCount = Math.min(loansCount - _offset, _limit);
        _ids = new uint[](resultCount);
        _loans = new Loan[](resultCount);
        for (uint i = 0; i < resultCount; i++) {
            _ids[i] = loanIdsByUser[_user][_offset + i];
            _loans[i] = loans[ _ids[i] ];
        }
    }


    //////

    function _calcFeeAmount(address _asset, uint _amount) internal view returns (uint _feeAmount, uint _operatorFeeAmount, uint _amountWithoutFee) {
        uint feeBasisPoints = parameters.getAssetFee(_asset);
        uint _totalFeeAmount = _amount * feeBasisPoints / BASIS_POINTS_IN_1;

        _operatorFeeAmount = _totalFeeAmount * parameters.operatorFeePercent() / 100;
        _feeAmount = _totalFeeAmount - _operatorFeeAmount;

        _amountWithoutFee = _amount - _totalFeeAmount;

        require(_amount == _feeAmount + _operatorFeeAmount + _amountWithoutFee, 'UP borrow module: BROKEN_FEE_LOGIC'); // assert
    }

    function _calcTotalDebt(uint debtAmount, uint interestRateBasisPoints, uint durationDays) internal pure returns (uint) {
        return debtAmount + debtAmount * interestRateBasisPoints * durationDays / BASIS_POINTS_IN_1 / 365;
    }

    function _calcCurrentInterestRate(uint auctionStartTS, uint16 interestRateMin, uint16 interestRateMax) internal view returns (uint16) {
        require(auctionStartTS < block.timestamp, 'UP borrow module: TOO_EARLY');
        require(0 < interestRateMin && interestRateMin <= interestRateMax, 'UP borrow module: INVALID_INTEREST_RATES'); // assert

        uint auctionEndTs = auctionStartTS + parameters.getAuctionDuration();
        uint onTime = Math.min(block.timestamp, auctionEndTs);

        return interestRateMin + uint16((interestRateMax - interestRateMin) * (onTime - auctionStartTS) / (auctionEndTs - auctionStartTS));
    }

    //////

    function _getLoansWithIds(EnumerableSet.UintSet storage _loansSet) internal view returns (uint[] memory _ids, Loan[] memory _loans) {
        _ids = _loansSet.values();
        _loans = new Loan[](_ids.length);
        for (uint i=0; i<_ids.length; i++) {
            _loans[i] = loans[ _ids[i] ];
        }
    }

    function _getLoansWithIdsLimited(EnumerableSet.UintSet storage _loansSet, uint _offset, uint _limit) internal view returns (uint[] memory _ids, Loan[] memory _loans) {
        uint loansCount = _loansSet.length();
        if (_offset > loansCount) {
            return (new uint[](0), new Loan[](0));
        }

        uint resultCount = Math.min(loansCount - _offset, _limit);
        _ids = new uint[](resultCount);
        _loans = new Loan[](resultCount);
        for (uint i = 0; i < resultCount; i++) {
            _ids[i] = _loansSet.at(_offset + i);
            _loans[i] = loans[ _ids[i] ];
        }
    }

    //////

    function onERC721Received(
        address operator,
        address /* from */,
        uint256 /* tokenId */,
        bytes calldata /* data */
    ) external view returns (bytes4) {
        require(operator == address(this), "UP borrow module: TRANSFER_NOT_ALLOWED");

        return IERC721Receiver.onERC721Received.selector;
    }
}
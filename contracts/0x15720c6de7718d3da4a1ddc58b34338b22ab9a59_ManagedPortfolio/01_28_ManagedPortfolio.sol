// SPDX-License-Identifier: MIT
pragma solidity 0.8.10;

import {ERC20Upgradeable} from "ERC20Upgradeable.sol";
import {IERC721Receiver} from "IERC721Receiver.sol";
import {IManagedPortfolio, ManagedPortfolioStatus} from "IManagedPortfolio.sol";
import {IERC20WithDecimals} from "IERC20WithDecimals.sol";
import {SafeERC20} from "SafeERC20.sol";
import {IBulletLoans, BulletLoanStatus} from "IBulletLoans.sol";
import {IProtocolConfig} from "IProtocolConfig.sol";
import {ILenderVerifier} from "ILenderVerifier.sol";
import {InitializableManageable} from "InitializableManageable.sol";

contract ManagedPortfolio is ERC20Upgradeable, InitializableManageable, IERC721Receiver, IManagedPortfolio {
    using SafeERC20 for IERC20WithDecimals;

    uint256 internal constant YEAR = 365 days;
    uint256 public constant MAX_LOANS_NUMBER = 100;

    uint256[] private _loans;

    IERC20WithDecimals public underlyingToken;
    IBulletLoans public bulletLoans;
    IProtocolConfig public protocolConfig;
    ILenderVerifier public lenderVerifier;

    uint256 public endDate;
    uint256 public maxSize;
    uint256 public totalDeposited;
    uint256 public latestRepaymentDate;
    uint256 public defaultedLoansCount;
    uint256 public managerFee;
    bool public paused;

    event Deposited(address indexed lender, uint256 amount);

    event Withdrawn(address indexed lender, uint256 sharesAmount, uint256 receivedAmount);

    event BulletLoanCreated(uint256 id, uint256 loanDuration, address borrower, uint256 principalAmount, uint256 repaymentAmount);

    event BulletLoanDefaulted(uint256 id);

    event ManagerFeeChanged(uint256 newManagerFee);

    event MaxSizeChanged(uint256 newMaxSize);

    event EndDateChanged(uint256 newEndDate);

    event LenderVerifierChanged(ILenderVerifier newLenderVerifier);

    event Paused();

    event Unpaused();

    modifier onlyOpened() {
        require(getStatus() == ManagedPortfolioStatus.Open, "ManagedPortfolio: Portfolio is not opened");
        _;
    }

    modifier onlyClosed() {
        require(getStatus() == ManagedPortfolioStatus.Closed, "ManagedPortfolio: Portfolio is not closed");
        _;
    }

    modifier whenNotPaused() {
        require(!paused, "ManagedPortfolio: Portfolio is paused");
        _;
    }

    constructor() InitializableManageable(msg.sender) {}

    function initialize(
        string memory _name,
        string memory _symbol,
        address _manager,
        IERC20WithDecimals _underlyingToken,
        IBulletLoans _bulletLoans,
        IProtocolConfig _protocolConfig,
        ILenderVerifier _lenderVerifier,
        uint256 _duration,
        uint256 _maxSize,
        uint256 _managerFee
    ) external initializer {
        InitializableManageable.initialize(_manager);
        ERC20Upgradeable.__ERC20_init(_name, _symbol);
        underlyingToken = _underlyingToken;
        bulletLoans = _bulletLoans;
        protocolConfig = _protocolConfig;
        lenderVerifier = _lenderVerifier;
        endDate = block.timestamp + _duration;
        maxSize = _maxSize;
        managerFee = _managerFee;
    }

    function pause() external onlyManager {
        paused = true;
        emit Paused();
    }

    function unpause() external onlyManager {
        paused = false;
        emit Unpaused();
    }

    function deposit(uint256 depositAmount, bytes memory metadata) external onlyOpened whenNotPaused {
        require(lenderVerifier.isAllowed(msg.sender, depositAmount, metadata), "ManagedPortfolio: Lender is not allowed to deposit");
        require(depositAmount >= 10**underlyingToken.decimals(), "ManagedPortfolio: Deposit amount is too small");
        totalDeposited += depositAmount;
        require(totalDeposited <= maxSize, "ManagedPortfolio: Portfolio is full");

        _mint(msg.sender, getAmountToMint(depositAmount));
        underlyingToken.safeTransferFrom(msg.sender, address(this), depositAmount);

        emit Deposited(msg.sender, depositAmount);
    }

    function withdraw(uint256 sharesAmount, bytes memory) external onlyClosed whenNotPaused returns (uint256) {
        uint256 liquidFunds = underlyingToken.balanceOf(address(this));
        uint256 amountToWithdraw = (sharesAmount * liquidFunds) / totalSupply();
        _burn(msg.sender, sharesAmount);
        underlyingToken.safeTransfer(msg.sender, amountToWithdraw);

        emit Withdrawn(msg.sender, sharesAmount, amountToWithdraw);

        return amountToWithdraw;
    }

    function createBulletLoan(
        uint256 loanDuration,
        address borrower,
        uint256 principalAmount,
        uint256 repaymentAmount
    ) external onlyManager {
        require(getStatus() != ManagedPortfolioStatus.Closed, "ManagedPortfolio: Cannot create loan when Portfolio is closed");
        require(_loans.length < MAX_LOANS_NUMBER, "ManagedPortfolio: Maximum loans number has been reached");
        uint256 repaymentDate = block.timestamp + loanDuration;
        _onLoanRepaymentDateChange(repaymentDate);
        uint256 protocolFee = protocolConfig.protocolFee();
        uint256 managersPart = (managerFee * principalAmount * loanDuration) / YEAR / 10000;
        uint256 protocolsPart = (protocolFee * principalAmount * loanDuration) / YEAR / 10000;
        uint256 loanId = bulletLoans.createLoan(underlyingToken, principalAmount, repaymentAmount, loanDuration, borrower);
        _loans.push(loanId);

        underlyingToken.safeTransfer(borrower, principalAmount);
        underlyingToken.safeTransfer(manager, managersPart);
        underlyingToken.safeTransfer(protocolConfig.protocolAddress(), protocolsPart);

        emit BulletLoanCreated(loanId, loanDuration, borrower, principalAmount, repaymentAmount);
    }

    function setManagerFee(uint256 _managerFee) external onlyManager {
        managerFee = _managerFee;
        emit ManagerFeeChanged(_managerFee);
    }

    function setLenderVerifier(ILenderVerifier _lenderVerifier) external onlyManager {
        lenderVerifier = _lenderVerifier;
        emit LenderVerifierChanged(_lenderVerifier);
    }

    function setMaxSize(uint256 _maxSize) external onlyManager {
        maxSize = _maxSize;
        emit MaxSizeChanged(_maxSize);
    }

    function setEndDate(uint256 newEndDate) external onlyManager {
        require(newEndDate < endDate, "ManagedPortfolio: End date can only be decreased");
        require(newEndDate >= latestRepaymentDate, "ManagedPortfolio: End date cannot be less than max loan default date");
        endDate = newEndDate;
        emit EndDateChanged(newEndDate);
    }

    function value() public view returns (uint256) {
        return liquidValue() + illiquidValue();
    }

    function getStatus() public view returns (ManagedPortfolioStatus) {
        if (block.timestamp > endDate) {
            return ManagedPortfolioStatus.Closed;
        }
        if (defaultedLoansCount > 0) {
            return ManagedPortfolioStatus.Frozen;
        }
        return ManagedPortfolioStatus.Open;
    }

    function getAmountToMint(uint256 amount) public view returns (uint256) {
        uint256 _totalSupply = totalSupply();
        if (_totalSupply == 0) {
            return (amount * 10**decimals()) / (10**underlyingToken.decimals());
        } else {
            return (amount * _totalSupply) / value();
        }
    }

    function getOpenLoanIds() external view returns (uint256[] memory) {
        return _loans;
    }

    function illiquidValue() public view returns (uint256) {
        uint256 _value = 0;
        for (uint256 i = 0; i < _loans.length; i++) {
            (
                ,
                BulletLoanStatus status,
                uint256 principal,
                uint256 totalDebt,
                uint256 amountRepaid,
                uint256 duration,
                uint256 repaymentDate,

            ) = bulletLoans.loans(_loans[i]);
            if (status != BulletLoanStatus.Issued || amountRepaid >= totalDebt) {
                continue;
            }
            if (repaymentDate <= block.timestamp || totalDebt < principal) {
                _value += totalDebt - amountRepaid;
            } else {
                _value +=
                    ((totalDebt - principal) * (block.timestamp + duration - repaymentDate)) /
                    duration +
                    principal -
                    amountRepaid;
            }
        }
        return _value;
    }

    function liquidValue() public view returns (uint256) {
        return underlyingToken.balanceOf(address(this));
    }

    function markLoanAsDefaulted(uint256 instrumentId) external onlyManager {
        defaultedLoansCount++;
        bulletLoans.markLoanAsDefaulted(instrumentId);
        emit BulletLoanDefaulted(instrumentId);
    }

    function updateLoanParameters(
        uint256 instrumentId,
        uint256 newTotalDebt,
        uint256 newRepaymentDate
    ) external onlyManager {
        _onLoanRepaymentDateChange(newRepaymentDate);
        bulletLoans.updateLoanParameters(instrumentId, newTotalDebt, newRepaymentDate);
    }

    function updateLoanParameters(
        uint256 instrumentId,
        uint256 newTotalDebt,
        uint256 newRepaymentDate,
        bytes memory borrowerSignature
    ) external onlyManager {
        _onLoanRepaymentDateChange(newRepaymentDate);
        bulletLoans.updateLoanParameters(instrumentId, newTotalDebt, newRepaymentDate, borrowerSignature);
    }

    function markLoanAsResolved(uint256 instrumentId) external onlyManager {
        defaultedLoansCount--;
        bulletLoans.markLoanAsResolved(instrumentId);
    }

    function _onLoanRepaymentDateChange(uint256 newRepaymentDate) private {
        require(newRepaymentDate <= endDate, "ManagedPortfolio: Loan end date is greater than Portfolio end date");
        if (newRepaymentDate > latestRepaymentDate) {
            latestRepaymentDate = newRepaymentDate;
        }
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256
    ) internal virtual override {
        require(from == address(0) || to == address(0), "ManagedPortfolio: transfer of LP tokens prohibited");
    }

    function onERC721Received(
        address,
        address,
        uint256,
        bytes calldata
    ) external pure returns (bytes4) {
        return IERC721Receiver.onERC721Received.selector;
    }
}
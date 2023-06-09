// SPDX-License-Identifier: BUSL-1.1
// See bluejay.finance/license
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/ERC20Upgradeable.sol";

import "../interfaces/ILoanPool.sol";

contract LoanPool is ILoanPool, ERC20Upgradeable, ReentrancyGuard {
  using SafeERC20 for IERC20;

  uint256 constant WAD = 10 ** 18;

  /// @notice CreditLine contract that this loan pool is using to account for the loan
  ICreditLineBase public override creditLine;

  /// @notice ERC20 token that is being used as the loan currency
  IERC20 public override fundingAsset;

  /// @notice Address of the borrower
  address public override borrower;

  /// @notice Address of the pool factory if deployed & initialized by the factory
  address public override deployer;

  /// @notice Address of the fee receiver
  address public override feeRecipient;

  /// @notice Timestamp the pool is accepting deposits, in unix epoch time
  uint256 public override fundingStart;

  /// @notice Timestamp the pool stops accepting deposits, in unix epoch time
  uint256 public override fundingEnd;

  /// @notice Minimum amount required when funding is closed for successful funding,
  /// in funding asset decimals
  uint256 public override minFundingRequired;

  /// @notice Duration after fundingEnd where drawdown can happen,
  /// or funds will be returned for inactive borrower, in seconds
  uint256 public override drawdownPeriod;

  /// @notice Fee for successful funding, in WAD
  uint256 public override fees;

  /// @notice Amount of assets repaid to individual lenders when they withdraw,
  /// in funding asset decimals
  mapping(address => uint256) public override repayments;

  modifier nonZero(uint256 _value) {
    if (_value == 0) revert ZeroAmount();
    _;
  }

  modifier onlyBorrower() {
    if (msg.sender != borrower) revert NotBorrower();
    _;
  }

  /// @notice Initialize the loan pool
  /// @param _creditLine CreditLine contract that this loan pool is using to account for the loan
  /// @param _fundingAsset ERC20 token that is being used as the loan currency
  /// @param _borrower Address of the borrower
  /// @param _feeRecipient Address of the fee receiver
  /// @param _uints Array of uints, in order:
  // _uints[0] _maxLimit Maximum amount of assets that can be borrowed, in asset's decimals
  // _uints[1] _interestApr Annual interest rate, in WAD
  // _uints[2] _paymentPeriod Length of each payment period, in seconds
  // _uints[3] _gracePeriod Length of the grace period (late fees is not applied), in seconds
  // _uints[4] _lateFeeApr Additional annual interest rate applied on late payments, in WAD
  // _uints[5] _loanTenureInPeriods Number of periods before the loan is due, in wei
  // _uints[6] _earlyRepaymentFee Early repayment fee, in WAD
  // _uints[7] _fundingStart Timestamp of the start of the funding period, in unix epoch time
  // _uints[8] _fundingPeriod Length of the funding period, in seconds
  // _uints[9] _minFundingRequired Minimum amount of funding required, in asset's decimals
  // _uints[10] _drawdownPeriod Length of the drawdown period before refund occurs, in seconds
  // _uints[11] _fee Fee for the loan, in WAD
  function initialize(
    ICreditLineBase _creditLine,
    IERC20 _fundingAsset,
    address _borrower,
    address _feeRecipient,
    uint256[12] calldata _uints // collapsing because of stack too deep
  ) public override initializer {
    __ERC20_init("LoanPool", "LP");
    borrower = _borrower;
    deployer = msg.sender;

    _creditLine.initialize(
      _uints[0],
      _uints[1],
      _uints[2],
      _uints[3],
      _uints[4],
      _uints[5],
      _uints[6]
    );

    creditLine = _creditLine;
    fundingAsset = _fundingAsset;
    feeRecipient = _feeRecipient;
    fundingStart = _uints[7];
    fundingEnd = _uints[7] + _uints[8];
    minFundingRequired = _uints[9];
    drawdownPeriod = _uints[10];
    fees = _uints[11];
  }

  // =============================== BORROWER FUNCTIONS =================================

  /// @notice Drawdown funds raised on the loan pool as borrower and start the interest accrual
  function drawdown() public override onlyBorrower nonReentrant {
    if (block.timestamp >= fundingEnd + drawdownPeriod)
      revert DrawdownPeriodEnded();

    uint256 loanAmount = creditLine.drawdown();
    if (loanAmount < minFundingRequired) revert MinimumFundingNotReached();
    fundingAsset.safeTransfer(borrower, loanAmount);

    uint256 successFees = totalSupply() - loanAmount;
    if (successFees > 0) {
      emit FeesCollected(borrower, feeRecipient, successFees);
      fundingAsset.safeTransfer(feeRecipient, successFees);
    }
    emit Drawndown(msg.sender, loanAmount);
  }

  /// @notice Repay funds to the loan pool as borrower
  /// @dev No access control applied to allow anyone to repay on behalf of the borrower
  /// @param amount Amount of funds to repay, in funding asset decimals
  function repay(uint256 amount) public override nonReentrant nonZero(amount) {
    fundingAsset.safeTransferFrom(msg.sender, address(this), amount);
    creditLine.repay(amount);
    emit Repay(msg.sender, amount);

    // In event that borrower repays more than needed, return excess to borrower
    uint256 additionalRepayment = creditLine.additionalRepayment();
    if (additionalRepayment > 0) {
      fundingAsset.safeTransfer(msg.sender, additionalRepayment);
      emit RefundAdditionalPayment(msg.sender, additionalRepayment);
    }
  }

  // =============================== PUBLIC FUNCTIONS =================================

  /// @notice Deposit funds into the loan pool as lender
  /// @param amount Amount of funds to deposit, in funding asset decimals
  /// @param recipient Address to credit the deposit to
  function fund(
    uint256 amount,
    address recipient
  ) public override nonZero(amount) nonReentrant {
    fundingAsset.safeTransferFrom(msg.sender, address(this), amount);
    _fundDangerous(recipient);
  }

  /// @notice Account for funds deposited
  /// @dev Function should be called from a contract which performs important safety checks.
  /// @param recipient Address to credit the deposit to
  function fundDangerous(address recipient) public nonReentrant {
    _fundDangerous(recipient);
  }

  /// @notice Withdraw funds from the loan pool as lender whenever loan is repaid
  /// @param amount Amount to withdraw, in funding asset decimals
  /// @param recipient Address to withdraw to
  function withdraw(
    uint256 amount,
    address recipient
  ) public override nonZero(amount) nonReentrant {
    ICreditLineBase.State creditLineState = creditLine.loanState();
    if (
      creditLineState != ICreditLineBase.State.Repayment &&
      creditLineState != ICreditLineBase.State.Repaid
    ) revert NotRepaymentOrRepaidState();
    uint256 balance = balanceAvailable(msg.sender);
    if (amount > balance) revert InsufficientBalance();

    repayments[msg.sender] += amount;
    fundingAsset.safeTransfer(recipient, amount);
    emit Withdraw(msg.sender, recipient, amount);
  }

  /// @notice Reverse a withdraw of repayments from the loan pool, to allow more tokens to be transferred
  /// @param amount Amount to reverse withdrawal for, in funding asset decimals
  /// @param recipient Address to reverse withdrawal for
  function unwithdraw(
    uint256 amount,
    address recipient
  ) public override nonZero(amount) nonReentrant {
    if (amount > repayments[recipient]) revert ExcessiveUnwithdraw();

    unchecked {
      repayments[recipient] -= amount;
    }
    fundingAsset.safeTransferFrom(msg.sender, address(this), amount);
    emit Unwithdraw(msg.sender, recipient, amount);
  }

  /// @notice Mark the loan as refunding when funding period is over and minimum funding is not reached
  function refundMinimumNotMet() public override nonReentrant {
    if (block.timestamp <= fundingEnd) revert FundingPeriodNotEnded();
    if (creditLine.principalBalance() >= minFundingRequired)
      revert MinimumFundingReached();
    creditLine.refund();
    emit Refunded();
  }

  /// @notice Mark the loan as refunding when borrower does not drawdown in time
  function refundInactiveBorrower() public override nonReentrant {
    if (block.timestamp < fundingEnd + drawdownPeriod)
      revert DrawdownPeriodNotEnded();
    if (creditLine.loanState() != ICreditLineBase.State.Funding)
      revert NotFundingState();
    creditLine.refund();
    emit Refunded();
  }

  /// @notice Withdraw funds from the loan pool as lender when the pool is in refunding state
  function refund(address recipient) public override nonReentrant {
    if (creditLine.loanState() != ICreditLineBase.State.Refund)
      revert NotRefundState();
    uint256 amount = balanceOf(msg.sender);
    if (amount == 0) revert ZeroAmount();
    _burn(msg.sender, amount);
    fundingAsset.safeTransfer(recipient, amount);
    emit Refund(msg.sender, recipient, amount);
  }

  // =============================== VIEW FUNCTIONS =================================

  function maxRepaymentAmount(
    address account
  ) public view override returns (uint256 repaymentCeiling) {
    uint256 totalRepayments = creditLine.totalRepayments();
    repaymentCeiling = (shareOfPool(account) * totalRepayments) / WAD;
  }

  /// @notice Get the amount of funds that a lender can withdraw from the loan pool
  /// @param account Address of the lender
  /// @return balance Amount of funds that can be withdrawn, in funding asset decimals
  function balanceAvailable(
    address account
  ) public view override returns (uint256 balance) {
    uint256 repaymentCeiling = maxRepaymentAmount(account);
    uint256 amountRepaid = repayments[account];
    unchecked {
      balance = repaymentCeiling > amountRepaid
        ? repaymentCeiling - amountRepaid
        : 0;
    }
  }

  /// @notice Get the share of the loan pool that a lender has
  /// @param account Address of the lender
  /// @return share Share of the loan pool, in WAD
  function shareOfPool(
    address account
  ) public view override returns (uint256 share) {
    uint256 totalSupply = totalSupply();
    if (totalSupply == 0) return 0;
    share = (balanceOf(account) * WAD) / totalSupply;
  }

  /// @notice Get the number of decimals of the funding asset
  /// @dev This allow wallets to display the correct number of decimals
  function decimals() public view virtual override returns (uint8) {
    return IERC20Metadata(address(fundingAsset)).decimals();
  }

  // =============================== INTERNAL FUNCTIONS =================================

  /// @notice Prevent transfers of unencumbered tokens
  function _afterTokenTransfer(
    address from,
    address,
    uint256
  ) internal virtual override {
    if (repayments[from] > maxRepaymentAmount(from))
      revert EncumberedTokenTransfer();
  }

  /// @notice Account for funds deposited
  /// @dev Function should be called from a contract which performs important safety checks.
  /// @param recipient Address to credit the deposit to
  function _fundDangerous(address recipient) internal {
    if (block.timestamp < fundingStart) revert FundingPeriodNotStarted();
    if (block.timestamp > fundingEnd) revert FundingPeriodEnded();

    uint256 amount = fundingAsset.balanceOf(address(this)) - totalSupply();
    creditLine.fund(amount - (amount * fees) / WAD);
    _mint(recipient, amount);
    emit Fund(msg.sender, recipient, amount);
  }
}
// SPDX-License-Identifier: No License
pragma solidity ^0.8.11;
import "../../interfaces/IGenericPool.sol";

interface ILendingPool is IGenericPool {
    
    /* ========== EVENTS ========== */
    event Borrow(address indexed borrower, uint256 vendorFees, uint256 lenderFees, uint48 borrowRate, uint256 additionalColAmount, uint256 additionalDebt);
    event RollIn(address indexed borrower, address originPool, uint256 originDebt, uint256 lendToRepay, uint256 lenderFeeAmt, uint256 protocolFeeAmt, uint256 colRolled, uint256 colToReimburse);
    event Repay(address indexed borrower, uint256 debtRepaid, uint256 colReturned);
    event Collect(address indexed lender, uint256 lenderLend, uint256 lenderCol);
    event UpdateBorrower(address indexed borrower, bool allowed);
    event OwnershipTransferred(address oldOwner, address newOwner);
    event RolloverPoolSet(address pool, bool enabled);
    event Withdraw(address indexed lender, uint256 amount);
    event Deposit(address indexed lender, uint256 amount);
    event WithdrawStrategyTokens(uint256 sharesAmount);
    event Pause(uint48 timestamp);
    event BalanceChange(address token, address to, bool incoming, uint256 amount);

    /* ========== STRUCTS ========== */
    struct UserReport {
        uint256 debt;           // total borrowed in lend token
        uint256 colAmount;      // total collateral deposited by the borrower
    }

    /* ========== ERRORS ========== */
    error PoolNotWhitelisted();
    error OperationsPaused();
    error NotOwner();
    error ZeroAddress();
    error InvalidParameters();
    error PrivatePool();
    error PoolExpired();
    error FeeTooHigh();
    error BorrowingPaused();
    error NotEnoughLiquidity();
    error FailedStrategyWithdraw();
    error NoDebt();
    error PoolStillActive();
    error NotGranted();
    error UpgradeNotAllowed();
    error ImplementationNotWhitelisted();
    error RolloverPartialAmountNotSupported();
    error NotValidPrice();
    error NotPrivatePool();
    error DebtIsLess();
    error InvalidCollateralReceived();
    
    function borrowOnBehalfOf(
        address _borrower,
        uint256 _colDepositAmount,
        uint48 _rate
    ) external returns (uint256 assetsBorrowed, uint256 lenderFees, uint256 vendorFees);

    function repayOnBehalfOf(
        address _borrower,
        uint256 _repayAmount
    ) external returns (uint256 lendTokenReceived, uint256 colReturnAmount);

    function debts(address _borrower) external returns (uint256, uint256);
}
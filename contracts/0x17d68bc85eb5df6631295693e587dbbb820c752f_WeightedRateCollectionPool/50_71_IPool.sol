// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**
 * @title Interface to a Pool
 */
interface IPool {
    /**************************************************************************/
    /* Errors */
    /**************************************************************************/

    /**
     * @notice Invalid caller
     */
    error InvalidCaller();

    /**
     * @notice Insufficient shares
     */
    error InsufficientShares();

    /**
     * @notice Invalid redemption status
     */
    error InvalidRedemptionStatus();

    /**
     * @notice Invalid loan receipt
     */
    error InvalidLoanReceipt();

    /**
     * @notice Invalid borrow options
     */
    error InvalidBorrowOptions();

    /**
     * @notice Unsupported collateral
     * @param index Index of unsupported asset
     */
    error UnsupportedCollateral(uint256 index);

    /**
     * @notice Unsupported loan duration
     */
    error UnsupportedLoanDuration();

    /**
     * @notice Repayment too high
     */
    error RepaymentTooHigh();

    /**
     * @notice Loan not expired
     */
    error LoanNotExpired();

    /**************************************************************************/
    /* Events */
    /**************************************************************************/

    /**
     * @notice Emitted when currency is deposited
     * @param account Account
     * @param tick Tick
     * @param amount Amount of currency tokens
     * @param shares Amount of shares allocated
     */
    event Deposited(address indexed account, uint128 indexed tick, uint256 amount, uint256 shares);

    /**
     * @notice Emitted when deposit shares are redeemed
     * @param account Account
     * @param tick Tick
     * @param shares Amount of shares to be redeemed
     */
    event Redeemed(address indexed account, uint128 indexed tick, uint256 shares);

    /**
     * @notice Emitted when redeemed currency tokens are withdrawn
     * @param account Account
     * @param tick Tick
     * @param shares Amount of shares redeemed
     * @param amount Amount of currency tokens withdrawn
     */
    event Withdrawn(address indexed account, uint128 indexed tick, uint256 shares, uint256 amount);

    /**
     * @notice Emitted when a loan is originated
     * @param loanReceiptHash Loan receipt hash
     * @param loanReceipt Loan receipt
     */
    event LoanOriginated(bytes32 indexed loanReceiptHash, bytes loanReceipt);

    /**
     * @notice Emitted when a loan is repaid
     * @param loanReceiptHash Loan receipt hash
     * @param repayment Repayment amount in currency tokens
     */
    event LoanRepaid(bytes32 indexed loanReceiptHash, uint256 repayment);

    /**
     * @notice Emitted when a loan is liquidated
     * @param loanReceiptHash Loan receipt hash
     */
    event LoanLiquidated(bytes32 indexed loanReceiptHash);

    /**
     * @notice Emitted when loan collateral is liquidated
     * @param loanReceiptHash Loan receipt hash
     * @param proceeds Total liquidation proceeds in currency tokens
     * @param borrowerProceeds Borrower's share of liquidation proceeds in
     * currency tokens
     */
    event CollateralLiquidated(bytes32 indexed loanReceiptHash, uint256 proceeds, uint256 borrowerProceeds);

    /**
     * @notice Emitted when admin fee rate is updated
     * @param rate New admin fee rate in basis points
     */
    event AdminFeeRateUpdated(uint256 rate);

    /**
     * @notice Emitted when admin fees are withdrawn
     * @param account Recipient account
     * @param amount Amount of currency tokens withdrawn
     */
    event AdminFeesWithdrawn(address indexed account, uint256 amount);

    /**************************************************************************/
    /* Getters */
    /**************************************************************************/

    /**
     * @notice Get currency token
     * @return Currency token contract
     */
    function currencyToken() external view returns (address);

    /**
     * @notice Get supported durations
     * @return List of loan durations in second
     */
    function durations() external view returns (uint64[] memory);

    /**
     * @notice Get supported rates
     * @return List of rates in interest per second
     */
    function rates() external view returns (uint64[] memory);

    /**
     * @notice Get admin
     * @return Admin
     */
    function admin() external view returns (address);

    /**
     * @notice Get admin fee rate
     * @return Admin fee rate in basis points
     */
    function adminFeeRate() external view returns (uint32);

    /**
     * @notice Get list of supported collateral wrappers
     * @return Collateral wrappers
     */
    function collateralWrappers() external view returns (address[] memory);

    /**
     * @notice Get collateral liquidator contract
     * @return Collateral liquidator contract
     */
    function collateralLiquidator() external view returns (address);

    /**
     * @notice Get delegation registry contract
     * @return Delegation registry contract
     */
    function delegationRegistry() external view returns (address);

    /**************************************************************************/
    /* Deposit API */
    /**************************************************************************/

    /**
     * @notice Deposit amount at tick
     *
     * Emits a {Deposited} event.
     *
     * @param tick Tick
     * @param amount Amount of currency tokens
     * @param minShares Minimum amount of shares to receive
     * @return shares Amount of shares minted
     */
    function deposit(uint128 tick, uint256 amount, uint256 minShares) external returns (uint256 shares);

    /**
     * @notice Redeem deposit shares for currency tokens. Currency tokens can
     * be withdrawn with the `withdraw()` method once the redemption is
     * processed.
     *
     * Emits a {Redeemed} event.
     *
     * @param tick Tick
     * @param shares Amount of deposit shares to redeem
     */
    function redeem(uint128 tick, uint256 shares) external;

    /**
     * @notice Get redemption available
     *
     * @param account Account
     * @param tick Tick
     * @return shares Amount of deposit shares available for redemption
     * @return amount Amount of currency tokens available for withdrawal
     */
    function redemptionAvailable(address account, uint128 tick) external view returns (uint256 shares, uint256 amount);

    /**
     * @notice Withdraw a redemption that is available
     *
     * Emits a {Withdrawn} event.
     *
     * @param tick Tick
     * @return shares Amount of deposit shares burned
     * @return amount Amount of currency tokens withdrawn
     */
    function withdraw(uint128 tick) external returns (uint256 shares, uint256 amount);

    /**
     * @notice Rebalance a redemption that is available to a new tick
     *
     * Emits {Withdrawn} and {Deposited} events.
     *
     * @param srcTick Source tick
     * @param dstTick Destination Tick
     * @param minShares Minimum amount of destination shares to receive
     * @return oldShares Amount of source deposit shares burned
     * @return newShares Amount of destination deposit shares minted
     * @return amount Amount of currency tokens redeposited
     */
    function rebalance(
        uint128 srcTick,
        uint128 dstTick,
        uint256 minShares
    ) external returns (uint256 oldShares, uint256 newShares, uint256 amount);

    /**************************************************************************/
    /* Lend API */
    /**************************************************************************/

    /**
     * @notice Quote repayment for a loan
     * @param principal Principal amount in currency tokens
     * @param duration Duration in seconds
     * @param collateralToken Collateral token
     * @param collateralTokenIds List of collateral token IDs
     * @param ticks Liquidity ticks
     * @param options Encoded options
     * @return Repayment amount in currency tokens
     */
    function quote(
        uint256 principal,
        uint64 duration,
        address collateralToken,
        uint256[] calldata collateralTokenIds,
        uint128[] calldata ticks,
        bytes calldata options
    ) external view returns (uint256);

    /**
     * @notice Quote refinancing for a loan
     *
     * @param encodedLoanReceipt Encoded loan receipt
     * @param principal New principal amount in currency tokens
     * @param duration Duration in seconds
     * @param ticks Liquidity ticks
     * @return downpayment Downpayment in currency tokens (positive for downpayment, negative for credit)
     * @return repayment Repayment amount in currency tokens for new loan
     */
    function quoteRefinance(
        bytes calldata encodedLoanReceipt,
        uint256 principal,
        uint64 duration,
        uint128[] calldata ticks
    ) external view returns (int256 downpayment, uint256 repayment);

    /**
     * @notice Originate a loan
     *
     * Emits a {LoanOriginated} event.
     *
     * @param principal Principal amount in currency tokens
     * @param duration Duration in seconds
     * @param collateralToken Collateral token address
     * @param collateralTokenId Collateral token ID
     * @param maxRepayment Maximum repayment amount in currency tokens
     * @param ticks Liquidity ticks
     * @param options Encoded options
     * @return Repayment amount in currency tokens
     */
    function borrow(
        uint256 principal,
        uint64 duration,
        address collateralToken,
        uint256 collateralTokenId,
        uint256 maxRepayment,
        uint128[] calldata ticks,
        bytes calldata options
    ) external returns (uint256);

    /**
     * @notice Repay a loan
     *
     * Emits a {LoanRepaid} event.
     *
     * @param encodedLoanReceipt Encoded loan receipt
     * @return Repayment amount in currency tokens
     */
    function repay(bytes calldata encodedLoanReceipt) external returns (uint256);

    /**
     * @notice Refinance a loan
     *
     * Emits a {LoanRepaid} event and a {LoanOriginated} event.
     *
     * @param encodedLoanReceipt Encoded loan receipt
     * @param principal Principal amount in currency tokens
     * @param duration Duration in seconds
     * @param maxRepayment Maximum repayment amount in currency tokens
     * @param ticks Liquidity ticks
     * @return Repayment amount in currency tokens
     */
    function refinance(
        bytes calldata encodedLoanReceipt,
        uint256 principal,
        uint64 duration,
        uint256 maxRepayment,
        uint128[] calldata ticks
    ) external returns (uint256);

    /**
     * @notice Liquidate an expired loan
     *
     * Emits a {LoanLiquidated} event.
     *
     * @param loanReceipt Loan receipt
     */
    function liquidate(bytes calldata loanReceipt) external;
}
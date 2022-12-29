pragma solidity ^0.8.10;

interface IRefundable {

    ////////////////////
    ////// Events //////
    ////////////////////

    /// @notice Emitted when a refund is issued
    event IssueRefund(address refunded, uint256 amount, bool sent, uint256 remainingBalance);

    /// @notice Emited when we're not able to refund the full amount
    event InsufficientFundsForRefund(address refunded, uint256 intendedAmount, uint256 sentAmount);

    /////////////////////
    ////// Methods //////
    /////////////////////

    function MAX_REFUND_PRIORITY_FEE() external view returns (uint256);
    function REFUND_BASE_GAS() external view returns (uint256);
}
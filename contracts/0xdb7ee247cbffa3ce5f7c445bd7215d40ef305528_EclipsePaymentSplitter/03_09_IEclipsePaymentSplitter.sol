// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface IEclipsePaymentSplitter {
    function splitPayment() external payable;

    function getTotalShares() external view returns (uint256);

    function getTotalRoyaltyShares() external view returns (uint256);

    function release(address account) external;

    function updatePayee(
        uint8 paymentType,
        uint8 payeeIndex,
        address newPayee
    ) external;
}
// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface IGenArtPaymentSplitterV4 {
    function splitPayment() external payable;

    function getTotalShares(uint8 _payment) external view returns (uint256);

    function release(address account) external;

    function updatePayee(
        uint8 paymentType,
        uint256 payeeIndex,
        address newPayee
    ) external;
}
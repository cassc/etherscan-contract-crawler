// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface IGenArtPaymentSplitterV5 {
    function splitPayment(uint256 mintValue) external payable;

    function getTotalShares(uint8 _payment) external view returns (uint256);

    function release(address account) external;

    function updatePayee(
        uint8 paymentType,
        uint256 payeeIndex,
        address newPayee
    ) external;
}
// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface IGenArtPaymentSplitter {
    function addCollectionPayment(
        address collection,
        address[] memory payees,
        uint256[] memory shares
    ) external;

    function addCollectionPaymentRoyalty(
        address collection,
        address[] memory payees,
        uint256[] memory shares
    ) external;

    function splitPayment(address collection) external payable;

    function splitPaymentRoyalty(address collection) external payable;

    function getTotalSharesOfCollection(address collection, uint8 _payment)
        external
        view
        returns (uint256);

    function release(address account) external;

    function updatePayee(
        address collection,
        uint8 paymentType,
        uint256 payeeIndex,
        address newPayee
    ) external;
}
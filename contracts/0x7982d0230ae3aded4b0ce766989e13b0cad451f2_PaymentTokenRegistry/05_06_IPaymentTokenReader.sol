// SPDX-License-Identifier: AGPL-3.0-or-later

pragma solidity ^0.8.0;
pragma abicoder v2;

interface IPaymentTokenReader {
    /**
     * @dev Check if a payment token is allowed for a collection
     */
    function isAllowedPaymentToken(
        address collectionAddress,
        uint32 paymentTokenId
    ) external view returns (bool);

    /**
     * @dev get payment token id by address
     */
    function getPaymentTokenIdByAddress(
        address token
    ) external view returns (uint32);

    /**
     * @dev get payment token address by id
     */
    function getPaymentTokenAddressById(
        uint32 id
    ) external view returns (address);
}
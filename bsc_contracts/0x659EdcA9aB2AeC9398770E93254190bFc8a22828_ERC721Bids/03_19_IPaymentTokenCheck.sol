// SPDX-License-Identifier: AGPL-3.0-or-later

pragma solidity ^0.8.0;
pragma abicoder v2;

interface IPaymentTokenCheck {
    /**
     * @dev Check if a payment token is allowed for a collection
     */
    function isAllowedPaymentToken(address collectionAddress, address token)
        external
        view
        returns (bool);
}
//SPDX-License-Identifier: Apache 2.0

pragma solidity ^0.8.21;

/**
 * @title RMRK Wrapped Equippable Interface
 * @notice This is the minimal interface that the Wrapper contract needs to be able to access on the Wrapped Collections.
 */
interface IRMRKWrappedEquippable {
    /**
     * @notice Sets the payment data for individual wrap payments.
     * @param paymentToken The address of the ERC20 token used for payment
     * @param individualWrappingPrice The price of wrapping an individual token
     * @param beneficiary The address of the beneficiary
     */
    function setPaymentData(
        address paymentToken,
        uint256 individualWrappingPrice,
        address beneficiary
    ) external;
}
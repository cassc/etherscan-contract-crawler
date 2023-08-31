// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "../libraries/DlnOrderLib.sol";

interface IDlnSource {
    /**
     * @notice This function returns the global fixed fee in the native asset of the protocol.
     * @dev This fee is denominated in the native asset (like Ether in Ethereum).
     * @return uint88 This return value represents the global fixed fee in the native asset.
     */
    function globalFixedNativeFee() external returns (uint88);

    /**
     * @notice This function provides the global transfer fee, expressed in Basis Points (BPS).
     * @dev It retrieves a global fee which is applied to order.giveAmount. The fee is represented in Basis Points (BPS), where 1 BPS equals 0.01%.
     * @return uint16 The return value represents the global transfer fee in BPS.
     */
    function globalTransferFeeBps() external returns (uint16);

    /**
     * @notice The `createOrder` function is used in the DLN protocol to initialize a new order.
     * @dev The function takes arguments:
     * @param _orderCreation is a structured parameter from the DlnOrderLib.OrderCreation library, containing all the necessary information required for creating a new order.
     * @param _affiliateFee is a bytes parameter specifying the affiliate fee that will be rewarded to the beneficiary. It includes the beneficiary's details and the affiliate amount.
     * @param _referralCode is a 32-bit unsigned integer containing the referral code. This code is traced back to the referral source or person that facilitated this order. This code is also emitted in an event for tracking purposes.
     * @param _permitEnvelope is a bytes parameter that is used to approve the spender through a signature. It contains the amount, the deadline, and the signature.
     * @return bytes32 Unique identifier for the newly created order.
     */
    function createOrder(
        DlnOrderLib.OrderCreation calldata _orderCreation,
        bytes calldata _affiliateFee,
        uint32 _referralCode,
        bytes calldata _permitEnvelope
    ) external payable returns (bytes32);
}
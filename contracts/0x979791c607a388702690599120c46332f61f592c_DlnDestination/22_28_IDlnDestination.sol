// SPDX-License-Identifier: MIT

pragma solidity ^0.8.7;
import "../libraries/DlnOrderLib.sol";

interface IDlnDestination {
    /**
     * @notice This function allows a taker to fulfill an order from another chain in the DLN protocol.
     *
     * @dev During the execution of this method:
     * - The `take` part of the order from the `taker` is sent to the `receiver` of the order.
     * - If a patch order was taken previously, the patch amount is deducted.
     * - After the above step, the `taker` can invoke `send_unlock` to receive the `give` part of the order on the specified chain.
     *
     * @param _order Full order to be fulfilled. This includes details about the order such as the `give` part, `take` part, and the `receiver`.
     * @param _fulFillAmount Amount the taker is expected to pay for this order. This is used for validation to ensure the taker pays the correct amount.
     * @param _orderId Unique identifier of the order to be fulfilled. This is used to verify that the taker is fulfilling the correct order.
     * @param _permitEnvelope Permit for approving the spender by signature. This parameter includes the amount, deadline, and signature.
     * @param _unlockAuthority Address authorized to unlock the order by calling send{Evm,Solana}Unlock after successful fulfillment of the order.
     *
     * @notice It checks if the taker is allowed based on the order's `allowedTakerDst` field.
     * - If `allowedTakerDst` is None, anyone with sufficient tokens can fulfill the order.
     * - If `allowedTakerDst` is Some, only the specified address can fulfill the order.
     */
    function fulfillOrder(
        DlnOrderLib.Order memory _order,
        uint256 _fulFillAmount,
        bytes32 _orderId,
        bytes calldata _permitEnvelope,
        address _unlockAuthority
    ) external payable;
}
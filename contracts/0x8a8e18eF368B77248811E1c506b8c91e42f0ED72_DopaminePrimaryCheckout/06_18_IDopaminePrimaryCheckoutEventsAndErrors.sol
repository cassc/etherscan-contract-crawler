// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.18;

import {Bundle} from "../../payments/DopaminePrimaryCheckoutStructs.sol";

////////////////////////////////////////////////////////////////////////////////
///              ░▒█▀▀▄░█▀▀█░▒█▀▀█░█▀▀▄░▒█▀▄▀█░▄█░░▒█▄░▒█░▒█▀▀▀              ///
///              ░▒█░▒█░█▄▀█░▒█▄▄█▒█▄▄█░▒█▒█▒█░░█▒░▒█▒█▒█░▒█▀▀▀              ///
///              ░▒█▄▄█░█▄▄█░▒█░░░▒█░▒█░▒█░░▒█░▄█▄░▒█░░▀█░▒█▄▄▄              ///
////////////////////////////////////////////////////////////////////////////////

/// @title Dopamine Primary Checkout Events & Errors Interface
interface IDopaminePrimaryCheckoutEventsAndErrors {

    /// @notice Emits when new checkout signer permissions are set.
    /// @param signer The address whose signing permissions are being set.
    /// @param setting Whether or not the address may verify checkouts.
    event DopamineCheckoutSignerSet(address signer, bool setting);

    /// @notice Emits when an order is successfully fulfilled.
    /// @param orderHash The tracking identifier of the Dopamine order.
    /// @param purchaser The address who completed the checkout.
    /// @param bundles All bundled items included with the Dopamine order.
    event OrderFulfilled(
        bytes32 orderHash,
        address indexed purchaser,
        Bundle[] bundles
    );

    /// @notice The provided order has already been processed.
    error OrderAlreadyProcessed();

    /// @notice Error when transferring ETH to the sender.
    error EthTransferFailed();

    /// @notice The number of bundles ordered exceeds the maximum allowed.
    error OrderCapacityExceeded();

    /// @notice Insufficient payment provided for the purchase.
    error PaymentInsufficient();

    /// @notice Amount specified for withdrawal is invalid.
    error WithdrawalInvalid();

}
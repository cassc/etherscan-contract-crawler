// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.16;

////////////////////////////////////////////////////////////////////////////////
///              ░▒█▀▀▄░█▀▀█░▒█▀▀█░█▀▀▄░▒█▀▄▀█░▄█░░▒█▄░▒█░▒█▀▀▀              ///
///              ░▒█░▒█░█▄▀█░▒█▄▄█▒█▄▄█░▒█▒█▒█░░█▒░▒█▒█▒█░▒█▀▀▀              ///
///              ░▒█▄▄█░█▄▄█░▒█░░░▒█░▒█░▒█░░▒█░▄█▄░▒█░░▀█░▒█▄▄▄              ///
////////////////////////////////////////////////////////////////////////////////

import {Bundle} from "../../payments/DopaminePrimaryCheckoutStructs.sol";

/// @title Dopamine Primary Checkout Events & Errors Interface
interface IDopaminePrimaryCheckoutEventsAndErrors {

    event DopamineCheckoutSignerSet(address signer, bool setting);

    event OrderFulfilled(
        bytes32 orderHash,
        address indexed purchaser,
        Bundle[] bundles
    );

    /// @notice The provided bundle has already been purchased.
    error BundleAlreadyPurchased();

    /// @notice Error when transferring ETH to the sender.
    error EthTransferFailed();

    /// @notice The number of bundles ordered exceeds the maximum allowed.
    error OrderCapacityExceeded();

    /// @notice Insufficient payment provided for the purchase.
    error PaymentInsufficient();

    /// @notice Amount specified for withdrawal is invalid.
    error WithdrawalInvalid();

}
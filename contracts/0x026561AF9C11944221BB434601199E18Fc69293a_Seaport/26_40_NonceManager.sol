// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;

// prettier-ignore
import {
    ConsiderationEventsAndErrors
} from "../interfaces/ConsiderationEventsAndErrors.sol";

import { ReentrancyGuard } from "./ReentrancyGuard.sol";

/**
 * @title NonceManager
 * @author 0age
 * @notice NonceManager contains a storage mapping and related functionality
 *         for retrieving and incrementing a per-offerer nonce.
 */
contract NonceManager is ConsiderationEventsAndErrors, ReentrancyGuard {
    // Only orders signed using an offerer's current nonce are fulfillable.
    mapping(address => uint256) private _nonces;

    /**
     * @dev Internal function to cancel all orders from a given offerer with a
     *      given zone in bulk by incrementing a nonce. Note that only the
     *      offerer may increment the nonce.
     *
     * @return newNonce The new nonce.
     */
    function _incrementNonce() internal returns (uint256 newNonce) {
        // Ensure that the reentrancy guard is not currently set.
        _assertNonReentrant();

        // No need to check for overflow; nonce cannot be incremented that far.
        unchecked {
            // Increment current nonce for the supplied offerer.
            newNonce = ++_nonces[msg.sender];
        }

        // Emit an event containing the new nonce.
        emit NonceIncremented(newNonce, msg.sender);
    }

    /**
     * @dev Internal view function to retrieve the current nonce for a given
     *      offerer.
     *
     * @param offerer The offerer in question.
     *
     * @return currentNonce The current nonce.
     */
    function _getNonce(address offerer)
        internal
        view
        returns (uint256 currentNonce)
    {
        // Return the nonce for the supplied offerer.
        currentNonce = _nonces[offerer];
    }
}
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.16;

import {LibSecp256k1} from "./LibSecp256k1.sol";

/**
 * @title LibSchnorr
 *
 * @notice Custom-purpose library for Schnorr signature verification on the
 *         secp256k1 curve
 */
library LibSchnorr {
    using LibSecp256k1 for LibSecp256k1.Point;

    /// @dev Returns whether `signature` and `commitment` sign via `pubKey`
    ///      message `message`.
    ///
    /// @custom:invariant Reverts iff out of gas.
    /// @custom:invariant Uses constant amount of gas.
    function verifySignature(
        LibSecp256k1.Point memory pubKey,
        bytes32 message,
        bytes32 signature,
        address commitment
    ) internal pure returns (bool) {
        // Return false if signature or commitment is zero.
        if (signature == 0 || commitment == address(0)) {
            return false;
        }

        // Note to enforce pubKey is valid secp256k1 point.
        //
        // While the Scribe contract ensures to only verify signatures for valid
        // public keys, this check is enabled as an additional defense
        // mechanism.
        if (!pubKey.isOnCurve()) {
            return false;
        }

        // Note to enforce signature is less than Q to prevent signature
        // malleability.
        //
        // While the Scribe contract only accepts messages with strictly
        // monotonically increasing timestamps, circumventing replay attack
        // vectors and therefore also signature malleability issues at a higher
        // level, this check is enabled as an additional defense mechanism.
        if (uint(signature) >= LibSecp256k1.Q()) {
            return false;
        }

        // Construct challenge = H(Pₓ ‖ Pₚ ‖ m ‖ Rₑ) mod Q
        uint challenge = uint(
            keccak256(
                abi.encodePacked(
                    pubKey.x, uint8(pubKey.yParity()), message, commitment
                )
            )
        ) % LibSecp256k1.Q();

        // Compute msgHash = -sig * Pₓ      (mod Q)
        //                 = Q - (sig * Pₓ) (mod Q)
        //
        // Unchecked because the only protected operation performed is the
        // subtraction from Q where the subtrahend is the result of a (mod Q)
        // computation, i.e. the subtrahend is guaranteed to be less than Q.
        uint msgHash;
        unchecked {
            msgHash = LibSecp256k1.Q()
                - mulmod(uint(signature), pubKey.x, LibSecp256k1.Q());
        }

        // Compute v = Pₚ + 27
        //
        // Unchecked because pubKey.yParity() ∊ {0, 1} which cannot overflow
        // by adding 27.
        uint v;
        unchecked {
            v = pubKey.yParity() + 27;
        }

        // Set r = Pₓ
        uint r = pubKey.x;

        // Compute s = Q - (e * Pₓ) (mod Q)
        //
        // Unchecked because the only protected operation performed is the
        // subtraction from Q where the subtrahend is the result of a (mod Q)
        // computation, i.e. the subtrahend is guaranteed to be less than Q.
        uint s;
        unchecked {
            s = LibSecp256k1.Q() - mulmod(challenge, pubKey.x, LibSecp256k1.Q());
        }

        // Compute ([s]G - [e]P)ₑ via ecrecover.
        address recovered =
            ecrecover(bytes32(msgHash), uint8(v), bytes32(r), bytes32(s));

        // Verification succeeds iff ([s]G - [e]P)ₑ = Rₑ.
        //
        // Note that commitment is guaranteed to not be zero.
        return commitment == recovered;
    }
}
pragma solidity ^0.8.0;

// SPDX-License-Identifier: MIT

/**
 *
 * This code is part of HouseOfPanda project.
 *
 */

struct Sig {
    bytes32 r;
    bytes32 s;
    uint8 v;
}

abstract contract ISigVerifier {
    function sigPrefixed(bytes32 hash) internal virtual pure returns (bytes32);
    function _isSigner(
        address account,
        bytes32 message,
        Sig memory sig
    ) internal virtual pure returns (bool);
}

contract SigVerifier is ISigVerifier {
    function sigPrefixed(bytes32 hash) internal override pure returns (bytes32) {
        return
            keccak256(
                abi.encodePacked("\x19Ethereum Signed Message:\n32", hash)
            );
    }

    function _isSigner(
        address account,
        bytes32 message,
        Sig memory sig
    ) internal override pure returns (bool) {
        return ecrecover(message, sig.v, sig.r, sig.s) == account;
    }
}
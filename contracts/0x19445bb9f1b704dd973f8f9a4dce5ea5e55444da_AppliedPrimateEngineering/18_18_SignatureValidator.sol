// SPDX-License-Identifier: MIT
pragma solidity ^0.8.16;

import "openzeppelin/utils/cryptography/ECDSA.sol";

contract SignatureValidator {
    error InvalidSignature();

    using ECDSA for bytes32;

    address public signer;

    constructor(address signer_) {
        signer = signer_;
    }

    function _validateSignature(bytes memory signature, bytes memory message) internal view {
        bytes32 messageHash = ECDSA.toEthSignedMessageHash(keccak256(message));
        address recovered = messageHash.recover(signature);
        if (signer != recovered) revert InvalidSignature();
    }

    function _setSigner(address signer_) internal {
        signer = signer_;
    }
}
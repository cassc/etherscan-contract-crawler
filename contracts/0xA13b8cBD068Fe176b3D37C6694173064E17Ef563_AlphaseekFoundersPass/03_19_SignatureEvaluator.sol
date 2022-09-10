// SPDX-License-Identifier: CC0
// Copyright (c) 2022 unReal Accelerator, LLC (https://unrealaccelerator.io)
pragma solidity ^0.8.9;

/// @title: SignatureEvaluator
/// @author: [email protected]
/// @notice ECDSA signature of a standardized message

import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";

contract SignatureEvaluator {
    using ECDSA for bytes32;

    error InvalidSignerAddress();
    error MessageUsed();

    address private signer;
    mapping(bytes32 => bool) private usedMessages;

    constructor(address signer_) {
        if (signer_ == address(0)) revert InvalidSignerAddress();
        signer = signer_;
    }

    function _setSigner(address signer_) internal {
        if (signer_ == address(0)) revert InvalidSignerAddress();
        signer = signer_;
    }

    function _getSigner() internal view returns (address) {
        return signer;
    }

    function _validateSignature(bytes memory data, bytes memory signature)
        internal
        returns (bool)
    {
        bytes32 message = _generateMessage(data);
        if (usedMessages[message]) revert MessageUsed();
        usedMessages[message] = true;
        return ECDSA.recover(message, signature) == signer;
    }

    function _generateMessage(bytes memory data)
        internal
        pure
        returns (bytes32)
    {
        return ECDSA.toEthSignedMessageHash(keccak256(data));
    }
}
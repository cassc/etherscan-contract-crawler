/// SPDX-License-Identifier: MIT

pragma solidity >=0.8.0;

type FactSignature is bytes32;

struct Fact {
    address account;
    FactSignature sig;
    bytes data;
}

/**
 * @title Facts
 * @author Theori, Inc.
 * @notice Helper functions for fact classes (part of fact signature that determines fee).
 */
library Facts {
    uint8 internal constant NO_FEE = 0;

    /**
     * @notice construct a fact signature from a fact class and some unique data
     * @param cls the fact class (determines the fee)
     * @param data the unique data for the signature
     */
    function toFactSignature(uint8 cls, bytes memory data) internal pure returns (FactSignature) {
        return FactSignature.wrap(bytes32((uint256(keccak256(data)) << 8) | cls));
    }

    /**
     * @notice extracts the fact class from a fact signature
     * @param factSig the input fact signature
     */
    function toFactClass(FactSignature factSig) internal pure returns (uint8) {
        return uint8(uint256(FactSignature.unwrap(factSig)));
    }
}
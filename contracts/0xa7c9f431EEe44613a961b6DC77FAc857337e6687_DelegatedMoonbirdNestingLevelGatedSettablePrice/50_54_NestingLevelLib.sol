// SPDX-License-Identifier: MIT
// Copyright 2023 PROOF Holdings Inc
pragma solidity ^0.8.16;

import {ECDSA} from "openzeppelin-contracts/utils/cryptography/ECDSA.sol";

library NestingLevelLib {
    using NestingLevelLib for MoonbirdNestingLevel;
    using NestingLevelLib for SignedMoonbirdNestingLevel;

    /**
     * @notice The nesting levels of a Moonbird.
     */
    enum NestingLevel {
        Unnested,
        Straw,
        Bronze,
        Silver,
        Gold,
        Diamond
    }

    /**
     * @notice Associates a moonbird with its nesting level.
     * @dev Encodes the payload to be signed by a trusted signer.
     */
    struct MoonbirdNestingLevel {
        uint256 tokenId;
        NestingLevel nestingLevel;
    }

    /**
     * @notice A MoonbirdNestingLevel with signature proving that the given nesting level is correct.
     * @dev The signature will be issued by a trusted signer.
     */
    struct SignedMoonbirdNestingLevel {
        MoonbirdNestingLevel payload;
        bytes signature;
    }

    /**
     * @notice Computes the hash of a given MoonbirdNestingLevel depending on chainId.
     */
    function digest(MoonbirdNestingLevel memory payload, uint256 chainId) internal pure returns (bytes32) {
        // We do not use EIP712 signatures here for the time being for simplicity (and since we will be the only ones
        // signing).
        return ECDSA.toEthSignedMessageHash(
            abi.encode(
                payload,
                // Adding chain id to prevent replay attacks using testnet signatures.
                chainId
            )
        );
    }

    /**
     * @notice Convenience wrapper around `digest(MoonbirdNestingLevel, uint256)` that uses the current chainId.
     */
    function digest(MoonbirdNestingLevel memory payload) internal view returns (bytes32) {
        return digest(payload, block.chainid);
    }

    /**
     * @notice Performs ECDSA.recover()y on the digest of the signed payload.
     */
    function recoverSigner(SignedMoonbirdNestingLevel memory signed, uint256 chainId) internal pure returns (address) {
        return ECDSA.recover(signed.payload.digest(chainId), signed.signature);
    }

    /**
     * @notice Convenience wrapper for `recoverSigner(SignedMoonbirdNestingLevel, block.chainid)`.
     */
    function recoverSigner(SignedMoonbirdNestingLevel memory signed) internal view returns (address) {
        return signed.recoverSigner(block.chainid);
    }
}
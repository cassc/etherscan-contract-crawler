// SPDX-License-Identifier: MIT-open-group
pragma solidity ^0.8.16;

import "contracts/libraries/errors/GenericParserLibraryErrors.sol";

import "contracts/libraries/parsers/BaseParserLibrary.sol";
import "contracts/libraries/parsers/RClaimsParserLibrary.sol";

/// @title Library to parse the RCert structure from a blob of capnproto state
library RCertParserLibrary {
    struct RCert {
        RClaimsParserLibrary.RClaims rClaims;
        uint256[4] sigGroupPublicKey;
        uint256[2] sigGroupSignature;
    }

    /** @dev size in bytes of a RCert cap'npro structure without the cap'n proto
      header bytes */
    uint256 internal constant _RCERT_SIZE = 264;
    /** @dev Number of bytes of a capnproto header, the state starts after the
      header */
    uint256 internal constant _CAPNPROTO_HEADER_SIZE = 8;
    /** @dev Number of Bytes of the sig group array */
    uint256 internal constant _SIG_GROUP_SIZE = 192;

    /// @notice Extracts the signature group out of a Capn Proto blob.
    /// @param src Binary state containing signature group state
    /// @param dataOffset offset of the signature group state inside src
    /// @return publicKey the public keys
    /// @return signature the signature
    /// @dev Execution cost: 1645 gas.
    function extractSigGroup(bytes memory src, uint256 dataOffset)
        internal
        pure
        returns (uint256[4] memory publicKey, uint256[2] memory signature)
    {
        if (dataOffset + RCertParserLibrary._SIG_GROUP_SIZE <= dataOffset) {
            revert GenericParserLibraryErrors.DataOffsetOverflow();
        }
        if (src.length < dataOffset + RCertParserLibrary._SIG_GROUP_SIZE) {
            revert GenericParserLibraryErrors.InsufficientBytes(
                src.length,
                dataOffset + RCertParserLibrary._SIG_GROUP_SIZE
            );
        }
        // _SIG_GROUP_SIZE = 192 bytes -> size in bytes of 6 uint256/bytes32 elements (6*32)
        publicKey[0] = BaseParserLibrary.extractUInt256(src, dataOffset + 0);
        publicKey[1] = BaseParserLibrary.extractUInt256(src, dataOffset + 32);
        publicKey[2] = BaseParserLibrary.extractUInt256(src, dataOffset + 64);
        publicKey[3] = BaseParserLibrary.extractUInt256(src, dataOffset + 96);
        signature[0] = BaseParserLibrary.extractUInt256(src, dataOffset + 128);
        signature[1] = BaseParserLibrary.extractUInt256(src, dataOffset + 160);
    }

    /**
    @notice This function is for deserializing state directly from capnproto
            RCert. It will skip the first 8 bytes (capnproto headers) and
            deserialize the RCert Data. If RCert is being extracted from
            inside of other structure (E.g PClaim capnproto) use the
            `extractInnerRCert(bytes, uint)` instead.
    */
    /// @param src Binary state containing a RCert serialized struct with Capn Proto headers
    /// @return the RCert struct
    /// @dev Execution cost: 4076 gas
    function extractRCert(bytes memory src) internal pure returns (RCert memory) {
        return extractInnerRCert(src, _CAPNPROTO_HEADER_SIZE);
    }

    /**
    @notice This function is for deserializing the RCert struct from an defined
            location inside a binary blob. E.G Extract RCert from inside of
            other structure (E.g RCert capnproto) or skipping the capnproto
            headers.
    */
    /// @param src Binary state containing a RCert serialized struct without Capn Proto headers
    /// @param dataOffset offset to start reading the RCert state from inside src
    /// @return rCert the RCert struct
    /// @dev Execution cost: 3691 gas
    function extractInnerRCert(bytes memory src, uint256 dataOffset)
        internal
        pure
        returns (RCert memory rCert)
    {
        if (dataOffset + _RCERT_SIZE <= dataOffset) {
            revert GenericParserLibraryErrors.DataOffsetOverflow();
        }
        if (src.length < dataOffset + _RCERT_SIZE) {
            revert GenericParserLibraryErrors.InsufficientBytes(
                src.length,
                dataOffset + _RCERT_SIZE
            );
        }
        rCert.rClaims = RClaimsParserLibrary.extractInnerRClaims(src, dataOffset + 16);
        (rCert.sigGroupPublicKey, rCert.sigGroupSignature) = extractSigGroup(src, dataOffset + 72);
    }
}
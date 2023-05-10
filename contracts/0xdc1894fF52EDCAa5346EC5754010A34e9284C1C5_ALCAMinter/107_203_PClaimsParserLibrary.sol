// SPDX-License-Identifier: MIT-open-group
pragma solidity ^0.8.16;

import "contracts/libraries/errors/GenericParserLibraryErrors.sol";

import "contracts/libraries/parsers/BaseParserLibrary.sol";
import "contracts/libraries/parsers/BClaimsParserLibrary.sol";
import "contracts/libraries/parsers/RCertParserLibrary.sol";

/// @title Library to parse the PClaims structure from a blob of capnproto state
library PClaimsParserLibrary {
    struct PClaims {
        BClaimsParserLibrary.BClaims bClaims;
        RCertParserLibrary.RCert rCert;
    }
    /** @dev size in bytes of a PCLAIMS cap'npro structure without the cap'n
      proto header bytes*/
    uint256 internal constant _PCLAIMS_SIZE = 456;
    /** @dev Number of bytes of a capnproto header, the state starts after the
      header */
    uint256 internal constant _CAPNPROTO_HEADER_SIZE = 8;

    /**
    @notice This function is for deserializing state directly from capnproto
            PClaims. Use `extractInnerPClaims()` if you are extracting PClaims
            from other capnproto structure (e.g Proposal).
    */
    /// @param src Binary state containing a RCert serialized struct with Capn Proto headers
    /// @return pClaims the PClaims struct
    /// @dev Execution cost: 7725 gas
    function extractPClaims(bytes memory src) internal pure returns (PClaims memory pClaims) {
        (pClaims, ) = extractInnerPClaims(src, _CAPNPROTO_HEADER_SIZE);
    }

    /**
    @notice This function is for deserializing the PClaims struct from an defined
            location inside a binary blob. E.G Extract PClaims from inside of
            other structure (E.g Proposal capnproto) or skipping the capnproto
            headers. Since PClaims is composed of a BClaims struct which has not
            a fixed sized depending on the txCount value, this function returns
            the pClaims struct deserialized and its binary size. The
            binary size must be used to adjust any other state that
            is being deserialized after PClaims in case PClaims is being
            deserialized from inside another struct.
    */
    /// @param src Binary state containing a PClaims serialized struct without Capn Proto headers
    /// @param dataOffset offset to start reading the PClaims state from inside src
    /// @return pClaims the PClaims struct
    /// @return pClaimsBinarySize the size of this PClaims
    /// @dev Execution cost: 7026 gas
    function extractInnerPClaims(
        bytes memory src,
        uint256 dataOffset
    ) internal pure returns (PClaims memory pClaims, uint256 pClaimsBinarySize) {
        if (dataOffset + _PCLAIMS_SIZE <= dataOffset) {
            revert GenericParserLibraryErrors.DataOffsetOverflow();
        }
        uint16 pointerOffsetAdjustment = BClaimsParserLibrary.getPointerOffsetAdjustment(
            src,
            dataOffset + 4
        );
        pClaimsBinarySize = _PCLAIMS_SIZE - pointerOffsetAdjustment;
        if (src.length < dataOffset + pClaimsBinarySize) {
            revert GenericParserLibraryErrors.InsufficientBytes(
                src.length,
                dataOffset + pClaimsBinarySize
            );
        }
        pClaims.bClaims = BClaimsParserLibrary.extractInnerBClaims(
            src,
            dataOffset + 16,
            pointerOffsetAdjustment
        );
        pClaims.rCert = RCertParserLibrary.extractInnerRCert(
            src,
            dataOffset + 16 + BClaimsParserLibrary._BCLAIMS_SIZE - pointerOffsetAdjustment
        );
    }
}
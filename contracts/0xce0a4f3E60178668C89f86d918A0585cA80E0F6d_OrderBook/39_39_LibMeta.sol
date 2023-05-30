// SPDX-License-Identifier: CAL
pragma solidity ^0.8.18;

import "./IMetaV1.sol";

/// @title LibMeta
/// @notice Need a place to put data that can be handled offchain like ABIs that
/// IS NOT etherscan.
library LibMeta {
    /// Returns true if the metadata bytes are prefixed by the Rain meta magic
    /// number. DOES NOT attempt to validate the body of the metadata as offchain
    /// tooling will be required for this.
    /// @param meta_ The data that may be rain metadata.
    /// @return True if `meta_` is metadata, false otherwise.
    function isRainMetaV1(bytes memory meta_) internal pure returns (bool) {
        if (meta_.length < 8) return false;
        uint256 mask_ = type(uint64).max;
        uint256 magicNumber_ = META_MAGIC_NUMBER_V1;
        assembly ("memory-safe") {
            magicNumber_ := and(mload(add(meta_, 8)), mask_)
        }
        return magicNumber_ == META_MAGIC_NUMBER_V1;
    }

    /// Reverts if the provided `meta_` is NOT metadata according to
    /// `isRainMetaV1`.
    /// @param meta_ The metadata bytes to check.
    function checkMetaUnhashed(bytes memory meta_) internal pure {
        if (!isRainMetaV1(meta_)) {
            revert NotRainMetaV1(meta_);
        }
    }

    /// Reverts if the provided `meta_` is NOT metadata according to
    /// `isRainMetaV1` OR it does not match the expected hash of its data.
    /// @param meta_ The metadata to check.
    function checkMetaHashed(bytes32 expectedHash_, bytes memory meta_) internal pure {
        bytes32 actualHash_ = keccak256(meta_);
        if (expectedHash_ != actualHash_) {
            revert UnexpectedMetaHash(expectedHash_, actualHash_);
        }
        checkMetaUnhashed(meta_);
    }
}
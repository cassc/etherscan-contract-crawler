// SPDX-License-Identifier: MIT
pragma solidity ^0.8.16;

import { JBTiered721FundingCycleMetadata } from "./../structs/JBTiered721FundingCycleMetadata.sol";

/// @title JBTiered721FundingCycleMetadataResolver
/// @notice Utility library to parse and store tiered 721 funding cycle metadata.
library JBTiered721FundingCycleMetadataResolver {
    function transfersPaused(uint256 _data) internal pure returns (bool) {
        return (_data & 1) == 1;
    }

    function mintingReservesPaused(uint256 _data) internal pure returns (bool) {
        return ((_data >> 1) & 1) == 1;
    }

    /// @notice Pack the tiered 721 funding cycle metadata.
    /// @param _metadata The metadata to validate and pack.
    /// @return packed The packed uint256 of all tiered 721 metadata params.
    function packFundingCycleGlobalMetadata(JBTiered721FundingCycleMetadata memory _metadata)
        internal
        pure
        returns (uint256 packed)
    {
        // pause transfers in bit 0.
        if (_metadata.pauseTransfers) packed |= 1;
        // pause mint reserves in bit 2.
        if (_metadata.pauseMintingReserves) packed |= 1 << 1;
    }

    /// @notice Expand the tiered 721 funding cycle metadata.
    /// @param _packedMetadata The packed metadata to expand.
    /// @return metadata The tiered 721 metadata object.
    function expandMetadata(uint8 _packedMetadata)
        internal
        pure
        returns (JBTiered721FundingCycleMetadata memory metadata)
    {
        return JBTiered721FundingCycleMetadata(transfersPaused(_packedMetadata), mintingReservesPaused(_packedMetadata));
    }
}
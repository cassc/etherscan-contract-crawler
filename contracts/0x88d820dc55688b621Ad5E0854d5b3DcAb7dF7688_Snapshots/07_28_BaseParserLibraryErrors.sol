// SPDX-License-Identifier: MIT-open-group
pragma solidity ^0.8.16;

library BaseParserLibraryErrors {
    error OffsetParameterOverflow(uint256 offset);
    error OffsetOutOfBounds(uint256 offset, uint256 srcLength);
    error LEUint16OffsetParameterOverflow(uint256 offset);
    error LEUint16OffsetOutOfBounds(uint256 offset, uint256 srcLength);
    error BEUint16OffsetParameterOverflow(uint256 offset);
    error BEUint16OffsetOutOfBounds(uint256 offset, uint256 srcLength);
    error BooleanOffsetParameterOverflow(uint256 offset);
    error BooleanOffsetOutOfBounds(uint256 offset, uint256 srcLength);
    error LEUint256OffsetParameterOverflow(uint256 offset);
    error LEUint256OffsetOutOfBounds(uint256 offset, uint256 srcLength);
    error BEUint256OffsetParameterOverflow(uint256 offset);
    error BEUint256OffsetOutOfBounds(uint256 offset, uint256 srcLength);
    error BytesOffsetParameterOverflow(uint256 offset);
    error BytesOffsetOutOfBounds(uint256 offset, uint256 srcLength);
    error Bytes32OffsetParameterOverflow(uint256 offset);
    error Bytes32OffsetOutOfBounds(uint256 offset, uint256 srcLength);
}
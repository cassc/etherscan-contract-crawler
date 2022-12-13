// SPDX-License-Identifier: MIT-open-group
pragma solidity ^0.8.16;

library GenericParserLibraryErrors {
    error DataOffsetOverflow();
    error InsufficientBytes(uint256 bytesLength, uint256 requiredBytesLength);
    error ChainIdZero();
    error HeightZero();
    error RoundZero();
}
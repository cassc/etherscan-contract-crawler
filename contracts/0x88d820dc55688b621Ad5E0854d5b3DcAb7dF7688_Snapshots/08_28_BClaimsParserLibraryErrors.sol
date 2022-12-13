// SPDX-License-Identifier: MIT-open-group
pragma solidity ^0.8.16;

library BClaimsParserLibraryErrors {
    error SizeThresholdExceeded(uint16 dataSectionSize);
    error DataOffsetOverflow(uint256 dataOffset);
    error NotEnoughBytes(uint256 dataOffset, uint256 srcLength);
    error ChainIdZero();
    error HeightZero();
}
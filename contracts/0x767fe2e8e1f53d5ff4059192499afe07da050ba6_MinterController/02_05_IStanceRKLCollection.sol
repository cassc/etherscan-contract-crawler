// SPDX-License-Identifier: MIT
pragma solidity =0.8.20;

interface IStanceRKLCollection {
    error NothingToMint();
    error ArgLengthMismatch();
    error MintToZeroAddr();

    function mint(address to, uint256[] memory tokenIds, uint256[] memory amounts) external;
}
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

interface CietyZoneErrors {
    error SignatureTimeOver(address caller, bytes32 orderHash, uint32 deadline);
    error MismatchSigner(address caller, bytes32 orderHash, uint32 deadline);
    error InvalidExtraDataLength();
    error InvalidOperator();
}
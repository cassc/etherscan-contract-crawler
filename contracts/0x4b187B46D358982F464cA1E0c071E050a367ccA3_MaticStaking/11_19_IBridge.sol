// SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.6;

interface IBridge {
    struct Metadata {
        bytes32 symbol;
        bytes32 name;
        uint256 originChain;
        address originAddress;
        bytes32 bondMetadata; // encoded metadata version, bond type
    }

    function deposit(
        address fromToken,
        uint256 toChain,
        address toAddress,
        uint256 amount
    ) external;

    function withdraw(
        bytes calldata encodedProof,
        bytes calldata rawReceipt,
        bytes calldata receiptRootSignature
    ) external;
}
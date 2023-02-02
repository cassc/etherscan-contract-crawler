// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

interface IMarketplaceErrors {
    /// @notice Emitted when theres an attempt to fulfill an order with an invalid nonce
    error InvalidNonce();

    /// @notice Emitted when theres an attempt to fulfill an order with endTime in the past
    error OrderExpired();

    /// @notice Emitted when theres an attempt to fulfill an order with startTime in the future
    error OrderNotActive();

    /// @notice Emitted when theres an attempt to fulfill an order in which the provided collection interface is not supported
    error InterfaceNotSupported();

    /// @notice Emitted when theres an attempt to fulfill an order in which the signer is the null address
    error InvalidSigner();

    /// @notice Emitted when theres an attempt to fulfill an order on a chain different than the one hardcoded into the contract
    error InvalidChain();

    /// @notice Emitted when theres an attempt to fulfill an order with a signature that doesnt match the signer
    error InvalidSignature();

    /// @notice Emitted when an order's merkle proof is invalid
    error InvalidMerkleProof();

    /// @notice Emitted when theres an attempt to use the marketplace when it's not active.
    error MarketplaceNotActive();
}
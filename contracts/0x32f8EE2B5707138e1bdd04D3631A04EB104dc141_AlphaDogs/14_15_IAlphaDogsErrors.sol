// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity >=0.8.14;

interface IAlphaDogsErrors {
    /// @dev 0x2783839d
    error InsufficientTokensAvailable();
    /// @dev 0x154e0758
    error InsufficientReservedTokensAvailable();
    /// @dev 0x8152a42e
    error InsufficientNonReservedTokensAvailable();
    /// @dev 0x53bb24f9
    error TokenLimitReached();
    /// @dev 0xb05e92fa
    error InvalidMerkleProof();
    /// @dev 0x2c5211c6
    error InvalidAmount();
    /// @dev 0x50e55ae1
    error InvalidAmountToClaim();
    /// @dev 0x6aa2a937
    error InvalidTokenID();
    /// @dev 0x1ae3550b
    error InvalidNameLength();
    /// @dev 0x8a0fcaee
    error InvalidSameValue();
    /// @dev 0x2a7c6b6e
    error InvalidTokenOwner();
    /// @dev 0x8e8ede30
    error FusionWithSameParentsForbidden();
    /// @dev 0x6d074376
    error FusionWithPuppyForbidden();
    /// @dev 0x36a1c33f
    error NotChanged();
    /// @dev 0x80cb55e2
    error NotActive();
    /// @dev 0xb4fa3fb3
    error InvalidInput();
    /// @dev 0xddb5de5e
    error InvalidSender();
    /// @dev 0x21029e82
    error InvalidChar();
}
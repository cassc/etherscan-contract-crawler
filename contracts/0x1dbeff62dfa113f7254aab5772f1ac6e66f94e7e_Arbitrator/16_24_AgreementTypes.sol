// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.17;

/// @dev Posible status for a position in the agreement.
enum PositionStatus {
    Idle,
    Joined,
    Finalized,
    Withdrawn,
    Disputed
}

/// @dev Posible status for an agreement.
enum AgreementStatus {
    Created,
    Ongoing,
    Finalized,
    Disputed
}

/// @notice Parameters to create new positions.
struct PositionParams {
    /// @dev Address of the owner of the position.
    address party;
    /// @dev Amount of agreement tokens in the position.
    uint256 balance;
}

/// @notice Data of position in the agreement.
struct PositionData {
    /// @dev Address of the owner of the position.
    address party;
    /// @dev Amount of agreement tokens in the position.
    uint256 balance;
    /// @dev Status of the position.
    PositionStatus status;
}

/// @dev Params to create new agreements.
struct AgreementParams {
    /// @dev Hash of the detailed terms of the agreement.
    bytes32 termsHash;
    /// @dev Required amount to join or merkle root of (address,amount).
    uint256 criteria;
    /// @dev URI of the metadata of the agreement.
    string metadataURI;
    /// @dev ERC20 token address to use for the agreement.
    address token;
}

/// @notice Data of an agreement.
struct AgreementData {
    /// @dev Hash of the detailed terms of the agreement.
    bytes32 termsHash;
    /// @dev Required amount to join or merkle root of (address,amount).
    uint256 criteria;
    /// @dev URI of the metadata of the agreement.
    string metadataURI;
    /// @dev ERC20 token address to use for the agreement.
    address token;
    /// @dev Total amount of token hold in the agreement.
    uint256 balance;
    /// @dev Status of the agreement.
    AgreementStatus status;
}
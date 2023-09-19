// SPDX-License-Identifier: GPL-3.0-or-later
// Copyright (C) 2022 Simplr
pragma solidity 0.8.11;

/// @title Contract Metadata
/// @author Chain Labs
/// @notice Stores important constant values of contract metadata
/// @dev constants that can help identify the collection type and version
contract ContractMetadata {
    /// @notice Contract Name
    /// @dev State used to identify the collection type
    /// @return CONTRACT_NAME name of contract type as string
    string public constant CONTRACT_NAME = "CollectionA";

    /// @notice Version
    /// @dev State used to identify the collection version
    /// @return VERSION version of contract as string
    string public constant VERSION = "0.1.0"; // contract version
}
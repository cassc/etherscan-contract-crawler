// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

/// @custom:security-contact [email protected]
interface IKFNC2023  {
    error InvalidMetadataURI();
    error InvalidContractMetadataURI();
    error InvalidOperatorDenylistRegistry();
    error NonEoA();
    error AlreadyMinted();
    error SupplyExceeded();
    error MintingNotAvailable();
    error OperatorDenied();
    error InvalidTimestamp();

    /// @notice Emitted when the metadataURL changes
    event MetadataURIChanged(
        address indexed sender,
        string previousURI,
        string newURI
    );

    /// @notice Emitted when the Contract metadataURL changes
    event ContractMetadataURIChanged(
        address indexed sender,
        string previousURI,
        string newURI
    );

    /// @notice Emitted when the Operator Denylist Registry changes
    event OperatorDenylistRegistryChanged(
        address indexed sender,
        address previousOperatorDenylistRegistry,
        address newOperatorDenylistRegistry
    );

    /// @notice Emitted when the Default Royalty changes
    event DefaultRoyaltyChanged(
        address indexed sender,
        address newReceiver,
        uint96 newFeeNumerator
    );

     /// @notice Emitted when Minting Timestamp change
    event MintTimestampChanged(
        address indexed sender, 
        uint256 previusMintTS, 
        uint256 newMintTS
    );
}
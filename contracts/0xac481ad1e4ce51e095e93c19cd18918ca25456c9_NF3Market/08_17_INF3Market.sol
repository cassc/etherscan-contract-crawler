// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.9;

/// @title NF3 Market Interface
/// @author NF3 Exchange
/// @dev This interface defines the functions related to public interaction and proxy interaction of the system.

interface INF3Market {
    /// -----------------------------------------------------------------------
    /// Errors
    /// -----------------------------------------------------------------------

    enum NF3MarketErrorCodes {
        FAILED_TO_SEND_ETH,
        LENGTH_NOT_EQUAL,
        INVALID_ADDRESS,
        INSUFFICIENT_ETH_SENT
    }

    error NF3MarketError(NF3MarketErrorCodes code);

    /// -----------------------------------------------------------------------
    /// Events
    /// -----------------------------------------------------------------------

    /// @dev Emits when new storage registry address has set.
    /// @param oldStorageRegistry Previous storage registry contract address
    /// @param newStorageRegistry New storage registry contract address
    event StorageRegistrySet(
        address oldStorageRegistry,
        address newStorageRegistry
    );

    /// @dev Emits when new trusted forwarder address has set.
    /// @param oldTrustedForwarder Previous trusted forwarder contract address
    /// @param newTrustedForwarder New vault trusted forwarder address
    event TrustedForwarderSet(
        address oldTrustedForwarder,
        address newTrustedForwarder
    );

    /// -----------------------------------------------------------------------
    /// Owner actions
    /// -----------------------------------------------------------------------

    /// @dev Set storage registry contract address.
    /// @param _storageRegistryAddress storage registry contract address
    function setStorageRegistry(address _storageRegistryAddress) external;

    /// @dev Set pause state of the contract.
    /// @param _setPause Boolean value of the pause state
    function setPause(bool _setPause) external;

    /// @dev Set trustedForwarders address.
    /// @param trustedForwarder address of the new trusted forwarder
    function setTrustedForwarder(address trustedForwarder) external;
}
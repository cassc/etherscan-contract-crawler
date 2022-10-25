// SPDX-License-Identifier: Apache 2.0
pragma solidity >=0.8.0 <0.9.0;

/// @title Rigoblock V3 Pool Events - Declares events of the pool contract.
/// @author Gabriele Rigo - <[email protected]>
interface IRigoblockV3PoolEvents {
    /// @notice Emitted when a new pool is initialized.
    /// @dev Pool is initialized at new pool creation.
    /// @param group Address of the factory.
    /// @param owner Address of the owner.
    /// @param baseToken Address of the base token.
    /// @param name String name of the pool.
    /// @param symbol String symbol of the pool.
    event PoolInitialized(
        address indexed group,
        address indexed owner,
        address indexed baseToken,
        string name,
        bytes8 symbol
    );

    /// @notice Emitted when new owner is set.
    /// @param old Address of the previous owner.
    /// @param current Address of the new owner.
    event NewOwner(address indexed old, address indexed current);

    /// @notice Emitted when pool operator updates NAV.
    /// @param poolOperator Address of the pool owner.
    /// @param pool Address of the pool.
    /// @param unitaryValue Value of 1 token in wei units.
    event NewNav(address indexed poolOperator, address indexed pool, uint256 unitaryValue);

    /// @notice Emitted when pool operator sets new mint fee.
    /// @param pool Address of the pool.
    /// @param who Address that is sending the transaction.
    /// @param transactionFee Number of the new fee in wei.
    event NewFee(address indexed pool, address indexed who, uint16 transactionFee);

    /// @notice Emitted when pool operator updates fee collector address.
    /// @param pool Address of the pool.
    /// @param who Address that is sending the transaction.
    /// @param feeCollector Address of the new fee collector.
    event NewCollector(address indexed pool, address indexed who, address feeCollector);

    /// @notice Emitted when pool operator updates minimum holding period.
    /// @param pool Address of the pool.
    /// @param minimumPeriod Number of seconds.
    event MinimumPeriodChanged(address indexed pool, uint48 minimumPeriod);

    /// @notice Emitted when pool operator updates the mint/burn spread.
    /// @param pool Address of the pool.
    /// @param spread Number of the spread in basis points.
    event SpreadChanged(address indexed pool, uint16 spread);

    /// @notice Emitted when pool operator sets a kyc provider.
    /// @param pool Address of the pool.
    /// @param kycProvider Address of the kyc provider.
    event KycProviderSet(address indexed pool, address indexed kycProvider);
}
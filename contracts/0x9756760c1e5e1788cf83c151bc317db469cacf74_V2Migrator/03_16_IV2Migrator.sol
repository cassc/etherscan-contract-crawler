// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity >=0.8.4;

import "../ERC-721/ERC721Pool.sol";

/// @title IERC721PoolV1
/// @author Hifi
interface IERC721PoolV1 {
    /// @notice Withdraw specified NFTs in exchange for an equivalent amount of pool tokens.
    ///
    /// @dev Emits a {Withdraw} event.
    ///
    /// @dev Requirements:
    ///
    /// - The length of `ids` must be greater than zero.
    /// - The length of `ids` scaled to 18 decimals.
    /// - The address `to` must not be the zero address.
    ///
    /// @param ids The asset token IDs to be released from the pool.
    function withdraw(uint256[] calldata ids) external;
}

/// @title IERC721PoolFactoryV1
/// @author Hifi
interface IERC721PoolFactoryV1 {
    /// CONSTANT FUNCTIONS ///

    /// @notice Returns the pool of the given asset token.
    /// @param asset The underlying ERC-721 asset contract address.
    function getPool(address asset) external view returns (address pool);
}

/// @title IV2Migrator
/// @author Hifi
interface IV2Migrator {
    /// CUSTOM ERRORS ///

    error V2Migrator__InsufficientIn();
    error V2Migrator__UnapprovedOperator();
    error V2Migrator__V1PoolDoesNotExist();
    error V2Migrator__V2PoolDoesNotExist();

    /// EVENTS ///

    /// @notice Emitted when NFTs are migrated from the V1 pool to the V2 pool.
    /// @param asset The underlying ERC-721 asset contract address.
    /// @param caller The caller of the function equal to msg.sender.
    /// @param ids The asset token IDs.
    event Migrate(address asset, address caller, uint256[] ids);

    /// NON-CONSTANT FUNCTIONS ///
    /// @notice Migrate NFTs from the V1 pool to the V2 pool.
    ///
    /// @dev Emits a {Migrate} event.
    ///
    /// @dev Requirements:
    ///
    /// - The V1 pool must exist.
    /// - The V2 pool must exist.
    /// - The length of `ids` must be greater than zero.
    /// - The caller must have allowed this contract to transfer the v1 pool tokens.
    ///
    /// @param asset The underlying ERC-721 asset contract address.
    /// @param ids The asset token IDs to be migrate from the V1 pool to V2 Pool.
    function migrate(address asset, uint256[] calldata ids) external;
}
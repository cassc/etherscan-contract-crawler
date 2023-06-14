// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity >=0.8.4;

import "./IERC721Pool.sol";

/// @title IPeripheralERC721Pool
/// @author Hifi
interface IPeripheralERC721Pool {
    /// CUSTOM ERRORS ///

    error PeripheralERC721Pool__InsufficientIn();
    error PeripheralERC721Pool__NoNFTsWithdrawn();
    error PeripheralERC721Pool__UnapprovedOperator();

    /// EVENTS ///

    /// @notice Emitted when NFTs are deposited in exchange for an equivalent amount of pool tokens.
    /// @param pool The address of the pool.
    /// @param ids The asset token IDs sent from the user's account to the pool.
    /// @param caller The caller of the function equal to msg.sender.
    event BulkDeposit(address pool, uint256[] ids, address caller);

    /// @notice Emitted when NFTs are withdrawn from the pool in exchange for an equivalent amount of pool tokens.
    /// @param pool The address of the pool.
    /// @param ids The asset token IDs released from the pool.
    /// @param caller The caller of the function equal to msg.sender.
    event BulkWithdraw(address pool, uint256[] ids, address caller);

    /// @notice Emitted when as many as available NFTs are withdrawn from the pool in exchange for an equal amount of pool tokens.
    /// @param pool The address of the pool.
    /// @param withdrawnIds The asset token IDs released from the pool.
    /// @param caller The caller of the function equal to msg.sender.
    event WithdrawAvailable(address pool, uint256[] withdrawnIds, address caller);

    /// CONSTANT FUNCTIONS ///

    // /// @notice The address of the pool.
    // function pool() external view returns (address);

    /// NON-CONSTANT FUNCTIONS ///

    /// @notice Deposit NFTs in exchange for an equivalent amount of pool tokens.
    ///
    /// @dev Emits a {Deposit} event.
    ///
    /// @dev Requirements:
    ///
    /// - The length of `ids` must be greater than zero.
    /// - The caller must have allowed the pool to transfer the NFTs.
    /// - The address `beneficiary` must not be the zero address.
    ///
    /// @param pool The address of the pool.
    /// @param ids The asset token IDs sent from the user's account to the pool.
    function bulkDeposit(IERC721Pool pool, uint256[] calldata ids) external;

    /// @notice Withdraw specified NFTs in exchange for an equivalent amount of pool tokens.
    ///
    /// @dev Emits a {Withdraw} event.
    ///
    /// @dev Requirements:
    ///
    /// - The length of `ids` must be greater than zero.
    /// - The caller must have allowed the PeripheralERC721Pool to transfer the pool tokens by calling
    ///   `approve()` on the pool token contract with sufficient allowance before calling this function.
    ///
    /// @param pool The address of the pool.
    /// @param ids The asset token IDs to be released from the pool.
    function bulkWithdraw(IERC721Pool pool, uint256[] calldata ids) external;

    /// @notice Withdraw specified available non-overlapping NFTs in exchange for an equivalent amount of pool tokens.
    ///
    /// @dev Emits a {WithdrawAvailable} event.
    ///
    /// @dev Requirements:
    ///
    /// - The length of `ids` must be greater than zero.
    /// - The caller must have allowed the PeripheralERC721Pool to transfer the pool tokens.
    /// - The address `beneficiary` must not be the zero address.
    ///
    /// @param pool The address of the pool.
    /// @param ids The asset token IDs to be released from the pool.
    function withdrawAvailable(IERC721Pool pool, uint256[] calldata ids) external;
}
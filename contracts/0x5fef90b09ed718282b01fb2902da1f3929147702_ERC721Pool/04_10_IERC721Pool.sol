// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity >=0.8.4;

/// @title IERC721Pool
/// @author Hifi
interface IERC721Pool {
    /// CUSTOM ERRORS ///

    error ERC721Pool__InsufficientIn();
    error ERC721Pool__InvalidTo();

    /// EVENTS ///

    /// @notice Emitted when NFTs are deposited and an equal amount of pool tokens are minted.
    /// @param ids The asset token IDs sent from the user's account to the pool.
    /// @param caller The caller of the function equal to msg.sender
    event Deposit(uint256[] ids, address caller);

    /// @notice Emitted when NFTs are withdrawn from the pool in exchange for an equal amount of pool tokens.
    /// @param ids The asset token IDs released from the pool.
    /// @param caller The caller of the function equal to msg.sender
    event Withdraw(uint256[] ids, address caller);

    /// CONSTANT FUNCTIONS ///

    /// @notice Returns the asset token ID held at index.
    /// @param index The index to check.
    function holdingAt(uint256 index) external view returns (uint256);

    /// @notice Returns the total number of asset token IDs held.
    function holdingsLength() external view returns (uint256);

    /// NON-CONSTANT FUNCTIONS ///

    /// @notice Deposit NFTs in exchange for an equivalent amount of pool tokens.
    ///
    /// @dev Emits a {Deposit} event.
    ///
    /// @dev Requirements:
    ///
    /// - The length of `ids` must be greater than zero.
    /// - The length of `ids` scaled to 18 decimals.
    /// - The address `to` must not be the zero address.
    ///
    /// @param ids The asset token IDs sent from the user's account to the pool.
    function deposit(uint256[] calldata ids) external;

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

    /// @notice Withdraw specified NFTs in exchange for an equivalent amount of pool tokens.
    ///
    /// @dev Emits a {Withdraw} event.
    ///
    /// @dev Requirements:
    /// - The `signature` must be a valid signed approval given by the caller to the ERC721Pool to spend pool tokens
    ///   equal to the length of the ids array for the given `deadline` and the caller's current nonce.
    /// - The length of `ids` must be greater than zero.
    /// - The length of `ids` scaled to 18 decimals.
    /// - The address `to` must not be the zero address.
    ///
    /// @param ids The asset token IDs to be released from the pool.
    /// @param deadline The deadline beyond which the signature is not valid anymore.
    /// @param signature The packed signature for ERC721Pool.
    function withdrawWithSignature(
        uint256[] calldata ids,
        uint256 deadline,
        bytes memory signature
    ) external;
}
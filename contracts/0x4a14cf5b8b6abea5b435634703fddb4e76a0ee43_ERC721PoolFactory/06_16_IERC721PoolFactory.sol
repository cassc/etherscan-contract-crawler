// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity >=0.8.4;

import "@openzeppelin/contracts/access/Ownable.sol";

/// @title IERC721PoolFactory
/// @author Hifi
interface IERC721PoolFactory {
    /// CUSTOM ERRORS ///

    error ERC721PoolFactory__DoesNotImplementIERC721Metadata();
    error ERC721PoolFactory__PoolAlreadyExists();
    error ERC721PoolFactory__PoolDoesNotExist();
    error ERC721PoolFactory__RecipientZeroAddress();
    error ERC721PoolFactory__RegistrarZeroAddress();

    /// EVENTS ///

    /// @notice Emitted when a new pool is created.
    /// @param name The ERC-20 name of the pool.
    /// @param symbol The ERC-20 symbol of the pool.
    /// @param asset The underlying ERC-721 asset contract address.
    /// @param pool The created pool contract address.
    event CreatePool(string name, string symbol, address indexed asset, address indexed pool);

    /// CONSTANT FUNCTIONS ///

    /// @notice Returns the pool of the given asset token.
    /// @param asset The underlying ERC-721 asset contract address.
    function getPool(address asset) external view returns (address pool);

    /// @notice Returns the list of all pools.
    function allPools(uint256) external view returns (address pool);

    /// @notice Returns the length of the pools list.
    function allPoolsLength() external view returns (uint256);

    /// @notice Returns the nonce used to calculate the salt for deploying new pools.
    /// @dev The nonce ensures that each new pool contract is deployed at a unique address.
    function nonce() external view returns (uint256);

    /// NON-CONSTANT FUNCTIONS ///

    /// @notice Create a new pool.
    ///
    /// @dev Emits a {CreatePool} event.
    ///
    /// @dev Requirements:
    /// - Can only create one pool per asset.
    ///
    /// @param asset The underlying ERC-721 asset contract address.
    function createPool(address asset) external;

    /// @notice Rescue the last NFT of a pool.
    ///
    /// @dev Emits a {RescueLastNFT} event.
    ///
    /// @dev Requirements:
    /// - Can only rescue the last NFT of a pool.
    /// - Can only be called by the owner.
    /// - The pool must exist.
    ///
    /// @param asset The underlying ERC-721 asset contract address.
    /// @param to The address to which the NFT will be sent.
    function rescueLastNFT(address asset, address to) external;

    /// @notice Set the ENS name of a pool.
    ///
    /// @dev Requirements:
    /// - Can only be called by the owner.
    /// - The pool must exist.
    ///
    /// @param asset The underlying ERC-721 asset contract address.
    /// @param registrar The ENS registrar address.
    /// @param name The ENS name.
    function setENSName(
        address asset,
        address registrar,
        string memory name
    ) external;
}
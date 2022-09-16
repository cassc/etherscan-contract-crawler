// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0 <0.9.0;

import "./peripherals/IGovernable.sol";

/// @title Factory of Pair Managers
/// @notice This contract creates new pair managers
interface IPairManagerFactory is IGovernable {
    // Variables

    /// @notice Maps the address of a Uniswap pool, to the address of the corresponding PairManager
    ///         For example, the uniswap address of DAI-WETH, will return the Keep3r/DAI-WETH pair manager address
    /// @param _pool The address of the Uniswap pool
    /// @return _pairManager The address of the corresponding pair manager
    function pairManagers(address _pool) external view returns (address _pairManager);

    // Events

    /// @notice Emitted when a new pair manager is created
    /// @param _pool The address of the corresponding Uniswap pool
    /// @param _pairManager The address of the just-created pair manager
    event PairCreated(address _pool, address _pairManager);

    // Errors

    /// @notice Throws an error if the pair manager is already initialized
    error AlreadyInitialized();

    /// @notice Throws an error if the caller is not the owner
    error OnlyOwner();

    // Methods

    /// @notice Creates a new pair manager based on the address of a Uniswap pool
    ///         For example, the uniswap address of DAI-WETH, will create the Keep3r/DAI-WETH pool
    /// @param _pool The address of the Uniswap pool the pair manager will be based of
    /// @return _pairManager The address of the just-created pair manager
    function createPairManager(address _pool) external returns (address _pairManager);
}
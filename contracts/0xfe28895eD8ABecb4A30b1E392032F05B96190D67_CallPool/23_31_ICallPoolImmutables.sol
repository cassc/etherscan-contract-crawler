// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity ^0.8.0;

/// @title Pool state that never changes
/// @notice These parameters are fixed for a pool forever, i.e., the methods will always return the same values
interface ICallPoolImmutables {
    /// @notice The contract that deployed the pool, which must adhere to the IUniswapV3Factory interface
    /// @return The contract address
    function factory() external view returns (address);

    function nft() external view returns (address);

    function nToken() external view returns (address);

    function callToken() external view returns (address);

    function oracle() external view returns (address);

    function premium() external view returns (address);
}
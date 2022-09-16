// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0 <0.9.0;

import "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";

/// @title  Pair Manager interface
/// @notice Generic interface for Keep3r liquidity pools (kLP)
interface IPairManager is IERC20Metadata {
    /// @notice Address of the pool from which the Keep3r pair manager will interact with
    /// @return _pool The pool's address
    function pool() external view returns (address _pool);

    /// @notice Token0 of the pool
    /// @return _token0 The address of token0
    function token0() external view returns (address _token0);

    /// @notice Token1 of the pool
    /// @return _token1 The address of token1
    function token1() external view returns (address _token1);
}
// SPDX-License-Identifier: AGPL-3.0

pragma solidity ^0.8.13;

interface IAaveToken {
    // @dev Deployed ddress of the associated Aave Pool
    function POOL() external view returns (address);

    /// @dev The address of the underlying asset
    function UNDERLYING_ASSET_ADDRESS() external view returns (address);
}
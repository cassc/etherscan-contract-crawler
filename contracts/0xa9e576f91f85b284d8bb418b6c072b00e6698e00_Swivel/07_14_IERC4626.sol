// SPDX-License-Identifier: AGPL-3.0

pragma solidity ^0.8.13;

interface IERC4626 {
    function deposit(uint256, address) external returns (uint256);

    function withdraw(
        uint256,
        address,
        address
    ) external returns (uint256);

    /// @dev Converts the given 'assets' (uint256) to 'shares', returning that amount
    function convertToAssets(uint256) external view returns (uint256);

    /// @dev The address of the underlying asset
    function asset() external view returns (address);
}
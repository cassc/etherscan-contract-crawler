// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

interface IOLAS {
    /// @dev Mints OLA tokens.
    /// @param account Account address.
    /// @param amount OLA token amount.
    function mint(address account, uint256 amount) external;

    /// @dev Provides OLA token time launch.
    /// @return Time launch.
    function timeLaunch() external view returns (uint256);
}
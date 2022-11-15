// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

/// implemented by erc1155 tokens to allow burning
interface IERC1155Burn {

    /// @notice event emitted when tokens are burned
    event Burned(
        address target,
        uint256 tokenHash,
        uint256 amount
    );

    /// @notice burn tokens of specified amount from the specified address
    /// @param target the burn target
    /// @param tokenHash the token hash to burn
    /// @param amount the amount to burn
    function burn(
        address target,
        uint256 tokenHash,
        uint256 amount
    ) external;


}
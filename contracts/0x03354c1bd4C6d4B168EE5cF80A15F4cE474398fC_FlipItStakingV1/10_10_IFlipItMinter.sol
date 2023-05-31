// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;

interface IFlipItMinter {
    /// @notice Mints a given number of tokens and transfers them to the recipient.
    /// @param recipient Address of the recipient.
    /// @param amount Amount of the token to mint.
    /// @return List of minted token ids.
    function mintBurger(address recipient, uint256 amount) external returns (uint256[] memory);

    /// @notice Mints a given number of tokens and transfers them to the recipient.
    /// @param recipient Address of the recipient.
    /// @param amount Amount of the token to mint.
    /// @return List of minted token ids.
    function mintIngredient(address recipient, uint256 amount) external returns (uint256[] memory);
}
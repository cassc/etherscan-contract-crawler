// SPDX-License-Identifier: MIT
pragma solidity ^0.8.12;

interface IBase721A {
    /// @notice Allows a `minter` to mint `amount` tokens to `to` with `extraData_`
    /// @param to to whom we need to mint
    /// @param amount how many to mint
    /// @param extraData extraData for these items
    function mintTo(
        address to,
        uint256 amount,
        uint24 extraData
    ) external;
}
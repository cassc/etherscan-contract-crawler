// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity >=0.8.14;

interface IAlphaToken {
    /// @dev 0x36a1c33f
    error NotChanged();
    /// @dev 0x3d693ada
    error NotAllowed();

    function mint(address addr, uint256 amount) external;

    function burn(address from, uint256 amount) external;
}
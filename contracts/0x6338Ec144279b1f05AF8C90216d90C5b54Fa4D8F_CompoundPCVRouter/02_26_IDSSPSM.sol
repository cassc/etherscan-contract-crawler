// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity =0.8.13;

/// @title Interface for the Maker DAO PSMs
/// @dev gem refers to collateral tokens
interface IDSSPSM {
    /// @notice Swap DAI for the underlying collateral type
    function buyGem(address usr, uint256 gemAmt) external;

    /// @notice Swap collateral type for DAI
    function sellGem(address usr, uint256 gemAmt) external;

    /// @notice redeem fee
    function tin() external view returns (uint256);

    /// @notice mint fee
    function tout() external view returns (uint256);

    /// @notice set mint or redeem fee
    function file(bytes32 what, uint256 data) external;
}
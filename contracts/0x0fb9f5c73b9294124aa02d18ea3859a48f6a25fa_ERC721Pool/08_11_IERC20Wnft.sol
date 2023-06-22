// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity >=0.8.4;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/draft-IERC20Permit.sol";

/// @title IERC20Wnft
/// @author Hifi
interface IERC20Wnft is IERC20Permit, IERC20Metadata {
    /// CUSTOM ERRORS ///

    error ERC20Wnft__Forbidden();
    error ERC20Wnft__InvalidSignature();
    error ERC20Wnft__PermitExpired();

    /// EVENTS ///

    /// @notice Emitted when the contract is initialized.
    /// @param name The ERC-20 name.
    /// @param symbol The ERC-20 symbol.
    /// @param asset The underlying ERC-721 asset contract address.
    event Initialize(string name, string symbol, address indexed asset);

    /// CONSTANT FUNCTIONS ///

    /// @notice Returns the address of the underlying ERC-721 asset.
    function asset() external view returns (address);

    /// @notice Returns the factory contract address.
    function factory() external view returns (address);

    /// NON-CONSTANT FUNCTIONS ///

    /// @notice Initializes the contract with the given values.
    ///
    /// @dev Emits an {Initialize} event.
    ///
    /// @dev Requirements:
    /// - Can only be called by the factory.
    ///
    /// @param name The ERC-20 name.
    /// @param symbol The ERC-20 symbol.
    /// @param asset The underlying ERC-721 asset contract address.
    function initialize(
        string memory name,
        string memory symbol,
        address asset
    ) external;
}
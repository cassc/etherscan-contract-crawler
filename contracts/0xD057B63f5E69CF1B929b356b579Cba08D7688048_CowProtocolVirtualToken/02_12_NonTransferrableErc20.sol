// SPDX-License-Identifier: LGPL-3.0-or-later
pragma solidity ^0.8.10;

import "../vendored/interfaces/IERC20.sol";

/// @dev A contract of an ERC20 token that cannot be transferred.
/// @title Non-Transferrable ERC20
/// @author CoW Protocol Developers
abstract contract NonTransferrableErc20 is IERC20 {
    /// @dev The ERC20 name of the token
    string public name;
    /// @dev The ERC20 symbol of the token
    string public symbol;
    /// @dev The ERC20 number of decimals of the token
    uint8 public constant decimals = 18; // solhint-disable const-name-snakecase

    // solhint-disable-next-line no-empty-blocks
    constructor(string memory _name, string memory _symbol) {
        name = _name;
        symbol = _symbol;
    }

    /// @dev This error is fired when trying to perform an action that is not
    /// supported by the contract, like transfers and approvals. These actions
    /// will never be supported.
    error NotSupported();

    /// @dev All types of transfers are permanently disabled.
    function transferFrom(
        address,
        address,
        uint256
    ) public pure returns (bool) {
        revert NotSupported();
    }

    /// @dev All types of transfers are permanently disabled.
    function transfer(address, uint256) public pure returns (bool) {
        revert NotSupported();
    }

    /// @dev All types of approvals are permanently disabled to reduce code
    /// size.
    function approve(address, uint256) public pure returns (bool) {
        revert NotSupported();
    }

    /// @dev Approvals cannot be set, so allowances are always zero.
    function allowance(address, address) public pure returns (uint256) {
        return 0;
    }
}
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.8;

import {IERC20Permit} from "./../interfaces/IERC20Permit.sol";
import {ERC20PermitStorage} from "./../libraries/ERC20PermitStorage.sol";
import {Context} from "@openzeppelin/contracts/utils/Context.sol";

/// @title ERC20 Fungible Token Standard, optional extension: Permit (proxiable version).
/// @dev This contract is to be used via inheritance in a proxied implementation.
/// @dev Note: This contract requires ERC20 (Fungible Token Standard).
/// @dev Note: This contract requires ERC20Detailed.
abstract contract ERC20PermitBase is Context, IERC20Permit {
    using ERC20PermitStorage for ERC20PermitStorage.Layout;

    /// @inheritdoc IERC20Permit
    function permit(address owner, address spender, uint256 value, uint256 deadline, uint8 v, bytes32 r, bytes32 s) external override {
        ERC20PermitStorage.layout().permit(owner, spender, value, deadline, v, r, s);
    }

    /// @inheritdoc IERC20Permit
    function nonces(address owner) external view override returns (uint256) {
        return ERC20PermitStorage.layout().nonces(owner);
    }

    /// @inheritdoc IERC20Permit
    // solhint-disable-next-line func-name-mixedcase
    function DOMAIN_SEPARATOR() external view override returns (bytes32) {
        return ERC20PermitStorage.DOMAIN_SEPARATOR();
    }
}
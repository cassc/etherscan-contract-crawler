// SPDX-License-Identifier: MIT
pragma solidity ^0.8.8;

import {IERC20Mintable} from "./../interfaces/IERC20Mintable.sol";
import {ERC20Storage} from "./../libraries/ERC20Storage.sol";
import {AccessControlStorage} from "./../../../access/libraries/AccessControlStorage.sol";
import {Context} from "@openzeppelin/contracts/utils/Context.sol";

/// @title ERC20 Fungible Token Standard, optional extension: Mintable (proxiable version).
/// @dev This contract is to be used via inheritance in a proxied implementation.
/// @dev Note: This contract requires ERC20 (Fungible Token Standard).
/// @dev Note: This contract requires AccessControl.
abstract contract ERC20MintableBase is Context, IERC20Mintable {
    using ERC20Storage for ERC20Storage.Layout;
    using AccessControlStorage for AccessControlStorage.Layout;

    bytes32 public constant MINTER_ROLE = "minter";

    /// @inheritdoc IERC20Mintable
    /// @dev Reverts if the sender does not have the 'minter' role.
    function mint(address to, uint256 value) external virtual override {
        AccessControlStorage.layout().enforceHasRole(MINTER_ROLE, _msgSender());
        ERC20Storage.layout().mint(to, value);
    }

    /// @inheritdoc IERC20Mintable
    /// @dev Reverts if the sender does not have the 'minter' role.
    function batchMint(address[] calldata recipients, uint256[] calldata values) external virtual override {
        AccessControlStorage.layout().enforceHasRole(MINTER_ROLE, _msgSender());
        ERC20Storage.layout().batchMint(recipients, values);
    }
}
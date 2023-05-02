// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./IAccessControlEnumerable.sol";
import "./Context.sol";
import "./AccessControlEnumerable.sol";
import "./ERC20Burnable.sol";

/// @dev implements custom rebaser role
contract ERC20PresetMinterRebaser is Context, AccessControlEnumerable, ERC20Burnable {
    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");
    bytes32 public constant REBASER_ROLE = keccak256("REBASER_ROLE");

    constructor(string memory name, string memory symbol) ERC20(name, symbol) {
        _setupRole(DEFAULT_ADMIN_ROLE, _msgSender());
        _setupRole(MINTER_ROLE, _msgSender());
        _setupRole(REBASER_ROLE, _msgSender());
    }
}

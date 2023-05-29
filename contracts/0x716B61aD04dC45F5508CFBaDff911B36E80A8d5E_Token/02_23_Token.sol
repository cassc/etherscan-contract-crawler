// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import { ERC20 } from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import { ERC20Pausable } from "@openzeppelin/contracts/token/ERC20/extensions/ERC20Pausable.sol";

import { ERC20PresetMinterPauser } from "@openzeppelin/contracts/token/ERC20/presets/ERC20PresetMinterPauser.sol";

import { ERC20Permit } from "@openzeppelin/contracts/token/ERC20/extensions/draft-ERC20Permit.sol";

import { ERC20OnApprove } from "./ERC20OnApprove.sol";

contract Token is ERC20PresetMinterPauser, ERC20Permit, ERC20OnApprove {
    bytes32 public constant MINTER_ADMIN_ROLE = keccak256("MINTER_ADMIN_ROLE");
    bytes32 public constant PAUSER_ADMIN_ROLE = keccak256("PAUSER_ADMIN_ROLE");

    constructor(
        string memory name_,
        string memory symbol_,
        uint256 initialSupply_
    ) ERC20PresetMinterPauser(name_, symbol_) ERC20Permit(name_) {
        _mint(_msgSender(), initialSupply_);

        _setRoleAdmin(MINTER_ROLE, MINTER_ADMIN_ROLE);
        _setRoleAdmin(PAUSER_ROLE, PAUSER_ADMIN_ROLE);

        _setupRole(MINTER_ADMIN_ROLE, _msgSender());
        _setupRole(PAUSER_ADMIN_ROLE, _msgSender());
    }

    /**
     * @dev change DEFAULT_ADMIN_ROLE to `account`.
     *      To revoke DEFAULT_ADMIN_ROLE, use `revokeRole(DEFAULT_ADMIN_ROLE, account)`
     */
    function changeAdminRole(address account) external {
        require(account != address(0), "Token: zero-address");
        changeRole(DEFAULT_ADMIN_ROLE, account);
    }

    /**
     * @dev grant and revoke `role` to `account`
     */
    function changeRole(bytes32 role, address account) public {
        grantRole(role, account);
        revokeRole(role, _msgSender());
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal override(ERC20, ERC20PresetMinterPauser) {
        super._beforeTokenTransfer(from, to, amount);
    }

    function getChainId() external view returns (uint256) {
        return block.chainid;
    }
}
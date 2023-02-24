//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.4;

import "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/ERC20Upgradeable.sol";


contract VC is ERC20Upgradeable, AccessControlUpgradeable {
    bytes32 public constant MINTER_ROLE = "MINTER_ROLE";

    function initialize() public initializer {
        __ERC20_init("Voyage Combat", "VC");
        __AccessControl_init();
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
    }

    function mint(address account, uint256 amount)
        public
        onlyRole(MINTER_ROLE)
    {
        _mint(account, amount);
    }

    function burn(address account, uint256 amount)
        public
        onlyRole(MINTER_ROLE)
    {
        _burn(account, amount);
    }

    function transferAdmin(address admin) public onlyRole(DEFAULT_ADMIN_ROLE) {
        _revokeRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _grantRole(DEFAULT_ADMIN_ROLE, admin);
    }
}
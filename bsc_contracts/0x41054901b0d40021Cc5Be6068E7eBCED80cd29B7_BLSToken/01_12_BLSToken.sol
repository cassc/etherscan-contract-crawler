// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";

interface IMEVChecker {
    function mevChecker(address from, address to, uint256 amount) external;
}

contract BLSToken is ERC20, ERC20Burnable, AccessControl {
    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE_BLS");
    IMEVChecker checker;

    constructor(address _checker) ERC20("BLS", "BLS") {
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _grantRole(MINTER_ROLE, msg.sender);
        checker = IMEVChecker(_checker);
    }

    function setChecker(address _checker) public onlyRole(DEFAULT_ADMIN_ROLE) {
        checker = IMEVChecker(_checker);
    }

    function mint(address to, uint256 amount) public onlyRole(MINTER_ROLE) {
        _mint(to, amount);
    }

    function _beforeTokenTransfer(address from, address to, uint256 amount)
        internal
        override
    {
        checker.mevChecker(from, to, amount);
        super._beforeTokenTransfer(from, to, amount);
    }
}
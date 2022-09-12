// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.2;

import "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";

contract Manager is AccessControlUpgradeable {
    bytes32 public constant MANAGER_ROLE = keccak256("MANAGER_ROLE");
    bytes32 public constant WITHDRAW_ROLE = keccak256("WITHDRAW_ROLE");
    bytes32 public constant MINT_ROLE = keccak256("MINT_ROLE");
    bytes32 public constant BURN_ROLE = keccak256("BURN_ROLE");
    bytes32 public constant DRAW_ROLE = keccak256("DRAW_ROLE");
    modifier onlyManager() {
        require(hasRole(MANAGER_ROLE, msg.sender), "Caller is not a manager");
        _;
    }
    modifier onlyBurn() {
        require((hasRole(BURN_ROLE, msg.sender) || hasRole(MANAGER_ROLE, msg.sender)), "Caller is No permission");
        _;
    }
    modifier onlyMint() {
        require((hasRole(MINT_ROLE, msg.sender) || hasRole(MANAGER_ROLE, msg.sender)), "Caller is No permission");
        _;
    }
    modifier onlyWithdraw() {
        require((hasRole(WITHDRAW_ROLE, msg.sender) || hasRole(MANAGER_ROLE, msg.sender)), "Caller is No permission");
        _;
    }
    modifier onlyDraw() {
        require((hasRole(DRAW_ROLE, msg.sender) || hasRole(MANAGER_ROLE, msg.sender)), "Caller is No permission");
        _;
    }
}
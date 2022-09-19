// contracts/GLDToken.sol
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";

contract GPCToken is ERC20, AccessControl {
    
    bytes32 public constant ROOT_ROLE = keccak256("ROOT");
    bytes32 public constant MANAGER_ROLE = keccak256("MANAGER");

    constructor() ERC20("Gene Player Coin", "GPC") {
        _setRoleAdmin(MANAGER_ROLE, ROOT_ROLE);
        _setupRole(ROOT_ROLE, msg.sender);
        _setupRole(MANAGER_ROLE, msg.sender);
    }

    function dispense(address recipient, uint256 amount) public onlyRole(MANAGER_ROLE) {
        _mint(recipient, amount);
    }

    function addManager(address manager) public onlyRole(ROOT_ROLE) {
        grantRole(MANAGER_ROLE, manager);
    }
    function revokeManager(address manager) public onlyRole(ROOT_ROLE) {
        revokeRole(MANAGER_ROLE, manager);
    }
}
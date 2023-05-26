// SPDX-License-Identifier: MIT
pragma solidity ^0.8.12;
import "@openzeppelin/contracts/access/AccessControl.sol";

abstract contract Permission is AccessControl{
    bytes32 public constant MANAGER_ROLE = keccak256("MANAGER_ROLE");
    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");
    
    constructor(){
        _setupRole(DEFAULT_ADMIN_ROLE, _msgSender());
        _setupRole(MANAGER_ROLE, _msgSender());
        _setupRole(MINTER_ROLE, _msgSender());
    }

    function grantMinter(address account) external onlyRole(MANAGER_ROLE){
        _grantRole(MINTER_ROLE, account);
    }

    function revokeMinter(address account) external onlyRole(MANAGER_ROLE){
        _revokeRole(MINTER_ROLE, account);
    }

    function grantManager(address account) external onlyRole(DEFAULT_ADMIN_ROLE){
        _grantRole(MANAGER_ROLE, account);
    }

    function revokeManager(address account) external onlyRole(DEFAULT_ADMIN_ROLE){
        _revokeRole(MANAGER_ROLE, account);
    }

    function transferAdmin(address account) external onlyRole(DEFAULT_ADMIN_ROLE){
        _revokeRole(DEFAULT_ADMIN_ROLE, _msgSender());
        _grantRole(DEFAULT_ADMIN_ROLE, account);
    }

}
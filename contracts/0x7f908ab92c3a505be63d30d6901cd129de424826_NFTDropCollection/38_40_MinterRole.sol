// SPDX-License-Identifier: UNLICENSED

pragma solidity >=0.6.0;

import "../../../contracts/mixins/roles/MinterRole.sol";

contract $MinterRole is MinterRole {
    bytes32 public __hh_exposed_bytecode_marker = "hardhat-exposed";

    constructor() {}

    function $_initializeMinterRole(address minter) external {
        return super._initializeMinterRole(minter);
    }

    function $_initializeAdminRole(address admin) external {
        return super._initializeAdminRole(admin);
    }

    function $__AccessControl_init() external {
        return super.__AccessControl_init();
    }

    function $__AccessControl_init_unchained() external {
        return super.__AccessControl_init_unchained();
    }

    function $_checkRole(bytes32 role) external view {
        return super._checkRole(role);
    }

    function $_checkRole(bytes32 role,address account) external view {
        return super._checkRole(role,account);
    }

    function $_setupRole(bytes32 role,address account) external {
        return super._setupRole(role,account);
    }

    function $_setRoleAdmin(bytes32 role,bytes32 adminRole) external {
        return super._setRoleAdmin(role,adminRole);
    }

    function $_grantRole(bytes32 role,address account) external {
        return super._grantRole(role,account);
    }

    function $_revokeRole(bytes32 role,address account) external {
        return super._revokeRole(role,account);
    }

    function $__ERC165_init() external {
        return super.__ERC165_init();
    }

    function $__ERC165_init_unchained() external {
        return super.__ERC165_init_unchained();
    }

    function $__Context_init() external {
        return super.__Context_init();
    }

    function $__Context_init_unchained() external {
        return super.__Context_init_unchained();
    }

    function $_msgSender() external view returns (address) {
        return super._msgSender();
    }

    function $_msgData() external view returns (bytes memory) {
        return super._msgData();
    }

    function $_disableInitializers() external {
        return super._disableInitializers();
    }

    receive() external payable {}
}
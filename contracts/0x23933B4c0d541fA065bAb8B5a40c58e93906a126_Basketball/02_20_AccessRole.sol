pragma solidity ^0.8.10;
// SPDX-License-Identifier: UNLICENSED

import "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";

contract AccessRole is AccessControlUpgradeable {
    
    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");

    modifier onlyAdmin() {
        require(isAdmin(_msgSender()), "Ownable: caller is not the admin");
        _;
    }

    modifier onlyMinter() {
        require(isMinter(_msgSender()), "Ownable: caller is not the minter");
        _;
    }

    function initialize() public initializer {
        AccessControlUpgradeable.__AccessControl_init();
        
        _setupRole(DEFAULT_ADMIN_ROLE, _msgSender());
    }

    function addMinter(address _account) public onlyAdmin {
        _setupRole(MINTER_ROLE, _account);
    }

    function removeMinter(address _account) public onlyAdmin {
        revokeRole(MINTER_ROLE, _account);
    }

    function addAdmin(address _account) public onlyAdmin {
        _setupRole(DEFAULT_ADMIN_ROLE , _account);
    }

    function removeAdmin(address _account) public onlyAdmin {
        revokeRole(DEFAULT_ADMIN_ROLE , _account);
    }

    function isMinter(address _account) internal virtual view returns(bool) {
        return hasRole(MINTER_ROLE, _account);
    }

    function isAdmin(address _account) internal virtual view returns(bool) {
        return hasRole(DEFAULT_ADMIN_ROLE , _account);
    }
}
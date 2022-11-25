// SPDX-License-Identifier: PRIVATE
pragma solidity ^0.8.4;

abstract contract SimpleRoles {
    mapping(address => bool) private _adminRights;
    mapping(address => bool) private _managersRights;
    address[] public _admins;
    address[] public _managers;

    function initialize() public {
        _adminRights[msg.sender] = true;
        _admins[_admins.length] = msg.sender;
    }

    modifier onlyAdmin() {
        require(isAdmin(msg.sender), "Roles: restricted to admins");
        _;
    }

    modifier onlyAdminOrManager() {
        require(
            isAdmin(msg.sender) || isManager(msg.sender),
            "Roles: restricted to admins or managers"
        );
        _;
    }

    function addAdmin(address account) external onlyAdmin {
        _adminRights[account] = true;
        _admins[_admins.length] = account;
    }

    function removeAdmin(address account) external onlyAdmin {
        require(
            account != msg.sender,
            "Roles: you can not delete the admin role from yourself"
        );
        _adminRights[account] = false; 
    }

    function addManager(address account) external onlyAdmin {
        _managersRights[account] = true;
        _managers[_admins.length] = account;
    }

    function removeManager(address account) external onlyAdmin {
        _managersRights[account] = false; 
    }

    function isAdmin(address account) public view returns (bool) {
        return _adminRights[account];
    }

    function isManager(address account) public view returns (bool) {
        return _managersRights[account];
    }
}
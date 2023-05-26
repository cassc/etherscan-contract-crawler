pragma solidity ^0.8.4;

import "@openzeppelin/contracts/access/AccessControl.sol";

/**
 * @dev Contract module which add functions for the default admin role defined by Access Control
 * By default, the account that deploys the contract will be assigned the Admin role.
 * Accounts can be added or removed with the functions defined below.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyAdmin`, which can be applied to your functions to restrict their use to admins.
 */
abstract contract AdminRole is AccessControl {

  /**
     * Modifier to make a function callable only by accounts with the admin role.
     */
    modifier onlyAdmin() {
        require(isAdmin(_msgSender()), "Not an Admin");
        _;
    }

    /**
     * Constructor.
     */
    constructor() {
      _setupRole(DEFAULT_ADMIN_ROLE, _msgSender());
    }

    /**
     * Validates whether or not the given account has been granted the admin role.
     * @param account The account to validate.
     * @return True if the account has been granted the admin role, false otherwise.
     */
    function isAdmin(address account) public view returns (bool) {
        return hasRole(DEFAULT_ADMIN_ROLE, account);
    }

    /**
     * Grants the admin role to a non-admin.
     * @param account The account to grant the admin role to.
     */
    function addAdmin(address account) public onlyAdmin {
        require(!isAdmin(account), "Already an Admin");
        grantRole(DEFAULT_ADMIN_ROLE, account);
    }

    /**
     * Removes the granted admin role.
     */
    function removeAdmin() public onlyAdmin {
        renounceRole(DEFAULT_ADMIN_ROLE, _msgSender());
    }
}
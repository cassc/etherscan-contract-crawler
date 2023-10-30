// SPDX-License-Identifier: MIT
pragma solidity 0.6.12;

/**
 * @title   Permission
 * @author  Liquis Finance
 * @notice  A simple permissions system giving a `caller` the ability to act on behalf of `owner`
 * @dev     Other than ERC20 Allowances, Permissions are boolean giving `caller` the ability
 *          to call a specific contract function without further controls. 
 *          Permission are thought to allow users to give peripheral contracts permission to act
 *          on their behalf in order to improve UX e.g. around claiming rewards.
 */
abstract contract Permission {

    event ModifyPermission(address owner, address caller, bool grant);

    /// @dev Specify whether `caller` can act on behalf of `owner`
    mapping(address => mapping(address => bool)) private _permitted;

    /**
     * @notice Allow (or revoke allowance) `caller` to act on behalf of `msg.sender`
     * @param caller Address of the `caller`
     * @param permitted Allow (true) or revoke (false) permission
     */
    function modifyPermission(address caller, bool permitted) external {
        _permitted[msg.sender][caller] = permitted;
        emit ModifyPermission(msg.sender, caller, permitted);
    }

    /** 
     * @notice Checks permission of `caller` to act on behalf of `owner`
     * @param owner Address of the `owner`
     * @param caller Address of the `caller`
     * @return permission Whether `caller` has the permission
     */
    function hasPermission(address owner, address caller) public view returns (bool) {
        return owner == caller || _permitted[owner][caller];
    }
}
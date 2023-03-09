//SPDX-License-Identifier: Unlicensed

pragma solidity ^0.8.9;

import {PermissionAdmin} from "./PermissionAdmin.sol";

/**
 * @title Blacklistable Token
 * @dev Allows accounts to be blacklisted by a "blacklister" role
 */
contract Blacklistable is PermissionAdmin {

    address internal _blacklister;
    mapping(address => bool) public blacklisted;

    event Blacklisted(address indexed _account);
    event UnBlacklisted(address indexed _account);
    event BlacklisterChanged(address indexed newBlacklister);

    /**
     * @dev Throws if called by any account other than the blacklister
     */
    modifier onlyBlacklister() {
        require(msg.sender == _blacklister, "caller not blacklister");
        _;
    }

    /**
     * @dev Throws if argument account is blacklisted
     * @param _account The address to check
     */
    modifier notBlacklisted(address _account) {
        require(_blacklister != address(0), "No zero addr");
        require(!blacklisted[_account], "account blacklisted");
        _;
    }

    /**
     * @notice Returns current rescuer
     * @return Blacklister's address
     */
    function getBlacklister() external view returns (address) {
        return _blacklister;
    }

    /**
     * @dev Checks if account is blacklisted
     * @param _account The address to check
     */
    function isBlacklisted(address _account) external view returns (bool) {
        return blacklisted[_account];
    }

    /**
     * @dev Adds account to blacklist
     * @param _account The address to blacklist
     */
    function blacklist(address _account) external onlyBlacklister {
        require(!blacklisted[_account], "already blacklisted");
        require(_account != _blacklister, "blacklister cannot blacklist itself");
        require(_account != address(0), "No zero addr");
        blacklisted[_account] = true;
        emit Blacklisted(_account);
    }

    /**
     * @dev Removes account from blacklist
     * @param _account The address to remove from the blacklist
     */
    function unBlacklist(address _account) external onlyBlacklister {
        blacklisted[_account] = false;
        emit UnBlacklisted(_account);
    }

    function updateBlacklister(address _newBlacklister)
        external
        onlyPermissionAdmin
    {
        //require(initialized, "TokenV1 not initialized");
        require(_newBlacklister != address(0), "No zero addr");
        _blacklister = _newBlacklister;
        emit BlacklisterChanged(_blacklister);
    }
}
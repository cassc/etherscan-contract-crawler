// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import {Errors} from "./libraries/Errors.sol";
import {IAccessControl} from "lib/openzeppelin-contracts/contracts/access/IAccessControl.sol";
import {IBlacklist} from "./interfaces/IBlacklist.sol";
import {Roles} from "./libraries/Roles.sol";

contract Blacklist is IBlacklist {
    IAccessControl public immutable override accessController;

    mapping(address => bool) private _blacklisted;

    /**
     * @dev Throws if called by any account other than the blacklister
     */
    modifier onlyBlacklister() {
        if (!accessController.hasRole(Roles.MCAG_BLACKLIST_ROLE, msg.sender)) {
            revert Errors.BLACKLIST_CALLER_IS_NOT_BLACKLISTER();
        }
        _;
    }

    constructor(IAccessControl _accessController) {
        if (address(_accessController) == address(0)) {
            revert Errors.CANNOT_SET_TO_ADDRESS_ZERO();
        }
        accessController = _accessController;
    }

    /**
     * @dev Adds account to blacklist
     * @param account The address to blacklist
     */
    function blacklist(address account) external override onlyBlacklister {
        _blacklisted[account] = true;
        emit Blacklisted(account);
    }

    /**
     * @dev Removes account from blacklist
     * @param account The address to remove from the blacklist
     */
    function unBlacklist(address account) external override onlyBlacklister {
        _blacklisted[account] = false;
        emit UnBlacklisted(account);
    }

    /**
     * @dev Checks if account is blacklisted
     * @param account The address to check
     */
    function isBlacklisted(address account) external view override returns (bool) {
        return _blacklisted[account];
    }
}
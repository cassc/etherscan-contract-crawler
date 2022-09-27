/**
 * @title Pauser Role
 * @dev PauserRole contract
 *
 * @author - <USDFI TRUST>
 * for the USDFI Trust
 *
 * SPDX-License-Identifier: GNU GPLv2
 *
 **/

pragma solidity 0.6.12;

import "./Roles.sol";
import "./Ownable.sol";

contract PauserRole is Ownable {
    using Roles for Roles.Role;

    event PauserAdded(address indexed account);
    event PauserRemoved(address indexed account);

    Roles.Role private _pausers;

    constructor() internal {
        _addPauser(msg.sender);
    }

    modifier onlyPauser() {
        require(
            isPauser(msg.sender),
            "PauserRole: caller does not have the Pauser role"
        );
        _;
    }

    /**
     * @dev Returns account address is Pauser true or false.
     *
     * Requirements:
     *
     * - address `account` cannot be the zero address.
     */
    function isPauser(address account) public view returns (bool) {
        return _pausers.has(account);
    }

    /**
     * @dev Adds address to the Pauser role.
     *
     * Requirements:
     *
     * - address `account` cannot be the zero address.
     */
    function addPauser(address account) public onlyOwner {
        _addPauser(account);
    }

    /**
     * @dev Removes address from the Pauser role.
     *
     * Requirements:
     *
     * - address `account` cannot be the zero address.
     */
    function renouncePauser(address account) public onlyOwner {
        _removePauser(account);
    }

    /**
     * @dev Adds address to the Pauser role (internally).
     *
     * Requirements:
     *
     * - address `account` cannot be the zero address.
     */
    function _addPauser(address account) internal {
        _pausers.add(account);
        emit PauserAdded(account);
    }

    /**
     * @dev Removes address from the Pauser role (internally).
     *
     * Requirements:
     *
     * - address `account` cannot be the zero address.
     */
    function _removePauser(address account) internal {
        _pausers.remove(account);
        emit PauserRemoved(account);
    }
}

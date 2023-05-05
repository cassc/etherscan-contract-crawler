// SPDX-License-Identifier: MIT

pragma solidity >=0.8.0 <0.9.0;

import "@openzeppelin/contracts/utils/Context.sol";

/**
 * @dev Contract module which allows children to implement an emergency stop
 * mechanism that can be triggered by an authorized account.
 *
 * This module is used through inheritance. It will make available the
 * modifiers `whenNotRestricted` and `whenRestricted`, which can be applied to
 * the functions of your contract. Note that they will not be pausable by
 * simply including this module, only once the modifiers are put in place.
 */
abstract contract Restrictable is Context {
    /**
     * @dev Emitted when the pause is triggered by `account`.
     */
    event Restricted(address account);

    /**
     * @dev Emitted when the pause is lifted by `account`.
     */
    event Unrestricted(address account);

    bool private _restricted;

    /**
     * @dev Initializes the contract in unrestricted state.
     */
    constructor() {
        _restricted = false;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is not restricted.
     *
     * Requirements:
     *
     * - The contract must not be restricted.
     */
    modifier whenNotRestricted() {
        _requireNotRestricted();
        _;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is restricted.
     *
     * Requirements:
     *
     * - The contract must be restricted.
     */
    modifier whenRestricted() {
        _requireRestricted();
        _;
    }

    /**
     * @dev Returns true if the contract is restricted, and false otherwise.
     */
    function restricted() public view virtual returns (bool) {
        return _restricted;
    }

    /**
     * @dev Throws if the contract is restricted.
     */
    function _requireNotRestricted() internal view virtual {
        require(!restricted(), "Pausable: restricted");
    }

    /**
     * @dev Throws if the contract is not restricted.
     */
    function _requireRestricted() internal view virtual {
        require(restricted(), "Pausable: not restricted");
    }

    /**
     * @dev Triggers stopped state.
     *
     * Requirements:
     *
     * - The contract must not be restricted.
     */
    function _restrict() internal virtual whenNotRestricted {
        _restricted = true;
        emit Restricted(_msgSender());
    }

    /**
     * @dev Returns to normal state.
     *
     * Requirements:
     *
     * - The contract must be restricted.
     */
    function _unrestrict() internal virtual whenRestricted {
        _restricted = false;
        emit Unrestricted(_msgSender());
    }
}
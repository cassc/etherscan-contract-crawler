// SPDX-License-Identifier: MIT

pragma solidity >=0.8.0 <0.9.0;

import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";

/**
 * @dev Contract module which is essentially like Pausable but only owner is allowed to change the state.
 */
abstract contract PausableByOwnerUpgradeable is PausableUpgradeable, OwnableUpgradeable {

    function __PausableByOwner_init() internal onlyInitializing {
        __Pausable_init();
        __Ownable_init();
    }

    /**
     * @dev Triggers stopped state.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    function pause() external virtual onlyOwner {
        _pause();
    }

    /**
     * @dev Returns to normal state.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    function unpause() external virtual onlyOwner {
        _unpause();
    }
}
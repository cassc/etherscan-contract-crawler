// SPDX-License-Identifier: MIT

pragma solidity 0.8.16;

import { OwnableUpgradeable } from "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import { PausableUpgradeable } from "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";

/**
 * @title PausableExtUpgradeable base contract
 * @dev Extends the {PausableUpgradeable} contract by adding the `pauser` role.
 *
 * This contract is used through inheritance. It introduces the `pauser` role that is allowed
 * to trigger paused/unpaused state of the contract that is inherited from this one.
 *
 * By default, the pauser is to the zero address. This can later be changed
 * by the contract owner with the {setPauser} function.
 */
abstract contract PausableExtUpgradeable is OwnableUpgradeable, PausableUpgradeable {
    /// @dev The address of the pauser.
    address private _pauser;

    // -------------------- Events -----------------------------------

    /// @dev Emitted when the pauser is changed.
    event PauserChanged(address indexed pauser);

    // -------------------- Errors -----------------------------------

    /// @dev The transaction sender is not a pauser.
    error UnauthorizedPauser(address account);

    // -------------------- Functions --------------------------------

    function __PausableExt_init() internal onlyInitializing {
        __Context_init_unchained();
        __Ownable_init_unchained();
        __Pausable_init_unchained();

        __PausableExt_init_unchained();
    }

    function __PausableExt_init_unchained() internal onlyInitializing {}

    /**
     * @dev Throws if called by any account other than the pauser.
     */
    modifier onlyPauser() {
        if (_msgSender() != _pauser) {
            revert UnauthorizedPauser(_msgSender());
        }
        _;
    }

    /**
     * @dev Returns the pauser address.
     */
    function pauser() public view virtual returns (address) {
        return _pauser;
    }

    /**
     * @dev Updates the pauser address.
     *
     * Requirements:
     *
     * - Can only be called by the contract owner.
     *
     * Emits a {PauserChanged} event.
     *
     * @param newPauser The address of a new pauser.
     */
    function setPauser(address newPauser) external onlyOwner {
        if (_pauser == newPauser) {
            return;
        }

        _pauser = newPauser;

        emit PauserChanged(_pauser);
    }

    /**
     * @dev See {PausableUpgradeable-pause}.
     *
     * Requirements:
     *
     * - Can only be called by the contract pauser.
     */
    function pause() external onlyPauser {
        _pause();
    }

    /**
     * @dev See {PausableUpgradeable-unpause}.
     *
     * Requirements:
     *
     * - Can only be called by the contract pauser.
     */
    function unpause() external onlyPauser {
        _unpause();
    }
}
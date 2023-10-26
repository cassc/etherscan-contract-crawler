// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

/** @dev This is based on OpenZeppelin's Pausable.
 * Unfortunately it's only last updated v4.7.0 (security/Pausable.sol).
 * So we have to manually update the contract ourselves.
 */

// import {Ownable} from "../lib/openzeppelin-contracts/contracts/access/Ownable.sol";
import {UnrenounceableOwnable2Step} from "./UnrenounceableOwnable2Step.sol";

/**
 * @dev A contract module enabling an authorized account to pause and unpause functionality.
 *
 * This module provides the `whenNotPaused` and `whenPaused` modifiers for functions.
 * The whenNotPaused modifier is used for normal functions of an ERC20 token - transfer(), transferFrom() but also other
 * functions such as issue() and redeem().
 * The function of introducing these modifiers in the contract, is to pause all activity in the situation where something has gone wrong.
 */
// contract Pausable is Ownable {
contract Pausable is UnrenounceableOwnable2Step {
    address public pauser;
    /**
     * @dev Emitted when the pause is triggered by `account`.
     */
    event Paused(address account);

    /**
     * @dev Emitted when the pause is lifted by `account`.
     */
    event Unpaused(address account);

    /**
     * @dev Emitted when the pauser address is updated.
     * @param newAddress The new address assigned as the pauser.
     */
    event PauserChanged(address indexed newAddress);

    bool private _paused;

    /**
     * @dev Initializes the contract in unpaused state.
     */
    constructor() {
        _paused = false;
        pauser = msg.sender;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is not paused.
     * Requirements:
     * - The contract must not be paused.
     */
    modifier whenNotPaused() {
        _requireNotPaused();
        _;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is paused.
     * Requirements:
     * - The contract must be paused.
     */
    modifier whenPaused() {
        _requirePaused();
        _;
    }

    /**
     * @dev Returns true if the contract is paused, and false otherwise.
     */
    function paused() public view virtual returns (bool) {
        return _paused;
    }

    /**
     * @dev Throws if the contract is paused.
     */
    function _requireNotPaused() internal view virtual {
        require(!paused(), "Pausable: paused");
    }

    /**
     * @dev Throws if the contract is not paused.
     */
    function _requirePaused() internal view virtual {
        require(paused(), "Pausable: not paused");
    }

    /**
     * @dev Triggers stopped state.
     * Requirements:
     * - The contract must not be paused.
     */
    function _pause() internal virtual whenNotPaused {
        _paused = true;
        emit Paused(_msgSender());
    }

    /**
     * @dev Returns to normal state.
     * Requirements:
     * - The contract must be paused.
     */
    function _unpause() internal virtual whenPaused {
        _paused = false;
        emit Unpaused(_msgSender());
    }

    /**
     * @dev throws if called by any account other than the pauser
     */
    modifier onlyPauser() {
        require(msg.sender == pauser, "Pausable: caller is not the pauser");
        _;
    }

    // Pausing

    function pause() public onlyPauser returns (bool) {
        _pause();
        return (paused());
    }

    function unpause() public onlyPauser returns (bool) {
        _unpause();
        return (paused());
    }

    /**
     * @dev update the pauser role - only the owner can call this function
     * Requirements:
     * - The newPauser must not be the zero address.
     */
    function updatePauser(address _newPauser) external onlyOwner {
        require(
            _newPauser != address(0),
            "Pausable: new pauser is the zero address"
        );
        pauser = _newPauser;
        emit PauserChanged(pauser);
    }
}
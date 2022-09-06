// SPDX-License-Identifier: MIT
// ERC721A Contracts v4.1.0

pragma solidity ^0.8.0;

import '../ERC721AUpgradeable.sol';
import '../ERC721A__Initializable.sol';

abstract contract ERC721APausableUpgradeable is     
    ERC721A__Initializable,
    ERC721AUpgradeable
{
    function __ERC721APausable_init() internal onlyInitializingERC721A {
        __PausableA_init_unchained();
    }

    function __ERC721APausable_init_unchained() internal onlyInitializingERC721A {
    }

    /**
     * @dev Emitted when the pause is triggered by `account`.
     */
    event Paused(address account);

    /**
     * @dev Emitted when the pause is lifted by `account`.
     */
    event Unpaused(address account);

    bool private _paused;

    /**
     * @dev Initializes the contract in unpaused state.
     */
    function __PausableA_init() internal onlyInitializingERC721A {
        __PausableA_init_unchained();
    }

    function __PausableA_init_unchained() internal onlyInitializingERC721A {
        _paused = false;
    }

    /**
     * @dev Returns true if the contract is paused, and false otherwise.
     */
    function paused() public view virtual returns (bool) {
        return _paused;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is not paused.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    modifier whenNotPaused() {
        require(!paused(), "Pausable: paused");
        _;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is paused.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    modifier whenPaused() {
        require(paused(), "Pausable: not paused");
        _;
    }

    /**
     * @dev Triggers stopped state.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    function _pause() internal virtual whenNotPaused {
        _paused = true;
        emit Paused(_msgSenderERC721A());
    }

    /**
     * @dev Returns to normal state.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    function _unpause() internal virtual whenPaused {
        _paused = false;
        emit Unpaused(_msgSenderERC721A());
    }

    uint256[50] private __gap;
}
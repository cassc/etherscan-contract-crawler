//SPDX-License-Identifier: MIT
pragma solidity 0.7.5;

// Inheritance
import "./Owned.sol";


abstract contract Pausable is Owned {
    bool public paused;

    event PauseChanged(bool isPaused);

    modifier notPaused {
        require(!paused, "This action cannot be performed while the contract is paused");
        _;
    }

    constructor() {
        // This contract is abstract, and thus cannot be instantiated directly
        require(owner() != address(0), "Owner must be set");
        // Paused will be false
    }

    /**
     * @notice Change the paused state of the contract
     * @dev Only the contract owner may call this.
     */
    function setPaused(bool _paused) external onlyOwner {
        // Ensure we're actually changing the state before we do anything
        if (_paused == paused) {
            return;
        }

        // Set our paused state.
        paused = _paused;

        // Let everyone know that our pause state has changed.
        emit PauseChanged(paused);
    }
}
// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (security/Pausable.sol)

pragma solidity ^0.8.0;

error ContractPaused();
error ContractUnpaused();

library PausableLib {
    bytes32 constant PAUSABLE_STORAGE_POSITION =
        keccak256("pausable.facet.storage");
    /**
     * @dev Emitted when the pause is triggered by `account`.
     */
    event Paused(address account);

    /**
     * @dev Emitted when the pause is lifted by `account`.
     */
    event Unpaused(address account);

    struct PausableStorage {
        bool _paused;
    }

    function pausableStorage()
        internal
        pure
        returns (PausableStorage storage s)
    {
        bytes32 position = PAUSABLE_STORAGE_POSITION;
        assembly {
            s.slot := position
        }
    }

    /**
     * @dev Returns true if the contract is paused, and false otherwise.
     */
    function _paused() internal view returns (bool) {
        return pausableStorage()._paused;
    }

    /**
     * @dev Triggers stopped state.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    function _pause() internal {
        PausableStorage storage s = pausableStorage();
        if (s._paused) revert ContractPaused();
        s._paused = true;
        emit Paused(msg.sender);
    }

    /**
     * @dev Returns to normal state.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    function _unpause() internal {
        PausableStorage storage s = pausableStorage();
        if (!s._paused) revert ContractUnpaused();
        s._paused = false;
        emit Unpaused(msg.sender);
    }

    function enforceUnpaused() internal view {
        if (pausableStorage()._paused) revert ContractPaused();
    }

    function enforcePaused() internal view {
        if (!pausableStorage()._paused) revert ContractUnpaused();
    }
}
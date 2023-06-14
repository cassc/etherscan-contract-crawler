// SPDX-License-Identifier: BUSL-1.1

pragma solidity ^0.8.13;

abstract contract Pausable {
    /// Storage ///

    bytes32 private constant NAMESPACE = keccak256("pausable.storage");

    /// Types ///

    struct PausableStorage {
        bool paused;
    }

    /// Modifiers ///

    modifier whenNotPaused() {
        require(!paused(), "Pausable: paused");
        _;
    }

    modifier whenPaused() {
        require(paused(), "Pausable: not paused");
        _;
    }

    /// Public Methods ///

    /// @dev fetch local storage
    function pausableStorage()
        internal
        pure
        returns (PausableStorage storage data)
    {
        bytes32 position = NAMESPACE;
        // solhint-disable-next-line no-inline-assembly
        assembly {
            data.slot := position
        }
    }

    /// @dev returns true if the contract is paused, and false otherwise
    function paused() public view returns (bool) {
        return pausableStorage().paused;
    }

    /// @dev called by the owner to pause, triggers stopped state
    function _pause() internal {
        pausableStorage().paused = true;
    }

    /// @dev called by the owner to unpause, returns to normal state
    function _unpause() internal {
        pausableStorage().paused = false;
    }
}
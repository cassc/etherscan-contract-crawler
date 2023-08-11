// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.4;

abstract contract LAInitializable {
    error AlreadyInitialized();

    struct InitializableState {
        bool _initialized;
    }

    function _getInitializableState()
        internal
        pure
        returns (InitializableState storage state)
    {
        bytes32 position = keccak256("liveart.Initializable");
        assembly {
            state.slot := position
        }
    }

    function _notInitialized() private {
        InitializableState storage state = _getInitializableState();
        if (state._initialized) {
            revert AlreadyInitialized();
        }
        state._initialized = true;
    }

    modifier notInitialized() {
        _notInitialized();
        _;
    }
}
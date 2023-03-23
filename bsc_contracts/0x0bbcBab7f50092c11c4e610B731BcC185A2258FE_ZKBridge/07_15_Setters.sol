// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./State.sol";

contract Setters is State {

    function _setInitialized(address implementation) internal {
        _state.initializedImplementations[implementation] = true;
    }

    function _setChainId(uint16 chainId) internal {
        _state.provider.chainId = chainId;
    }

    function _setTransferCompleted(bytes32 hash) internal {
        _state.completedTransfers[hash] = true;
    }

    function _setZKBridgeImplementation(uint16 chainId, bytes32 bridgeContract) internal {
        _state.zkBridgeImplementations[chainId] = bridgeContract;
    }

    function _setOwner(address owner) internal {
        _state.owner = owner;
    }

    function _setNextSequence(bytes32 hash, uint64 sequence) internal {
        _state.sequences[hash] = sequence;
    }

    function _setMptVerifier(uint16 chainId,address mptVerifier) internal {
        _state.mptVerifiers[chainId] = mptVerifier;
    }

    function _setBlockUpdater(uint16 chainId,address blockUpdater) internal {
        _state.blockUpdaters[chainId] = blockUpdater;
    }

    function _setPendingImplementation(address pendingImplementation) internal {
        _state.pendingImplementation = pendingImplementation;
    }

    function _setToUpdateTime(uint256 toUpdateTime) internal {
        _state.toUpdateTime = toUpdateTime;
    }

    function _setLockTime(uint256 lockTime) internal {
        _state.lockTime = lockTime;
    }
}
// contracts/Setters.sol
// SPDX-License-Identifier: Apache 2

pragma solidity ^0.8.0;

import "./NFTBridgeState.sol";

contract NFTBridgeSetters is NFTBridgeState {
    function _setInitialized(address implementation) internal {
        _state.initializedImplementations[implementation] = true;
    }

    function _setChainId(uint16 chainId) internal {
        _state.provider.chainId = chainId;
    }

    function _setBridgeImplementation(uint16 chainId, address bridgeContract) internal {
        _state.bridgeImplementations[chainId] = bridgeContract;
    }

    function _setTokenImplementation(address impl) internal {
        _state.tokenImplementation = impl;
    }

    function _setZKBridge(address h) internal {
        _state.zkBridge = payable(h);
    }

    function _setWrappedAsset(uint16 tokenChainId, bytes32 tokenAddress, address wrapper) internal {
        _state.wrappedAssets[tokenChainId][tokenAddress] = wrapper;
        _state.isWrappedAsset[wrapper] = true;
    }

    function _setOwner(address owner) internal {
        _state.owner = owner;
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
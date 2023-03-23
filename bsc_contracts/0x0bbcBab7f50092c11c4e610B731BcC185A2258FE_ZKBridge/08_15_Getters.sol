// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./State.sol";
import "./interfaces/IMptVerifier.sol";
import "./interfaces/IBlockUpdater.sol";

contract Getters is State {

    function isInitialized(address impl) public view returns (bool) {
        return _state.initializedImplementations[impl];
    }

    function chainId() public view returns (uint16) {
        return _state.provider.chainId;
    }

    function nextSequence(bytes32 hash) public view returns (uint64) {
        return _state.sequences[hash];
    }

    function zkBridgeContracts(uint16 chainId) public view returns (bytes32){
        return _state.zkBridgeImplementations[chainId];
    }

    function isTransferCompleted(bytes32 hash) public view returns (bool) {
        return _state.completedTransfers[hash];
    }

    function mptVerifier(uint16 chainId) public view returns (IMptVerifier) {
        return IMptVerifier(_state.mptVerifiers[chainId]);
    }

    function blockUpdater(uint16 chainId) public view returns (IBlockUpdater) {
        return IBlockUpdater(_state.blockUpdaters[chainId]);
    }

    function owner() public view returns (address) {
        return _state.owner;
    }

    function pendingImplementation() public view returns (address) {
        return _state.pendingImplementation;
    }

    function toUpdateTime() public view returns (uint256) {
        return _state.toUpdateTime;
    }

    function lockTime() public view returns (uint256) {
        return _state.lockTime;
    }

}
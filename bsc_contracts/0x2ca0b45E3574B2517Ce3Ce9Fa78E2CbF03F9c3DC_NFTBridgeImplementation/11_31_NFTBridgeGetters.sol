// contracts/Getters.sol
// SPDX-License-Identifier: Apache 2

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

import "../interfaces/IZKBridge.sol";

import "./NFTBridgeState.sol";

contract NFTBridgeGetters is NFTBridgeState {
    function isInitialized(address impl) public view returns (bool) {
        return _state.initializedImplementations[impl];
    }

    function zkBridge() public view returns (IZKBridge) {
        return IZKBridge(_state.zkBridge);
    }

    function chainId() public view returns (uint16){
        return _state.provider.chainId;
    }

    function wrappedAsset(uint16 tokenChainId, bytes32 tokenAddress) public view returns (address){
        return _state.wrappedAssets[tokenChainId][tokenAddress];
    }

    function bridgeContracts(uint16 chainId_) public view returns (address){
        return _state.bridgeImplementations[chainId_];
    }

    function tokenImplementation() public view returns (address){
        return _state.tokenImplementation;
    }

    function isWrappedAsset(address token) public view returns (bool){
        return _state.isWrappedAsset[token];
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
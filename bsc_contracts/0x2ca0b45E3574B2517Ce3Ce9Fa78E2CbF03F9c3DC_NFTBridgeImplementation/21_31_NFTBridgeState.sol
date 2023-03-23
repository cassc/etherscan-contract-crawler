// contracts/State.sol
// SPDX-License-Identifier: Apache 2

pragma solidity ^0.8.0;

import "./NFTBridgeStructs.sol";

contract NFTBridgeStorage {
    struct Provider {
        uint16 chainId;
    }

    struct State {
        address payable zkBridge;

        address tokenImplementation;

        address owner;

        address pendingImplementation;

        uint256 toUpdateTime;

        uint256 lockTime;

        // Mapping of initialized implementations
        mapping(address => bool) initializedImplementations;

        // Mapping of wrapped assets (chainID => nativeAddress => wrappedAddress)
        mapping(uint16 => mapping(bytes32 => address)) wrappedAssets;

        // Mapping to safely identify wrapped assets
        mapping(address => bool) isWrappedAsset;

        // Mapping of bridge contracts on other chains
        mapping(uint16 => address) bridgeImplementations;

        Provider provider;
    }
}

contract NFTBridgeState {
    NFTBridgeStorage.State _state;
    uint256 public constant MIN_LOCK_TIME = 1 days;
}
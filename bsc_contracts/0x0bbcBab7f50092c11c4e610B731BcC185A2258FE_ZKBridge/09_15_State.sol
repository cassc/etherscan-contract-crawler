// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;


contract Storage {

    struct Provider {
        uint16 chainId;
    }

    struct ZKBridgeState {
        Provider provider;

        address owner;

        address pendingImplementation;

        uint256 toUpdateTime;

        uint256 lockTime;

        // Sequence numbers per emitter
        mapping(bytes32 => uint64) sequences;

        // Mapping of zkBridge contracts on other chains
        mapping(uint16 => bytes32) zkBridgeImplementations;

        // Mapping of initialized implementations
        mapping(address => bool) initializedImplementations;

        // Mapping of consumed token transfers
        mapping(bytes32 => bool) completedTransfers;

        mapping(uint16 => address) mptVerifiers;

        mapping(uint16 => address) blockUpdaters;
    }
}

contract State {
    Storage.ZKBridgeState _state;
    uint256 public constant MIN_LOCK_TIME = 1 days;
}
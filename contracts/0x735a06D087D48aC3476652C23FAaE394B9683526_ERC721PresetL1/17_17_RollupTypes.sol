// SPDX-License-Identifier: LGPL-3.0-only
pragma solidity ^0.8.0;

struct StateContext {
    bool _writable;
    bytes32 _hash; // writable
    uint256 _startBlock; // writable
    // readable
    uint8 _epoch;
}

struct KeyValuePair {
    bytes key;
    bytes value;
}

struct RollupInfo {
    uint8 originDomainID;
    uint64 nonce;
    bytes32 stateChangeHash;
    bytes32 rootHash;
    uint64 totalBatches;
    address destAddress;
}
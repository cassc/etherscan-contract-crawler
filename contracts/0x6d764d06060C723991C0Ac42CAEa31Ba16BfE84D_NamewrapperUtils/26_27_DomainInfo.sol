// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

struct DomainInfo {
    bytes32 node;
    address owner;
    uint32 fuses;
    uint64 expiry;
}
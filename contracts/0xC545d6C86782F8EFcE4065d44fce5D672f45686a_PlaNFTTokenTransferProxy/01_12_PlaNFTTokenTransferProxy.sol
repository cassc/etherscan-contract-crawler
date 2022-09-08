// SPDX-License-Identifier: MIT

pragma solidity ^0.8.13;

import "./TokenTransferProxy.sol";

contract PlaNFTTokenTransferProxy is TokenTransferProxy {
    constructor(ProxyRegistry registryAddr) {
        registry = registryAddr;
    }
}
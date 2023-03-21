// SPDX-License-Identifier: MIT
pragma solidity 0.8.18;

interface RootChainManager {
    function depositFor(address user, address rootToken, bytes calldata depositData) external;
}
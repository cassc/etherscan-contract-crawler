// SPDX-License-Identifier: UNLICENSED
pragma solidity >0.8.0;

interface IRootChainManager {
    function depositFor(address user, address rootToken, bytes calldata depositData) external;

    function exit(bytes calldata inputData) external;

    function tokenToType(address token) external returns (bytes32);

    function typeToPredicate(bytes32 tokenType) external returns (address);
}
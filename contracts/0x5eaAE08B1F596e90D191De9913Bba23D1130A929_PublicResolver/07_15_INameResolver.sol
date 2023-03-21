// SPDX-License-Identifier: MIT

pragma solidity 0.8.9;

interface INameResolver {
    event NameChanged(bytes32 indexed node, string name);

    function name(bytes32 node) external view returns (string memory);
}
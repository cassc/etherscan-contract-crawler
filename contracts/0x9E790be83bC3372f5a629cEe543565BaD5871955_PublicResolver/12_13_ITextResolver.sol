// SPDX-License-Identifier: MIT

pragma solidity 0.8.9;

interface ITextResolver {
    event TextChanged(
        bytes32 indexed node,
        string indexed indexedKey,
        string key
    );

    function text(bytes32 node, string calldata key)
        external
        view
        returns (string memory);
}
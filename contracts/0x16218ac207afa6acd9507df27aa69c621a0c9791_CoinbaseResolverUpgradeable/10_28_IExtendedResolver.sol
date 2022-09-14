// SPDX-License-Identifier: MIT

pragma solidity ^0.8.13;

interface IExtendedResolver {
    /**
     * @notice Function interface for the ENSIP-10 wildcard resolution function.
     * @param name DNS-encoded name to resolve.
     * @param data ABI-encoded data for the underlying resolution function (e.g. addr(bytes32), text(bytes32,string)).
     */
    function resolve(bytes memory name, bytes memory data)
        external
        view
        returns (bytes memory);
}
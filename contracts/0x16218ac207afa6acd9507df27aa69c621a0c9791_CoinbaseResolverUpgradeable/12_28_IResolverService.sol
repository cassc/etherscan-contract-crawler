// SPDX-License-Identifier: MIT

pragma solidity ^0.8.13;

interface IResolverService {
    /**
     * @notice Function interface for the lookup function supported by the off-chain gateway.
     * @dev This function is executed off-chain by the off-chain gateway.
     * @param name DNS-encoded name to resolve.
     * @param data ABI-encoded data for the underlying resolution function (e.g. addr(bytes32), text(bytes32,string)).
     * @return result ABI-encode result of the lookup.
     * @return expires Time at which the signature expires.
     * @return sig A signer's signature authenticating the result.
     */
    function resolve(bytes calldata name, bytes calldata data)
        external
        view
        returns (
            bytes memory result,
            uint64 expires,
            bytes memory sig
        );
}
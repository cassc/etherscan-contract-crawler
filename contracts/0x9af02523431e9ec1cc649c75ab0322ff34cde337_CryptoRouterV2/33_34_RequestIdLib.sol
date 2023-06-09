// SPDX-License-Identifier: UNLICENSED
// Copyright (c) Eywa.Fi, 2021-2023 - all rights reserved
pragma solidity 0.8.17;

library RequestIdLib {

    /**
     * @dev Prepares a request ID with the given arguments.
     *
     * @param to receiver;
     * @param chainIdTo opposite chain id;
     * @param from sender;
     * @param chainIdFrom current chain id;
     * @param nonce current nonce.
     */
    function prepareRequestId(
        bytes32 to,
        uint256 chainIdTo,
        bytes32 from,
        uint256 chainIdFrom,
        uint256 nonce
    ) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked(from, nonce, chainIdTo, chainIdFrom, to));
    }
}
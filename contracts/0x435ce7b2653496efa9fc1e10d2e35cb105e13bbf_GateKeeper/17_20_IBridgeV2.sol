// SPDX-License-Identifier: UNLICENSED
// Copyright (c) Eywa.Fi, 2021-2023 - all rights reserved
pragma solidity ^0.8.17;

interface IBridgeV2 {

    enum State { 
        Active, // data send and receive possible
        Inactive, // data send and receive impossible
        Limited // only data receive possible
    }

    struct SendParams {
        /// @param requestId unique request ID
        bytes32 requestId;
        /// @param data call data
        bytes data;
        /// @param to receiver contract address
        address to;
        /// @param chainIdTo destination chain ID
        uint256 chainIdTo;
    }

    struct ReceiveParams {
        /// @param blockHeader block header serialization
        bytes blockHeader;
        /// @param merkleProof OracleRequest transaction payload and its Merkle audit path
        bytes merkleProof;
        /// @param votersPubKey aggregated public key of the old epoch participants, who voted for the block
        bytes votersPubKey;
        /// @param votersSignature aggregated signature of the old epoch participants, who voted for the block
        bytes votersSignature;
        /// @param votersMask bitmask of epoch participants, who voted, among all participants
        uint256 votersMask;
    }

    function sendV2(
        SendParams calldata params,
        address sender,
        uint256 nonce
    ) external returns (bool);

    function receiveV2(ReceiveParams[] calldata params) external returns (bool);

    function nonces(address from) external view returns (uint256);
}
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.12;

interface IEventLogger {
    function emitReplicaDeployed(address replica_) external;

    function emitReplicaTransferred(
        uint256 canonicalTokenId_,
        uint256 replicaTokenId_
    ) external;

    function emitReplicaRegistered(
        address canonicalNftContract_,
        uint256 canonicalTokenId_,
        address replica_
    ) external;
}
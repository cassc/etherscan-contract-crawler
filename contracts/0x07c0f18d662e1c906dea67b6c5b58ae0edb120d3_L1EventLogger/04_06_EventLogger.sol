// SPDX-License-Identifier: MIT
pragma solidity ^0.8.12;

import "./interface/IEventLogger.sol";
import "./interface/IEventLoggerEvents.sol";

abstract contract EventLogger is IEventLogger, IEventLoggerEvents {
    function emitReplicaDeployed(address replica_) external {
        emit ReplicaDeployed(msg.sender, replica_);
    }

    function emitReplicaRegistered(
        address canonicalNftContract_,
        uint256 canonicalTokenId_,
        address replica_
    ) external {
        emit ReplicaRegistered(
            msg.sender,
            canonicalNftContract_,
            canonicalTokenId_,
            replica_
        );
    }

    function emitReplicaUnregistered(address replica_) external {
        emit ReplicaUnregistered(msg.sender, replica_);
    }

    function emitReplicaTransferred(
        uint256 canonicalTokenId_,
        uint256 replicaTokenId_
    ) external {
        emit ReplicaTransferred(msg.sender, canonicalTokenId_, replicaTokenId_);
    }

    function emitReplicaBridgingInitiated(
        address canonicalNftContract_,
        uint256 replicaTokenId_,
        address sourceOwnerAddress_,
        address destinationOwnerAddress_
    ) external {
        emit ReplicaBridgingInitiated(
            msg.sender,
            canonicalNftContract_,
            replicaTokenId_,
            sourceOwnerAddress_,
            destinationOwnerAddress_
        );
    }

    function emitReplicaBridgingFinalized(
        address canonicalNftContract_,
        uint256 replicaTokenId_,
        address sourceOwnerAddress_,
        address destinationOwnerAddress_
    ) external {
        emit ReplicaBridgingFinalized(
            msg.sender,
            canonicalNftContract_,
            replicaTokenId_,
            sourceOwnerAddress_,
            destinationOwnerAddress_
        );
    }
}
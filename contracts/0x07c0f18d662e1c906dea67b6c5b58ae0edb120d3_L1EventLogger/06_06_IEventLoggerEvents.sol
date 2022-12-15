// SPDX-License-Identifier: MIT
pragma solidity ^0.8.12;

//**
//* As convention, we put the indexed address of the caller as the first parameter of each event.
//* This is so that we can verify that the (indirect) emitter of the event is a verified part
//* of the protocol.
//**
interface IEventLoggerEvents {
    event ReplicaDeployed(
        address indexed replicaFactory,
        address indexed replica
    );

    event ReplicaRegistered(
        address indexed replicaRegistry,
        address indexed canonicalNftContract,
        uint256 canonicalTokenId,
        address indexed replica
    );

    event ReplicaUnregistered(
        address indexed replicaRegistry,
        address indexed replica
    );

    event ReplicaTransferred(
        address indexed replica,
        uint256 canonicalTokenId,
        uint256 replicaTokenId
    );

    event ReplicaBridgingInitiated(
        address indexed bridge,
        address indexed canonicalNftContract,
        uint256 replicaTokenId,
        address indexed sourceOwnerAddress,
        address destinationOwnerAddress
    );

    event ReplicaBridgingFinalized(
        address indexed bridge,
        address indexed canonicalNftContract,
        uint256 replicaTokenId,
        address sourceOwnerAddress,
        address indexed destinationOwnerAddress
    );
}
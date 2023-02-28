// SPDX-License-Identifier: Apache 2
pragma solidity 0.8.16;

interface IWormhole {

    struct Signature {
        bytes32 r;
        bytes32 s;
        uint8 v;
        uint8 guardianIndex;
    }

    struct VM {
        uint8 version;
        uint32 timestamp;
        uint32 nonce;
        uint16 emitterChainId;
        bytes32 emitterAddress;
        uint64 sequence;
        uint8 consistencyLevel;
        bytes payload;

        uint32 guardianSetIndex;
        Signature[] signatures;

        bytes32 hash;
    }

    function parseAndVerifyVM(bytes calldata encodedVM) external view returns (VM memory vm, bool valid, string memory reason);
    function parseVM(bytes memory encodedVM) external pure returns (VM memory vm);
}
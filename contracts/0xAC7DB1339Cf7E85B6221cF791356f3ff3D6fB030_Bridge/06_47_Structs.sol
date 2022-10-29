//SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.7;

import "./Enums.sol";

interface Structs {
    struct VSM {
        bytes32 emitter;
        uint16 chainId;
        uint64 sequence;
        bytes32 nonce;
        bytes payload;
        //signatures must be in ascending order, correlated with the authorities
        Signature[] signatures;
    }

    struct BridgeToken {
        bytes tokenClassKey;
        uint16 destinationChainId;
        uint256 quantity;
        uint256 instance;
        bytes recipient;
    }

    struct BridgeUpgrade {
        address newImplementation;
        uint256 onlyAfterBlock;
        bytes init;
    }

    struct Signature {
        bytes32 r;
        bytes32 s;
        uint8 v;
        uint8 index;
    }

    /// @notice This struct defines a collection configuration in the bridge.
    /// All data, except enabled flag, is immutable as changing these values
    /// on a collection that is already operating can be catastrophic.
    struct TokenBridge {
        bytes tokenClassKey;
        bool initialized;
        bool burning;
        bool enabled;
        address token;
        uint256 baseType;
    }
}
// SPDX-License-Identifier: Unlicensed

pragma solidity 0.8.16;

library EthboxStructs {
    struct Message {
        string message;
        uint256 originalValue;
        uint256 claimedValue;
        uint256 data;
    }

    struct MessageData {
        address from;
        uint64 timestamp;
        uint8 index;
        uint24 feeBPS;
    }

    struct UnpackedMessage {
        string message;
        uint256 originalValue;
        uint256 claimedValue;
        address from;
        uint64 timestamp;
        uint8 index;
        uint24 feeBPS;
    }

    struct MessageInfo {
        address to;
        string visibility;
        UnpackedMessage message;
        uint256 index;
        uint256 maxSize;
    }

    struct EthboxInfo {
        address recipient;
        uint8 size;
        bool locked;
        uint64 drip;
    }
}
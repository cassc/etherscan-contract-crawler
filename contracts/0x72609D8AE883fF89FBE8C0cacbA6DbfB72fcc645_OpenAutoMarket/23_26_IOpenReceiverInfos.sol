// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

interface IOpenReceiverInfos {
    struct ReceiverInfos {
        address account;
        uint96 fee;
        uint256 minimum;
    }
}
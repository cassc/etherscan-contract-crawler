// SPDX-License-Identifier: GPL-3.0-only
pragma solidity 0.8.7;

interface INativeReceiver {
    function receivePacket(uint256 packetId, bytes32 root) external;
}
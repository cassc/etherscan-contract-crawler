// SPDX-License-Identifier: GPL-3.0-only
pragma solidity 0.8.7;

import "./BaseCapacitor.sol";

contract SingleCapacitor is BaseCapacitor {
    /**
     * @notice initialises the contract with socket address
     */
    constructor(address socket_) BaseCapacitor(socket_) {}

    /// adds the packed message to a packet
    /// @inheritdoc ICapacitor
    function addPackedMessage(
        bytes32 packedMessage_
    ) external override onlyRole(SOCKET_ROLE) {
        uint256 packetCount = _packets;
        _roots[packetCount] = packedMessage_;
        _packets++;

        emit MessageAdded(packedMessage_, packetCount, packedMessage_);
    }

    function sealPacket()
        external
        virtual
        override
        onlyRole(SOCKET_ROLE)
        returns (bytes32, uint256)
    {
        uint256 packetCount = _sealedPackets++;
        bytes32 root = _roots[packetCount];

        if (_roots[packetCount] == bytes32(0)) revert NoPendingPacket();

        emit PacketComplete(root, packetCount);
        return (root, packetCount);
    }
}
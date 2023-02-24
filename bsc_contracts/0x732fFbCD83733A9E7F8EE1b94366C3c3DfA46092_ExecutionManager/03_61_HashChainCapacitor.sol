// SPDX-License-Identifier: GPL-3.0-only
pragma solidity 0.8.7;

import "./BaseCapacitor.sol";

contract HashChainCapacitor is BaseCapacitor {
    uint256 private _chainLength;
    uint256 private constant _MAX_LEN = 10;

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

        _roots[packetCount] = keccak256(
            abi.encode(_roots[packetCount], packedMessage_)
        );
        _chainLength++;

        if (_chainLength == _MAX_LEN) {
            _packets++;
            _chainLength = 0;
        }

        emit MessageAdded(packedMessage_, packetCount, _roots[packetCount]);
    }

    function sealPacket()
        external
        virtual
        override
        onlyRole(SOCKET_ROLE)
        returns (bytes32, uint256)
    {
        uint256 packetCount = _sealedPackets++;

        if (_roots[packetCount] == bytes32(0)) revert NoPendingPacket();
        bytes32 root = _roots[packetCount];

        emit PacketComplete(root, packetCount);
        return (root, packetCount);
    }
}
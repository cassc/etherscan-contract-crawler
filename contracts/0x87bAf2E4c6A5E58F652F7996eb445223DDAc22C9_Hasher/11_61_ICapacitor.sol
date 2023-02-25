// SPDX-License-Identifier: GPL-3.0-only
pragma solidity 0.8.7;

interface ICapacitor {
    /**
     * @notice emits the message details when it arrives
     * @param packedMessage the message packed with payload, fees and config
     * @param packetCount an incremental id assigned to each new packet
     * @param newRootHash the packed message hash (to be replaced with the root hash of the merkle tree)
     */
    event MessageAdded(
        bytes32 packedMessage,
        uint256 packetCount,
        bytes32 newRootHash
    );

    /**
     * @notice emits when the packet is sealed and indicates it can be send to remote
     * @param rootHash the packed message hash (to be replaced with the root hash of the merkle tree)
     * @param packetCount an incremental id assigned to each new packet
     */
    event PacketComplete(bytes32 rootHash, uint256 packetCount);

    /**
     * @notice adds the packed message to a packet
     * @dev this should be only executable by socket
     * @dev it will be later replaced with a function adding each message to a merkle tree
     * @param packedMessage the message packed with payload, fees and config
     */
    function addPackedMessage(bytes32 packedMessage) external;

    /**
     * @notice returns the latest packet details which needs to be sealed
     * @return root root hash of the latest packet which is not yet sealed
     * @return packetCount latest packet id which is not yet sealed
     */
    function getNextPacketToBeSealed()
        external
        view
        returns (bytes32 root, uint256 packetCount);

    /**
     * @notice returns the root of packet for given id
     * @param id the id assigned to packet
     * @return root root hash corresponding to given id
     */
    function getRootById(uint256 id) external view returns (bytes32 root);

    /**
     * @notice seals the packet
     * @dev also indicates the packet is ready to be shipped and no more messages can be added now.
     * @dev this should be executable by socket only
     * @return root root hash of the packet
     * @return packetCount id of the packed sealed
     */
    function sealPacket() external returns (bytes32 root, uint256 packetCount);
}
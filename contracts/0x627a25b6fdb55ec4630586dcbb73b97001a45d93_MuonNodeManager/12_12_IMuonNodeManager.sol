// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

interface IMuonNodeManager {
    struct Node {
        uint64 id; // incremental ID
        address nodeAddress; // will be used on the node
        address stakerAddress;
        string peerId; // p2p peer ID
        bool active;
        uint8 tier;
        uint64[] roles;
        uint256 startTime;
        uint256 endTime;
        uint256 lastEditTime;
    }

    function addNode(
        address _nodeAddress,
        address _stakerAddress,
        string calldata _peerId,
        bool _active
    ) external;

    function deactiveNode(uint64 nodeId) external;

    function stakerAddressInfo(
        address _addr
    ) external view returns (Node memory node);

    function setTier(uint64 nodeId, uint8 tier) external;
}
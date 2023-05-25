pragma solidity 0.7.6;

// SPDX-License-Identifier: GPL-3.0-only

interface IStafiNodeManager {
    function getNodeCount() external view returns (uint256);
    function getNodeAt(uint256 _index) external view returns (address);
    function getTrustedNodeCount() external view returns (uint256);
    function getTrustedNodeAt(uint256 _index) external view returns (address);
    function getSuperNodeCount() external view returns (uint256);
    function getSuperNodeAt(uint256 _index) external view returns (address);
    function getNodeExists(address _nodeAddress) external view returns (bool);
    function getNodeTrusted(address _nodeAddress) external view returns (bool);
    function getSuperNodeExists(address _nodeAddress) external view returns (bool);
    function registerNode(address _nodeAddress) external;
    function setNodeTrusted(address _nodeAddress, bool _trusted) external;
    function setNodeSuper(address _nodeAddress, bool _super) external;
}
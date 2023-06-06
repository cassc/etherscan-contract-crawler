// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "../../../interfaces/IMessenger.sol";
import "../../RestrictedCalls.sol";
import "polygon_zkevm/PolygonZkBridgeInterface.sol";

// This messenger reepresents both L1 & L2 messengers.
// The prefix "local" refers to instances on the same chain, while
// the prefix "remote" refers to instances on the other layer.
contract PolygonZkEVMMessenger is IMessenger, RestrictedCalls {
    IPolygonZkEVMBridge public immutable bridge;
    address public immutable localCallee;
    address public remoteMessenger;
    // 1 means Polygon ZkEVM and 0 means L1
    uint32 public immutable remoteNetwork;

    constructor(address _bridge, address _localCallee, uint32 _remoteNetwork) {
        bridge = IPolygonZkEVMBridge(_bridge);
        localCallee = _localCallee;
        remoteNetwork = _remoteNetwork;
    }

    function setRemoteMessenger(address _remoteMessenger) public onlyOwner {
        require(remoteMessenger == address(0), "Remote messenger already set");
        remoteMessenger = _remoteMessenger;
    }

    // This messenger is the direct courier for the localCallee because
    // it calls localCallee in onMessageReceived.
    // We dont check for caller because we already do that in onMessageReceived.
    function callAllowed(
        address,
        address courier
    ) external view returns (bool) {
        return courier == address(this);
    }

    // This function is the callback and is receiving the message
    // from native bridge. The origin address should be remoteMessenger.
    function onMessageReceived(
        address originAddress,
        uint32 originNetwork,
        bytes memory data
    ) external payable {
        require(msg.sender == address(bridge), "Call not allowed");
        require(originNetwork == remoteNetwork, "Origin not allowed");
        require(originAddress == remoteMessenger, "Call forbidden");
        (bool sent, ) = localCallee.call(data);
        require(sent, "Failed to execute call");
    }

    function sendMessage(
        address,
        bytes calldata message
    ) external restricted(block.chainid) {
        bridge.bridgeMessage(remoteNetwork, remoteMessenger, true, message);
    }
}
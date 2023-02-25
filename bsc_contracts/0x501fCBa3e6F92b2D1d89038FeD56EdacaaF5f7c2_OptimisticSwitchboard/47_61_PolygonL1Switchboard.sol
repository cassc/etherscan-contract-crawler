// SPDX-License-Identifier: GPL-3.0-only
pragma solidity 0.8.7;

import "lib/contracts/contracts/tunnel/FxBaseRootTunnel.sol";
import "./NativeSwitchboardBase.sol";

contract PolygonL1Switchboard is NativeSwitchboardBase, FxBaseRootTunnel {
    // stores the roots received from native bridge
    mapping(uint256 => bytes32) public roots;

    event FxChildTunnelSet(address fxRootTunnel, address newFxRootTunnel);
    event RootReceived(uint256 packetId, bytes32 root);

    error NoRootFound();

    constructor(
        uint256 initialConfirmationGasLimit_,
        uint256 executionOverhead_,
        address checkpointManager_,
        address fxRoot_,
        address owner_,
        IOracle oracle_
    ) AccessControl(owner_) FxBaseRootTunnel(checkpointManager_, fxRoot_) {
        oracle__ = oracle_;

        initateNativeConfirmationGasLimit = initialConfirmationGasLimit_;
        executionOverhead = executionOverhead_;
    }

    /**
     * @param packetId_ - packet id
     */
    function initateNativeConfirmation(uint256 packetId_) external payable {
        uint256 capacitorPacketCount = uint256(uint64(packetId_));
        bytes32 root = capacitor__.getRootById(capacitorPacketCount);
        if (root == bytes32(0)) revert NoRootFound();

        bytes memory data = abi.encode(packetId_, root);
        _sendMessageToChild(data);
        emit InitiatedNativeConfirmation(packetId_);
    }

    function _processMessageFromChild(bytes memory message_) internal override {
        (uint256 packetId, bytes32 root) = abi.decode(
            message_,
            (uint256, bytes32)
        );
        roots[packetId] = root;
        emit RootReceived(packetId, root);
    }

    /**
     * @notice verifies if the packet satisfies needed checks before execution
     * @param packetId_ packet id
     */
    function allowPacket(
        bytes32 root_,
        uint256 packetId_,
        uint256,
        uint256
    ) external view override returns (bool) {
        if (tripGlobalFuse) return false;
        if (roots[packetId_] != root_) return false;

        return true;
    }

    function _getSwitchboardFees(
        uint256,
        uint256,
        uint256 sourceGasPrice_
    ) internal view override returns (uint256) {
        return initateNativeConfirmationGasLimit * sourceGasPrice_;
    }

    // set fxChildTunnel if not set already
    function updateFxChildTunnel(address fxChildTunnel_) external onlyOwner {
        emit FxChildTunnelSet(fxChildTunnel, fxChildTunnel_);
        fxChildTunnel = fxChildTunnel_;
    }
}
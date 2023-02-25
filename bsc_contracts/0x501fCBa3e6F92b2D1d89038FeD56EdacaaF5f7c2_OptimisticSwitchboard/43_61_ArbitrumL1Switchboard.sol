// SPDX-License-Identifier: GPL-3.0-only
pragma solidity 0.8.7;

import "../../interfaces/native-bridge/IInbox.sol";
import "../../interfaces/native-bridge/IOutbox.sol";
import "../../interfaces/native-bridge/IBridge.sol";
import "../../interfaces/native-bridge/INativeReceiver.sol";

import "./NativeSwitchboardBase.sol";

contract ArbitrumL1Switchboard is NativeSwitchboardBase, INativeReceiver {
    address public remoteRefundAddress;
    address public callValueRefundAddress;
    address public remoteNativeSwitchboard;
    uint256 public dynamicFees;

    IInbox public inbox__;

    // stores the roots received from native bridge
    mapping(uint256 => bytes32) public roots;

    event UpdatedInboxAddress(address inbox);
    event UpdatedRefundAddresses(
        address remoteRefundAddress,
        address callValueRefundAddress
    );
    event UpdatedRemoteNativeSwitchboard(address remoteNativeSwitchboard);
    event RootReceived(uint256 packetId, bytes32 root);
    event UpdatedDynamicFees(uint256 dynamicFees);

    error InvalidSender();
    error NoRootFound();

    modifier onlyRemoteSwitchboard() {
        IBridge bridge__ = inbox__.bridge();
        if (msg.sender != address(bridge__)) revert InvalidSender();

        IOutbox outbox__ = IOutbox(bridge__.activeOutbox());
        address l2Sender = outbox__.l2ToL1Sender();
        if (l2Sender != remoteNativeSwitchboard) revert InvalidSender();

        _;
    }

    constructor(
        uint256 dynamicFees_,
        uint256 initialConfirmationGasLimit_,
        uint256 executionOverhead_,
        address remoteNativeSwitchboard_,
        address inbox_,
        address owner_,
        IOracle oracle_
    ) AccessControl(owner_) {
        dynamicFees = dynamicFees_;
        initateNativeConfirmationGasLimit = initialConfirmationGasLimit_;
        executionOverhead = executionOverhead_;

        inbox__ = IInbox(inbox_);
        remoteNativeSwitchboard = remoteNativeSwitchboard_;
        oracle__ = oracle_;

        remoteRefundAddress = msg.sender;
        callValueRefundAddress = msg.sender;
    }

    function initateNativeConfirmation(
        uint256 packetId_,
        uint256 maxSubmissionCost_,
        uint256 maxGas_,
        uint256 gasPriceBid_
    ) external payable {
        uint256 capacitorPacketCount = uint256(uint64(packetId_));
        bytes32 root = capacitor__.getRootById(capacitorPacketCount);
        if (root == bytes32(0)) revert NoRootFound();

        bytes memory data = abi.encodeWithSelector(
            INativeReceiver.receivePacket.selector,
            packetId_,
            root
        );

        // to avoid stack too deep
        address callValueRefund = callValueRefundAddress;
        address remoteRefund = remoteRefundAddress;

        inbox__.createRetryableTicket{value: msg.value}(
            remoteNativeSwitchboard,
            0, // no value needed for receivePacket
            maxSubmissionCost_,
            remoteRefund,
            callValueRefund,
            maxGas_,
            gasPriceBid_,
            data
        );

        emit InitiatedNativeConfirmation(packetId_);
    }

    function receivePacket(
        uint256 packetId_,
        bytes32 root_
    ) external override onlyRemoteSwitchboard {
        roots[packetId_] = root_;
        emit RootReceived(packetId_, root_);
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
        // TODO: check if dynamic fees can be divided into more constants
        // arbitrum: check src contract
        return
            initateNativeConfirmationGasLimit * sourceGasPrice_ + dynamicFees;
    }

    function updateRefundAddresses(
        address remoteRefundAddress_,
        address callValueRefundAddress_
    ) external onlyOwner {
        remoteRefundAddress = remoteRefundAddress_;
        callValueRefundAddress = callValueRefundAddress_;

        emit UpdatedRefundAddresses(
            remoteRefundAddress_,
            callValueRefundAddress_
        );
    }

    function updateDynamicFees(uint256 dynamicFees_) external onlyOwner {
        dynamicFees = dynamicFees_;
        emit UpdatedDynamicFees(dynamicFees_);
    }

    function updateInboxAddresses(address inbox_) external onlyOwner {
        inbox__ = IInbox(inbox_);
        emit UpdatedInboxAddress(inbox_);
    }

    function updateRemoteNativeSwitchboard(
        address remoteNativeSwitchboard_
    ) external onlyOwner {
        remoteNativeSwitchboard = remoteNativeSwitchboard_;
        emit UpdatedRemoteNativeSwitchboard(remoteNativeSwitchboard_);
    }
}
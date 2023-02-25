// SPDX-License-Identifier: GPL-3.0-only
pragma solidity 0.8.7;

import "../../interfaces/native-bridge/ICrossDomainMessenger.sol";
import "../../interfaces/native-bridge/INativeReceiver.sol";

import "./NativeSwitchboardBase.sol";

contract OptimismSwitchboard is NativeSwitchboardBase, INativeReceiver {
    uint256 public receivePacketGasLimit;
    uint256 public l2ReceiveGasLimit;

    address public remoteNativeSwitchboard;
    // stores the roots received from native bridge
    mapping(uint256 => bytes32) public roots;

    ICrossDomainMessenger public crossDomainMessenger__;

    event UpdatedRemoteNativeSwitchboard(address remoteNativeSwitchboard);
    event UpdatedReceivePacketGasLimit(uint256 receivePacketGasLimit);
    event RootReceived(uint256 packetId, bytes32 root);
    event UpdatedL2ReceiveGasLimit(uint256 l2ReceiveGasLimit);

    error InvalidSender();
    error NoRootFound();

    modifier onlyRemoteSwitchboard() {
        if (
            msg.sender != address(crossDomainMessenger__) &&
            crossDomainMessenger__.xDomainMessageSender() !=
            remoteNativeSwitchboard
        ) revert InvalidSender();
        _;
    }

    constructor(
        uint256 receivePacketGasLimit_,
        uint256 l2ReceiveGasLimit_,
        uint256 initialConfirmationGasLimit_,
        uint256 executionOverhead_,
        address remoteNativeSwitchboard_,
        address owner_,
        IOracle oracle_
    ) AccessControl(owner_) {
        receivePacketGasLimit = receivePacketGasLimit_;

        l2ReceiveGasLimit = l2ReceiveGasLimit_;
        initateNativeConfirmationGasLimit = initialConfirmationGasLimit_;
        executionOverhead = executionOverhead_;

        remoteNativeSwitchboard = remoteNativeSwitchboard_;
        oracle__ = oracle_;

        if ((block.chainid == 10 || block.chainid == 420)) {
            crossDomainMessenger__ = ICrossDomainMessenger(
                0x4200000000000000000000000000000000000007
            );
        } else {
            crossDomainMessenger__ = block.chainid == 1
                ? ICrossDomainMessenger(
                    0x25ace71c97B33Cc4729CF772ae268934F7ab5fA1
                )
                : ICrossDomainMessenger(
                    0x5086d1eEF304eb5284A0f6720f79403b4e9bE294
                );
        }
    }

    function initateNativeConfirmation(uint256 packetId_) external {
        uint256 capacitorPacketCount = uint256(uint64(packetId_));
        bytes32 root = capacitor__.getRootById(capacitorPacketCount);
        bytes memory data = abi.encodeWithSelector(
            INativeReceiver.receivePacket.selector,
            packetId_,
            root
        );

        crossDomainMessenger__.sendMessage(
            remoteNativeSwitchboard,
            data,
            uint32(receivePacketGasLimit)
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
        uint256 dstRelativeGasPrice_,
        uint256 sourceGasPrice_
    ) internal view override returns (uint256) {
        // l2ReceiveGasLimit will be 0 when switchboard is deployed on L1
        return
            initateNativeConfirmationGasLimit *
            sourceGasPrice_ +
            l2ReceiveGasLimit *
            dstRelativeGasPrice_;
    }

    function updateL2ReceiveGasLimit(
        uint256 l2ReceiveGasLimit_
    ) external onlyOwner {
        l2ReceiveGasLimit = l2ReceiveGasLimit_;
        emit UpdatedL2ReceiveGasLimit(l2ReceiveGasLimit_);
    }

    function updateRemoteNativeSwitchboard(
        address remoteNativeSwitchboard_
    ) external onlyOwner {
        remoteNativeSwitchboard = remoteNativeSwitchboard_;
        emit UpdatedRemoteNativeSwitchboard(remoteNativeSwitchboard_);
    }

    function updateReceivePacketGasLimit(
        uint256 receivePacketGasLimit_
    ) external onlyOwner {
        receivePacketGasLimit = receivePacketGasLimit_;
        emit UpdatedReceivePacketGasLimit(receivePacketGasLimit_);
    }
}
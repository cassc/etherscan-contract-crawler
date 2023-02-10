// SPDX-License-Identifier: Unlicensed
pragma solidity ^0.8.15;

// we actually do use assembly to parse roundtrips
/* solhint-disable no-inline-assembly */

import "sgn-v2-contracts/contracts/message/libraries/MessageSenderLib.sol";
import "sgn-v2-contracts/contracts/message/interfaces/IMessageBus.sol";
import "sgn-v2-contracts/contracts/message/interfaces/IMessageReceiverApp.sol";

import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/interfaces/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/structs/BitMaps.sol";

import "./lib/CollectTokens.sol";

uint8 constant MESSAGE_KIND_ROUNDTRIP = 1;
uint8 constant MESSAGE_KIND_REWARD = 2;

abstract contract IMCeler is IMessageReceiverApp, Ownable {
    using SafeERC20 for IERC20;

    struct MessageWithTransferQueueEntry {
        address token;
        uint256 amount;
        bytes message;
    }

    address public peerAddress;
    uint64 public peerChainId;

    address public immutable messageBus;

    uint32 public maxSlippage = 1000000;

    MessageWithTransferQueueEntry[] public incomingMessageQueue;

    BitMaps.BitMap private _seenRoundtripId;
    uint64 private _celerSendMessageWithTransferNonce;

    event OutgoingMessageSent(bytes32 roundtripId);
    event OutgoingMessageWithTransferSent(bytes32 roundtripId, address token, uint256 amount);

    event OutgoingMessageWithTransferRefund(bytes32 roundtripId, address token, uint256 tokenAmount);
    event OutgoingMessageWithTransferFallback(bytes32 roundtripId, address token, uint256 tokenAmount);

    event IncomingMessageQueued(bytes32 roundtripId);
    event IncomingMessageWithTransferQueued(bytes32 roundtripId, address token, uint256 amount);

    // IMCeler inherited classes are responsible for firing events indicating successful processing of incoming messages

    event ConfigurationUpdated();

    constructor(address _messageBus) {
        messageBus = _messageBus;
    }

    modifier onlyMessageBusOrOwner() {
        require(msg.sender == messageBus || msg.sender == owner(), "MESSAGEBUS_OR_OWNER");
        _;
    }

    modifier onlyFromPeer(address _peerAddress, uint64 _peerChainId) {
        require(peerAddress == _peerAddress && peerChainId == _peerChainId, "PEER");
        _;
    }

    modifier onlyUnique(bytes memory message) {
        uint256 roundtripId = uint256(getRoundtripIdFromMessage(message));

        if (BitMaps.get(_seenRoundtripId, roundtripId)) {
            revert("UNIQUE");
        }

        BitMaps.set(_seenRoundtripId, roundtripId);

        _;
    }

    function onMessage(bytes memory message) internal virtual;
    function onMessageWithTransfer(bytes memory message, address token, uint256 amount) internal virtual;

    function getRoundtripIdFromMessage(bytes memory message)
        internal
        pure
        returns (bytes32 roundtripId)
    {
        assembly {
            roundtripId := mload(add(message, 32))
        }
    }

    function executeMessageWithTransfer(
        address sender,
        address token,
        uint256 amount,
        uint64 srcChainId,
        bytes calldata incomingMessage,
        address executor
    )
        external
        payable
        override
        onlyMessageBusOrOwner
        onlyFromPeer(sender, srcChainId)
        onlyUnique(incomingMessage)
        returns (ExecutionStatus)
    {
        require(IERC20(token).balanceOf(address(this)) >= amount, "INSUFFICIENT_BRIDGE");

        incomingMessageQueue.push(MessageWithTransferQueueEntry({
            token: token,
            amount: amount,
            message: incomingMessage
        }));

        bytes32 roundtripId = getRoundtripIdFromMessage(incomingMessage);
        emit IncomingMessageWithTransferQueued(roundtripId, token, amount);

        _refundMsgValue(executor);

        return ExecutionStatus.Success;
    }

    function executeMessageWithTransferRefund(
        address token,
        uint256 amount,
        bytes calldata incomingMessage,
        address executor
    )
        external
        payable
        override
        onlyMessageBusOrOwner
        onlyUnique(incomingMessage)
        returns (ExecutionStatus)
    {
        bytes32 roundtripId = getRoundtripIdFromMessage(incomingMessage);
        emit OutgoingMessageWithTransferRefund(roundtripId, token, amount);

        _refundMsgValue(executor);

        return ExecutionStatus.Success;
    }

    function executeMessageWithTransferFallback(
        address sender,
        address token,
        uint256 amount,
        uint64 srcChainId,
        bytes calldata incomingMessage,
        address executor
    )
        external
        payable
        override
        onlyMessageBusOrOwner
        onlyFromPeer(sender, srcChainId)
        onlyUnique(incomingMessage)
        returns (ExecutionStatus)
    {
        bytes32 roundtripId = getRoundtripIdFromMessage(incomingMessage);
        emit OutgoingMessageWithTransferFallback(roundtripId, token, amount);

        _refundMsgValue(executor);

        return ExecutionStatus.Success;
    }

    function executeMessage(
        address sender,
        uint64 srcChainId,
        bytes calldata incomingMessage,
        address executor
    )
        external
        payable
        override
        onlyMessageBusOrOwner
        onlyFromPeer(sender, srcChainId)
        onlyUnique(incomingMessage)
        returns (ExecutionStatus)
    {
        incomingMessageQueue.push(MessageWithTransferQueueEntry({
            token: address(0),
            amount: 0,
            message: incomingMessage
        }));

        bytes32 roundtripId = getRoundtripIdFromMessage(incomingMessage);
        emit IncomingMessageQueued(roundtripId);

        _refundMsgValue(executor);

        return ExecutionStatus.Success;
    }

    // non-evm variant
    function executeMessage(
        bytes calldata sender, // solhint-disable-line no-unused-vars
        uint64 srcChainId, // solhint-disable-line no-unused-vars
        bytes calldata incomingMessage,
        address executor
    )
        external
        payable
        override
        onlyMessageBusOrOwner
        // onlyFromPeer(sender, srcChainId) // not yet.
        onlyUnique(incomingMessage)
        returns (ExecutionStatus)
    {
        _refundMsgValue(executor);
        return ExecutionStatus.Fail;
    }

    function tossIncomingMessageQueue()
        public
        payable
    {
        require(incomingMessageQueue.length > 0, "EMPTY");

        uint256 originalBalance = address(this).balance;

        for (uint i=0; i<incomingMessageQueue.length; i++) {
            if (incomingMessageQueue[i].token == address(0)) {
                onMessage(incomingMessageQueue[i].message);
            } else {
                onMessageWithTransfer(incomingMessageQueue[i].message, incomingMessageQueue[i].token, incomingMessageQueue[i].amount);
            }
        }

        delete incomingMessageQueue;

        uint256 feePaid = originalBalance - address(this).balance;
        if (feePaid < msg.value) {
            payable(msg.sender).transfer(msg.value - feePaid);
        }
    }

    function sendMessage(bytes memory message)
        internal
        returns (uint256 fee)
    {
        fee = IMessageBus(messageBus).calcFee(message);
        require(address(this).balance >= fee, "CELER_FEE");

        MessageSenderLib.sendMessage(peerAddress, peerChainId, message, messageBus, fee);

        bytes32 roundtripId = getRoundtripIdFromMessage(message);
        emit OutgoingMessageSent(roundtripId);
    }

    function sendMessageWithTransfer(address token, uint256 amount, bytes memory message)
        internal
        returns (uint256 fee)
    {
        fee = IMessageBus(messageBus).calcFee(message);
        require(address(this).balance >= fee, "CELER_FEE");

        MessageSenderLib.sendMessageWithTransfer(
            peerAddress,
            token,
            amount,
            peerChainId,
            _celerSendMessageWithTransferNonce,
            maxSlippage,
            message,
            MsgDataTypes.BridgeSendType.Liquidity,
            messageBus,
            fee
        );

        _celerSendMessageWithTransferNonce++;

        bytes32 roundtripId = getRoundtripIdFromMessage(message);
        emit OutgoingMessageWithTransferSent(roundtripId, token, amount);
    }

    function clearIncomingMessageQueue()
        public
        onlyOwner
    {
        delete incomingMessageQueue;
    }

    function setPeer(address _peerAddress, uint64 _peerChainId)
        public
        onlyOwner
    {
        peerAddress = _peerAddress;
        peerChainId = _peerChainId;

        emit ConfigurationUpdated();
    }

    function setMaxSlippage(uint32 _maxSlippage)
        public
        onlyOwner
    {
        maxSlippage = _maxSlippage;

        emit ConfigurationUpdated();
    }

    function isSeenRoundtripId(bytes32 roundtripId)
        public
        view
        returns (bool)
    {
        return BitMaps.get(_seenRoundtripId, uint256(roundtripId));
    }

    function markRoundtripId(bytes32 roundtripId, bool isUsed)
        public
        onlyOwner
    {
        if (isUsed) {
            BitMaps.set(_seenRoundtripId, uint256(roundtripId));
            return;
        }

        BitMaps.unset(_seenRoundtripId, uint256(roundtripId));
    }

    function collectTokens(address[] memory tokens, address to)
        public
        onlyOwner
    {
        CollectTokens._collectTokens(tokens, to);
    }

    // Some methods must be `payable` while in fact they
    // do not consume any native tokens. We refund `msg.value`
    // in full for those methods.
    function _refundMsgValue(address executor)
        internal
    {
        if (msg.value > 0) {
            payable(executor).transfer(msg.value);
        }
    }
}
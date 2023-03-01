// SPDX-License-Identifier: Unlicensed
pragma solidity ^0.8.15;

import "sgn-v2-contracts/contracts/message/libraries/MessageSenderLib.sol";
import "sgn-v2-contracts/contracts/message/interfaces/IMessageBus.sol";
import "sgn-v2-contracts/contracts/message/interfaces/IMessageReceiverApp.sol";

import "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/interfaces/IERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/interfaces/IERC20MetadataUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/structs/BitMapsUpgradeable.sol";

import "./lib/Serializer.sol";
import "./lib/CollectTokens.sol";

abstract contract IMCeler is IMessageReceiverApp, OwnableUpgradeable {
    using SafeERC20Upgradeable for IERC20Upgradeable;

    struct MessageWithTransferQueueEntry {
        uint256 amount;
        bool isLocalBridge;
        bytes message;
    }

    address public quoteToken;

    address public localBridgeCustodian;
    uint256 public localBridgeTresholdAmount;

    address public peerAddress;
    uint64 public peerChainId;

    uint64 private celerSendMessageWithTransferNonce;

    uint32 public maxSlippage = 30000; // 3% = 30000

    address public messageBus;

    MessageWithTransferQueueEntry[] public incomingMessageQueue;

    BitMapsUpgradeable.BitMap private seenRoundtripId;

    event OutgoingMessageSent(bytes32 roundtripId);
    event OutgoingMessageWithTransferSent(bytes32 roundtripId, uint256 amount, bool isLocalBridge);

    event OutgoingMessageWithTransferRefund(bytes32 roundtripId, uint256 tokenAmount);
    event OutgoingMessageWithTransferFallback(bytes32 roundtripId, uint256 tokenAmount);

    event IncomingMessageQueued(bytes32 roundtripId);
    event IncomingMessageWithTransferQueued(bytes32 roundtripId, uint256 amount, bool isLocalBridge);

    // IMCeler inherited classes are responsible for firing events indicating successful processing of incoming messages

    event ConfigurationUpdated();

    constructor() {
        _disableInitializers();
    }

    function __IMCeler_initialize(address _messageBus, address _quoteToken, address _peerAddress, uint64 _peerChainId) // solhint-disable-line func-name-mixedcase
        internal
    {
        messageBus = _messageBus;
        quoteToken = _quoteToken;
        peerAddress = _peerAddress;
        peerChainId = _peerChainId;
        _transferOwnership(msg.sender);
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
        uint256 roundtripId = uint256(Serializer.getRoundtripIdFromMessage(message));

        if (BitMapsUpgradeable.get(seenRoundtripId, roundtripId)) {
            revert("UNIQUE");
        }

        BitMapsUpgradeable.set(seenRoundtripId, roundtripId);

        _;
    }

    function onMessage(bytes memory message) internal virtual;
    function onMessageWithTransfer(bytes memory message, uint256 amount) internal virtual;

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
        require(amount > 0, "ZERO_BRIDGED");
        require(token == quoteToken, "QUOTE_TOKEN");
        require(IERC20Upgradeable(quoteToken).balanceOf(address(this)) >= amount, "INSUFFICIENT_BRIDGED");

        incomingMessageQueue.push(MessageWithTransferQueueEntry({
            amount: amount,
            message: incomingMessage,
            isLocalBridge: false
        }));

        bytes32 roundtripId = Serializer.getRoundtripIdFromMessage(incomingMessage);
        emit IncomingMessageWithTransferQueued(roundtripId, amount, false);

        _refundMsgValue(executor);

        return ExecutionStatus.Success;
    }

    function executeMessageWithTransferRefund(
        address token, // solhint-disable-line no-unused-vars
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
        bytes32 roundtripId = Serializer.getRoundtripIdFromMessage(incomingMessage);
        emit OutgoingMessageWithTransferRefund(roundtripId, amount);

        _refundMsgValue(executor);

        return ExecutionStatus.Success;
    }

    function executeMessageWithTransferFallback(
        address sender,
        address token, // solhint-disable-line no-unused-vars
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
        bytes32 roundtripId = Serializer.getRoundtripIdFromMessage(incomingMessage);
        emit OutgoingMessageWithTransferFallback(roundtripId, amount);

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
        (bytes32 roundtripId, uint256 amount, uint8 peerDecimals, bytes memory message) = abi.decode(incomingMessage, (bytes32, uint256, uint8, bytes));

        bool isLocalBridge = amount > 0;

        if (isLocalBridge) {
            uint8 myDecimals = IERC20MetadataUpgradeable(quoteToken).decimals();
            if (myDecimals > peerDecimals) {
                amount *= (10 ** (myDecimals - peerDecimals));
            } else if (myDecimals < peerDecimals) {
                amount /= (10 ** (peerDecimals - myDecimals));
            } // bear in mind to keep amount intact in case decimals are equal
        }

        incomingMessageQueue.push(MessageWithTransferQueueEntry({
            amount: amount,
            message: message,
            isLocalBridge: isLocalBridge
        }));

        if (isLocalBridge) {
            emit IncomingMessageWithTransferQueued(roundtripId, amount, true);

        } else {
            emit IncomingMessageQueued(roundtripId);
        }

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

        uint256 totalLocalBridgeAmount = 0;
        for (uint i=0; i<incomingMessageQueue.length; i++) {
            if (incomingMessageQueue[i].isLocalBridge) {
                totalLocalBridgeAmount += incomingMessageQueue[i].amount;
            }
        }

        if (totalLocalBridgeAmount > 0) {
            IERC20Upgradeable(quoteToken).transferFrom(localBridgeCustodian, address(this), totalLocalBridgeAmount);
        }

        for (uint i=0; i<incomingMessageQueue.length; i++) {
            if (incomingMessageQueue[i].amount == 0) {
                onMessage(incomingMessageQueue[i].message);
            } else {
                onMessageWithTransfer(incomingMessageQueue[i].message, incomingMessageQueue[i].amount);
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
        bytes32 roundtripId = Serializer.getRoundtripIdFromMessage(message);

        bytes memory transferMessage = abi.encode(roundtripId, uint256(0), uint8(0), message);

        fee = IMessageBus(messageBus).calcFee(transferMessage);
        require(address(this).balance >= fee, "CELER_FEE");

        MessageSenderLib.sendMessage(peerAddress, peerChainId, transferMessage, messageBus, fee);

        emit OutgoingMessageSent(roundtripId);
    }

    function sendMessageWithTransfer(uint256 amount, bytes memory message)
        internal
        returns (uint256 fee)
    {
        bytes32 roundtripId = Serializer.getRoundtripIdFromMessage(message);

        bool isLocalBridge = amount < localBridgeTresholdAmount && localBridgeCustodian != address(0);

        if (isLocalBridge) {
            bytes memory transferMessage = abi.encode(roundtripId, amount, uint8(IERC20MetadataUpgradeable(quoteToken).decimals()), message);

            fee = IMessageBus(messageBus).calcFee(transferMessage);
            require(address(this).balance >= fee, "CELER_FEE");

            MessageSenderLib.sendMessage(peerAddress, peerChainId, transferMessage, messageBus, fee);

            IERC20Upgradeable(quoteToken).transfer(localBridgeCustodian, amount);

        } else {
            fee = IMessageBus(messageBus).calcFee(message);
            require(address(this).balance >= fee, "CELER_FEE");

            MessageSenderLib.sendMessageWithTransfer(
                peerAddress,
                quoteToken,
                amount,
                peerChainId,
                celerSendMessageWithTransferNonce,
                maxSlippage,
                message,
                MsgDataTypes.BridgeSendType.Liquidity,
                messageBus,
                fee
            );

            celerSendMessageWithTransferNonce++;
        }

        emit OutgoingMessageWithTransferSent(roundtripId, amount, isLocalBridge);
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

    function setQuoteToken(address _quoteToken)
        public
        onlyOwner
    {
        quoteToken = _quoteToken;
        emit ConfigurationUpdated();
    }

    function setLocalBridgeProperties(address _localBridgeCustodian, uint256 _localBridgeTresholdAmount)
        public
        onlyOwner
    {
        localBridgeCustodian = _localBridgeCustodian;
        localBridgeTresholdAmount = _localBridgeTresholdAmount;

        emit ConfigurationUpdated();
    }

    function isSeenRoundtripId(bytes32 roundtripId)
        public
        view
        returns (bool)
    {
        return BitMapsUpgradeable.get(seenRoundtripId, uint256(roundtripId));
    }

    function markRoundtripId(bytes32 roundtripId, bool isUsed)
        public
        onlyOwner
    {
        if (isUsed) {
            BitMapsUpgradeable.set(seenRoundtripId, uint256(roundtripId));
            return;
        }

        BitMapsUpgradeable.unset(seenRoundtripId, uint256(roundtripId));
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

    function _shutdown()
        internal
    {
        require(incomingMessageQueue.length == 0, "QUEUE");

        // deleting peer ensures that noone can execute messages anymore
        delete peerChainId;
        delete peerAddress;

        delete quoteToken;
        delete incomingMessageQueue;
        delete seenRoundtripId;
    }
}
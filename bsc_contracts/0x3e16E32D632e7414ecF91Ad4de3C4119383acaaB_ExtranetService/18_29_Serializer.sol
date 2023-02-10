// SPDX-License-Identifier: Unlicensed
pragma solidity ^0.8.15;

import "../IMCeler.sol";
import "../interfaces/IQueueEntry.sol";

library Serializer {
    function createWithdrawMessage(bytes32 roundtripId, QueueEntry[] memory withdrawQueue)
        internal
        pure
        returns (bytes memory)
    {
        return abi.encode(roundtripId, MESSAGE_KIND_ROUNDTRIP, withdrawQueue);
    }

    function parseWithdrawMessage(bytes memory incomingMessage)
        internal
        pure
        returns (bytes32 roundtripId, QueueEntry[] memory incomingQueue)
    {
        (roundtripId, , incomingQueue) = abi.decode(incomingMessage, (bytes32, uint8, QueueEntry[]));
    }

    function createInvestMessage(bytes32 roundtripId, QueueEntry[] memory investQueue)
        internal
        pure
        returns (bytes memory)
    {
        return abi.encode(roundtripId, MESSAGE_KIND_ROUNDTRIP, investQueue);
    }

    function parseInvestMessage(bytes memory incomingMessage)
        internal
        pure
        returns (bytes32 roundtripId, QueueEntry[] memory incomingQueue)
    {
        (roundtripId, , incomingQueue) = abi.decode(incomingMessage, (bytes32, uint8, QueueEntry[]));
    }

    function createInvestResponseMessage(bytes32 roundtripId, QueueEntry[] memory outgoingQueue)
        internal
        pure
        returns (bytes memory)
    {
        return abi.encode(roundtripId, MESSAGE_KIND_ROUNDTRIP, outgoingQueue);
    }

    function createWithdrawResponseMessage(bytes32 roundtripId, uint256 totalQuoteTokenAmount, QueueEntry[] memory outgoingQueue)
        internal
        pure
        returns (bytes memory)
    {
        return abi.encode(roundtripId, MESSAGE_KIND_ROUNDTRIP, totalQuoteTokenAmount, outgoingQueue);
    }

    function createRewardMessage(bytes32 rewardMessageId, uint256 rewardAmount)
        internal
        pure
        returns (bytes memory)
    {
        return abi.encode(rewardMessageId, MESSAGE_KIND_REWARD, rewardAmount);
    }
}
// SPDX-License-Identifier: Unlicensed
pragma solidity ^0.8.15;

// we actually do use assembly to parse roundtrips
/* solhint-disable no-inline-assembly */

import "../interfaces/IQueueEntry.sol";

uint8 constant MESSAGE_KIND_INVEST = 1;
uint8 constant MESSAGE_KIND_WITHDRAW = 2;
uint8 constant MESSAGE_KIND_REWARD = 3;

library Serializer {
    function createQueueMessage(bytes32 roundtripId, uint256 totalAmount, QueueEntry[] memory queue)
        internal
        pure
        returns (bytes memory)
    {
        return abi.encode(roundtripId, totalAmount, queue);
    }

    function parseQueueMessage(bytes memory message)
        internal
        pure
        returns (bytes32 roundtripId, uint256 totalAmount, QueueEntry[] memory queue)
    {
        (roundtripId, totalAmount, queue) = abi.decode(message, (bytes32, uint256, QueueEntry[]));
    }

    function createRewardMessage(bytes32 rewardMessageId, uint256 rewardAmount)
        internal
        pure
        returns (bytes memory)
    {
        return abi.encode(rewardMessageId, rewardAmount);
    }

    function parseRewardMessage(bytes memory message)
        internal
        pure
        returns (bytes32 rewardMessageId, uint256 rewardAmount)
    {
        (rewardMessageId, rewardAmount) = abi.decode(message, (bytes32, uint256));
    }

    function getMessageKindFromMessage(bytes memory message)
        internal
        pure
        returns (uint8 messageKind)
    {
        return uint8(message[0]);
    }

    function getRoundtripIdFromMessage(bytes memory message)
        internal
        pure
        returns (bytes32 roundtripId)
    {
        assembly {
            roundtripId := mload(add(message, 32))
        }
    }
}
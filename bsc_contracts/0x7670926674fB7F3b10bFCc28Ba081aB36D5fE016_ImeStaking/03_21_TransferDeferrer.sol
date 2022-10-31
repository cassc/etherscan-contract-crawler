//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {TimeContext} from "./TimeContext.sol";
import {Sorter} from "../lib/Sorter.sol";

/**
    @title TransferDeferrer
    @author iMe Group
    @notice Contract fragment, responsible for token transfer deferral
 */
abstract contract TransferDeferrer is TimeContext {
    struct DeferredTransfer {
        uint256 amount;
        uint256 notBefore;
    }

    struct TransferQueue {
        mapping(uint32 => DeferredTransfer) transfers;
        uint32 start;
        uint32 end;
    }

    mapping(address => TransferQueue) private _queues;
    uint256 private _totalDeferredTokens = 0;

    /**
        @notice Defer a token transfer
        
        @param to Transfer recipient
        @param amount Amount of tokens to transfer
        @param notBefore Earliest timestamp for actual transfer
     */
    function _deferTransfer(
        address to,
        uint256 amount,
        uint256 notBefore
    ) internal {
        if (amount == 0) {
            return;
        }

        _queues[to].transfers[_queues[to].end] = DeferredTransfer(
            amount,
            notBefore
        );
        _queues[to].end++;

        _totalDeferredTokens += amount;
    }

    /**
        @notice Finalize transfers, which are ready, for certain user.
        Be sure to perform a real transfer of `amount` tokens!

        @return amount Amount of tokens to transfer
     */
    function _finalizeDeferredTransfers(address to)
        internal
        returns (uint256 amount)
    {
        uint32 finalizedTransfers = 0;

        uint32 iQueueStart = _queues[to].start;
        uint32 iQueueEnd = _queues[to].end;

        for (
            uint32 i = iQueueStart;
            i < iQueueEnd && _now() >= _queues[to].transfers[i].notBefore;
            i++
        ) {
            finalizedTransfers++;
            amount += _queues[to].transfers[i].amount;
            delete _queues[to].transfers[i];
        }

        if (finalizedTransfers == 0) {
            return 0;
        }

        if (iQueueStart + finalizedTransfers == iQueueEnd) {
            _queues[to].start = 0;
            _queues[to].end = 0;
            // _queues[to].transfers = 0 // Already nullified
        } else {
            _queues[to].start = iQueueStart + finalizedTransfers;
        }

        _totalDeferredTokens -= amount;
        return amount;
    }

    /**
        @notice Yields amount of deferred tokens for a certain user

        @return pending Amount of tokens, which cannot be transferred yet
        @return ready Amount of tokens, ready to be transferred
     */
    function _deferredTokensOf(address to)
        internal
        view
        returns (uint256 pending, uint256 ready)
    {
        for (uint32 i = _queues[to].start; i < _queues[to].end; i++) {
            DeferredTransfer memory transfer = _queues[to].transfers[i];

            if (_now() >= transfer.notBefore) {
                ready += transfer.amount;
            } else {
                pending += transfer.amount;
            }
        }
    }

    /**
        @notice Yields total amount of deferred tokens
     */
    function _overallDeferredTokens() internal view returns (uint256) {
        return _totalDeferredTokens;
    }
}
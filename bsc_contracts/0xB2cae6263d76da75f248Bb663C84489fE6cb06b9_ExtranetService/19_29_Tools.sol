// SPDX-License-Identifier: Unlicensed
pragma solidity ^0.8.15;

import "../interfaces/IQueueEntry.sol";

library Tools {
    function sumAmountFromQueue(QueueEntry[] memory queue)
        internal
        pure
        returns (uint256 amount)
    {
        for (uint256 i=0; i<queue.length; i++) {
            amount += queue[i].amount;
        }
    }

    function createScaledQueueFromQueue(uint256 mulAmount, uint256 divAmount, QueueEntry[] memory incomingQueue)
        internal
        pure
        returns (QueueEntry[] memory outgoingQueue)
    {
        outgoingQueue = new QueueEntry[](incomingQueue.length);

        for (uint256 i=0; i<incomingQueue.length; i++) {
            QueueEntry memory entry = incomingQueue[i];

            uint256 amount = entry.amount * mulAmount / divAmount;

            outgoingQueue[i] = QueueEntry({
                account: entry.account,
                amount: amount
            });
        }
    }

    // from @uniswap/v2-core/contracts/libraries/Math.sol
    // babylonian method (https://en.wikipedia.org/wiki/Methods_of_computing_square_roots#Babylonian_method)
    function sqrt(uint y)
        internal
        pure
        returns (uint z)
    {
        if (y > 3) {
            z = y;
            uint x = y / 2 + 1;
            while (x < z) {
                z = x;
                x = (y / x + x) / 2;
            }
        } else if (y != 0) {
            z = 1;
        }
    }

    function getSwapAmountForSingleSideUniswap(uint256 amountA, uint256 reserveA, uint256 fee)
        internal
        pure
        returns (uint256)
    {
        return (sqrt(((2000 - fee) * reserveA) ** 2 + 4 * 1000 * (1000 - fee) * amountA * reserveA) - (2000 - fee) * reserveA) / (2 * (1000 - fee));
    }
}
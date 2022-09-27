// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.0;

import {SafeMath} from "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "./LimitOrder.sol";

import "hardhat/console.sol";

/*
 * A library storing data and logic at a pip
 */

library TickPosition {
    using SafeMath for uint128;
    using SafeMath for uint64;
    using LimitOrder for LimitOrder.Data;
    struct Data {
        uint128 liquidity;
        uint64 filledIndex;
        uint64 currentIndex;
        // position at a certain tick
        // index => order data
        mapping(uint64 => LimitOrder.Data) orderQueue;
    }

    function insertLimitOrder(
        TickPosition.Data storage self,
        uint128 size,
        bool hasLiquidity,
        bool isBuy
    ) internal returns (uint64) {
        self.currentIndex++;
        if (
            !hasLiquidity &&
            self.filledIndex != self.currentIndex &&
            self.liquidity != 0
        ) {
            // means it has liquidity but is not set currentIndex yet
            // reset the filledIndex to fill all
            self.filledIndex = self.currentIndex;
            self.liquidity = size;
        } else {
            self.liquidity = self.liquidity + size;
        }
        self.orderQueue[self.currentIndex].update(isBuy, size);
        return self.currentIndex;
    }

    function updateOrderWhenClose(
        TickPosition.Data storage self,
        uint64 orderId
    ) internal returns (uint256) {
        return self.orderQueue[orderId].updateWhenClose();
    }

    function getQueueOrder(TickPosition.Data storage self, uint64 orderId)
        internal
        view
        returns (
            bool isFilled,
            bool isBuy,
            uint256 size,
            uint256 partialFilled
        )
    {
        (isBuy, size, partialFilled) = self.orderQueue[orderId].getData();
        if (self.filledIndex > orderId && size != 0) {
            isFilled = true;
        } else if (self.filledIndex < orderId) {
            isFilled = false;
        } else {
            isFilled = partialFilled >= size && size != 0 ? true : false;
        }
    }

    function partiallyFill(TickPosition.Data storage _self, uint128 _amount)
        internal
    {
        _self.liquidity -= _amount;
        unchecked {
            uint64 index = _self.filledIndex;
            uint128 totalSize = 0;
            if (
                _self.orderQueue[index].size ==
                _self.orderQueue[index].partialFilled
            ) {
                index++;
            }
            if (_self.orderQueue[index].partialFilled != 0) {
                totalSize += (_self.orderQueue[index].size -
                    _self.orderQueue[index].partialFilled);
                index++;
            }
            while (totalSize < _amount) {
                totalSize += _self.orderQueue[index].size;
                index++;
            }
            index--;
            _self.filledIndex = index;
            _self.orderQueue[index].updatePartialFill(
                uint120(totalSize - _amount)
            );
        }
    }

    function calculatingFilledIndex(TickPosition.Data storage self)
        internal
        view
        returns (uint64)
    {
        if (self.filledIndex == self.currentIndex && self.currentIndex > 0) {
            return self.filledIndex - 1;
        }

        return self.filledIndex;
    }

    function cancelLimitOrder(TickPosition.Data storage self, uint64 orderId)
        internal
        returns (
            uint256,
            uint256,
            bool
        )
    {
        (bool isBuy, uint256 size, uint256 partialFilled) = self
            .orderQueue[orderId]
            .getData();
        if (self.liquidity >= uint128(size - partialFilled)) {
            self.liquidity = self.liquidity - uint128(size - partialFilled);
        }
        self.orderQueue[orderId].update(isBuy, partialFilled);

        return (size - partialFilled, partialFilled, isBuy);
    }
}
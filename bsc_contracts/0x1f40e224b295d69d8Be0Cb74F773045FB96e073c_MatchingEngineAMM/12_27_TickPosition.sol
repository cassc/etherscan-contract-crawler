// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.9;

import {SafeMath} from "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "./LimitOrder.sol";

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

    /// @notice insert the limit order to queue in the pip
    /// @param _size the size of order
    /// @param _isBuy the side of order
    /// @param _hasLiquidity the flag check pip have liquidity before insert
    /// @return _orderId the id of order
    function insertLimitOrder(
        TickPosition.Data storage _self,
        uint128 _size,
        bool _hasLiquidity,
        bool _isBuy
    ) internal returns (uint64) {
        _self.currentIndex++;
        if (
            !_hasLiquidity &&
            _self.filledIndex != _self.currentIndex &&
            _self.liquidity != 0
        ) {
            // means it has liquidity but is not set currentIndex yet
            // reset the filledIndex to fill all
            _self.filledIndex = _self.currentIndex;
            _self.liquidity = _size;
        } else {
            _self.liquidity = _self.liquidity + _size;
        }
        _self.orderQueue[_self.currentIndex].update(_isBuy, _size);
        return _self.currentIndex;
    }

    /// @notice update the order when claim asset of partial order
    /// @param _orderId the id of order
    /// @return the remaining size of order
    function updateOrderWhenClose(
        TickPosition.Data storage _self,
        uint64 _orderId
    ) internal returns (uint256) {
        return _self.orderQueue[_orderId].updateWhenClose();
    }

    /// @notice Get the order by order id
    /// @param _orderId the id of order
    /// @return _isFilled the flag show order is filled
    /// @return _isBuy the side of order
    /// @return _size the _size of order
    /// @return _partialFilled the _size of order filled
    function getQueueOrder(
        TickPosition.Data storage _self,
        uint64 _orderId
    )
        internal
        view
        returns (
            bool _isFilled,
            bool _isBuy,
            uint256 _size,
            uint256 _partialFilled
        )
    {
        (_isBuy, _size, _partialFilled) = _self.orderQueue[_orderId].getData();
        if (_self.filledIndex > _orderId && _size != 0) {
            _isFilled = true;
        } else if (_self.filledIndex < _orderId) {
            _isFilled = false;
        } else {
            _isFilled = _partialFilled >= _size && _size != 0 ? true : false;
        }
    }

    /// @notice update the order to partial fill when market trade
    /// @param _amount the amount fill
    function partiallyFill(
        TickPosition.Data storage _self,
        uint128 _amount
    ) internal {
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

    /// @notice update the order to full fill when market trade
    function fullFillLiquidity(TickPosition.Data storage _self) internal {
        uint64 _currentIndex = _self.currentIndex;
        _self.liquidity = 0;
        _self.filledIndex = _currentIndex;
        _self.orderQueue[_currentIndex].partialFilled = _self
            .orderQueue[_currentIndex]
            .size;
    }

    /// @notice update the order when cancel limit order
    /// @param _orderId the id of order
    function cancelLimitOrder(
        TickPosition.Data storage _self,
        uint64 _orderId
    ) internal returns (uint256, uint256, bool) {
        (bool _isBuy, uint256 _size, uint256 _partialFilled) = _self
            .orderQueue[_orderId]
            .getData();
        if (_self.liquidity >= uint128(_size - _partialFilled)) {
            _self.liquidity = _self.liquidity - uint128(_size - _partialFilled);
        }
        _self.orderQueue[_orderId].update(_isBuy, _partialFilled);

        return (_size - _partialFilled, _partialFilled, _isBuy);
    }
}
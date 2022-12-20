// SPDX-License-Identifier: UNLCIENSED

pragma solidity >=0.8.0;

import {Side} from "../interfaces/IPool.sol";
import {SignedInt, SignedIntOps} from "./SignedInt.sol";

library PositionUtils {
    using SignedIntOps for SignedInt;

    function calcPnl(Side _side, uint256 _positionSize, uint256 _entryPrice, uint256 _indexPrice)
        internal
        pure
        returns (SignedInt memory)
    {
        if (_positionSize == 0) {
            return SignedIntOps.wrap(uint256(0));
        }
        if (_side == Side.LONG) {
            return SignedIntOps.wrap(_indexPrice).sub(_entryPrice).mul(_positionSize).div(_entryPrice);
        } else {
            return SignedIntOps.wrap(_entryPrice).sub(_indexPrice).mul(_positionSize).div(_entryPrice);
        }
    }

    /// @notice calculate new avg entry price when increase position
    /// @dev for longs: nextAveragePrice = (nextPrice * nextSize)/ (nextSize + delta)
    ///      for shorts: nextAveragePrice = (nextPrice * nextSize) / (nextSize - delta)
    function calcAveragePrice(
        Side _side,
        uint256 _lastSize,
        uint256 _increasedSize,
        uint256 _entryPrice,
        uint256 _nextPrice
    ) internal pure returns (uint256) {
        if (_lastSize == 0) {
            return _nextPrice;
        }
        SignedInt memory pnl = calcPnl(_side, _lastSize, _entryPrice, _nextPrice);
        SignedInt memory nextSize = SignedIntOps.wrap(_lastSize + _increasedSize);
        SignedInt memory divisor = _side == Side.LONG ? nextSize.add(pnl) : nextSize.sub(pnl);
        return nextSize.mul(_nextPrice).div(divisor).toUint();
    }
}
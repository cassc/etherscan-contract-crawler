// SPDX-License-Identifier: GPL-3.0-or-later
// Deployed with donations via Gitcoin GR9

pragma solidity 0.7.5;

import 'IReserves.sol';
import 'IERC20.sol';
import 'SafeMath.sol';

contract Reserves is IReserves {
    using SafeMath for uint256;

    uint112 private reserve0;
    uint112 private reserve1;
    uint32 private lastTimestamp;

    uint112 private reference0;
    uint112 private reference1;
    uint32 private lastEpoch;

    uint256 private fee0;
    uint256 private fee1;

    function getReserves()
        public
        view
        override
        returns (
            uint112,
            uint112,
            uint32
        )
    {
        return (reserve0, reserve1, lastTimestamp);
    }

    function setReserves(
        uint112 _reserve0,
        uint112 _reserve1,
        uint32 _lastTimestamp
    ) private {
        require(_reserve0 != 0 && _reserve1 != 0, 'RS_ZERO');
        reserve0 = _reserve0;
        reserve1 = _reserve1;
        lastTimestamp = _lastTimestamp;
        emit Sync(reserve0, reserve1);
    }

    function getReferences()
        public
        view
        override
        returns (
            uint112,
            uint112,
            uint32
        )
    {
        return (reference0, reference1, lastEpoch);
    }

    function setReferencesToReserves(uint32 _lastEpoch) internal {
        reference0 = reserve0;
        reference1 = reserve1;
        lastEpoch = _lastEpoch;
    }

    function updateReserves(uint256 balance0, uint256 balance1) internal {
        require(balance0 <= uint112(-1) && balance1 <= uint112(-1), 'RS_OVERFLOW');
        uint32 blockTimestamp = uint32(block.timestamp % 2**32);
        setReserves(uint112(balance0), uint112(balance1), blockTimestamp);
    }

    function adjustReserves(uint256 balance0, uint256 balance1) internal {
        (uint112 _reserve0, uint112 _reserve1, ) = getReserves();
        if (_reserve0 != balance0 || _reserve1 != balance1) {
            updateReserves(balance0, balance1);
            updateReferences(
                uint256(reference0).add(reserve0).sub(_reserve0),
                uint256(reference1).add(reserve1).sub(_reserve1)
            );
        }
    }

    function syncReserves(address token0, address token1) internal {
        uint256 balance0 = IERC20(token0).balanceOf(address(this));
        uint256 balance1 = IERC20(token1).balanceOf(address(this));
        (uint112 _reserve0, uint112 _reserve1, ) = getReserves();

        uint256 oldBalance0 = fee0.add(_reserve0);
        uint256 oldBalance1 = fee1.add(_reserve1);
        fee0 = oldBalance0 != 0 ? fee0.mul(balance0).div(oldBalance0) : fee0;
        fee1 = oldBalance1 != 0 ? fee1.mul(balance1).div(oldBalance1) : fee1;

        uint256 newReserve0 = balance0.sub(fee0);
        uint256 newReserve1 = balance1.sub(fee1);
        if (_reserve0 != newReserve0 || _reserve1 != newReserve1) {
            updateReserves(newReserve0, newReserve1);
            updateReferences(
                uint256(reference0).add(reserve0).sub(_reserve0),
                uint256(reference1).add(reserve1).sub(_reserve1)
            );
        }
    }

    function updateReferences(uint256 _reference0, uint256 _reference1) private {
        require(_reference0 <= uint112(-1) && _reference1 <= uint112(-1), 'RS_OVERFLOW');
        reference0 = uint112(_reference0);
        reference1 = uint112(_reference1);
    }

    function getFees() public view override returns (uint256, uint256) {
        return (fee0, fee1);
    }

    function addFees(uint256 _fee0, uint256 _fee1) internal {
        setFees(fee0.add(_fee0), fee1.add(_fee1));
    }

    function setFees(uint256 _fee0, uint256 _fee1) internal {
        fee0 = _fee0;
        fee1 = _fee1;
        emit Fees(fee0, fee1);
    }

    function getBalances(address token0, address token1) internal returns (uint256, uint256) {
        uint256 balance0 = IERC20(token0).balanceOf(address(this));
        uint256 balance1 = IERC20(token1).balanceOf(address(this));
        if (fee0 > balance0) {
            fee0 = balance0;
            emit Fees(fee0, fee1);
        }
        if (fee1 > balance1) {
            fee1 = balance1;
            emit Fees(fee0, fee1);
        }
        return (balance0.sub(fee0), balance1.sub(fee1));
    }
}
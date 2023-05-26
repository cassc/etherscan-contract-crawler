// SPDX-License-Identifier: GPL-3.0-or-later
// Deployed with donations via Gitcoin GR9

pragma solidity 0.7.6;

import '../interfaces/IReserves.sol';
import '../interfaces/IERC20.sol';
import '../libraries/SafeMath.sol';

contract Reserves is IReserves {
    using SafeMath for uint256;

    uint112 private reserve0;
    uint112 private reserve1;

    uint112 private fee0;
    uint112 private fee1;

    function getReserves() public view override returns (uint112, uint112) {
        return (reserve0, reserve1);
    }

    function setReserves(uint256 balance0MinusFee, uint256 balance1MinusFee) internal {
        require(balance0MinusFee != 0 && balance1MinusFee != 0, 'RS09');
        reserve0 = balance0MinusFee.toUint112();
        reserve1 = balance1MinusFee.toUint112();
    }

    function syncReserves(address token0, address token1) internal {
        uint256 balance0 = IERC20(token0).balanceOf(address(this));
        uint256 balance1 = IERC20(token1).balanceOf(address(this));

        uint256 oldBalance0 = uint256(reserve0) + fee0;
        uint256 oldBalance1 = uint256(reserve1) + fee1;

        if (balance0 != oldBalance0 || balance1 != oldBalance1) {
            if (oldBalance0 != 0) {
                fee0 = (balance0.mul(fee0).div(oldBalance0)).toUint112();
            }
            if (oldBalance1 != 0) {
                fee1 = (balance1.mul(fee1).div(oldBalance1)).toUint112();
            }

            setReserves(balance0.sub(fee0), balance1.sub(fee1));
        }
    }

    function getFees() public view override returns (uint256, uint256) {
        return (fee0, fee1);
    }

    function addFees(uint256 _fee0, uint256 _fee1) internal {
        setFees(_fee0.add(fee0), _fee1.add(fee1));
    }

    function setFees(uint256 _fee0, uint256 _fee1) internal {
        fee0 = _fee0.toUint112();
        fee1 = _fee1.toUint112();
    }

    function getBalances(address token0, address token1) internal returns (uint256, uint256) {
        uint256 balance0 = IERC20(token0).balanceOf(address(this));
        uint256 balance1 = IERC20(token1).balanceOf(address(this));
        if (fee0 > balance0) {
            fee0 = uint112(balance0);
        }
        if (fee1 > balance1) {
            fee1 = uint112(balance1);
        }
        return (balance0.sub(fee0), balance1.sub(fee1));
    }
}
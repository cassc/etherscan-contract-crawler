// SPDX-License-Identifier: GPL-3.0
pragma solidity =0.5.16;
// a library for performing various math operations
import "./SafeMath.sol";
import "hardhat/console.sol";
library Math {
    using SafeMath for uint256;

    function clamp(uint x, uint min, uint max) internal pure returns (uint z) {
        z = x <= min ? min : x >= max ? max : x;
    }
    function min(uint x, uint y) internal pure returns (uint z) {
        z = x < y ? x : y;
    }
    function max(uint x, uint y) internal pure returns (uint z) {
        z = x > y ? x : y;
    }
    // babylonian method (https://en.wikipedia.org/wiki/Methods_of_computing_square_roots#Babylonian_method)
    function sqrt(uint y) internal pure returns (uint z) {
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

    function absoluteDiff(uint value1, uint value2) pure internal returns (uint abs) {
        if (value1 >= value2) {
            abs = value1 - value2;
        } else {
            abs = value2 - value1;
        }
    }

    // This function takes two variables and look at the maximum possible with the ration given by the reserves
    // @pR0, @pR1 the pair reserves
    // @b0, @b1 the balances to calculate
    function _getMaximum(uint _reserve0, uint _reserve1, uint _b0, uint _b1) pure internal returns (uint maxX, uint maxY)  {

        //Expresses b1 in units of reserve0
        uint px = _reserve0.mul(_b1)/_reserve1;

        if (px > _b0) {
            maxX = _b0;
            maxY = _b0.mul(_reserve1)/_reserve0; //b0 in units of reserve1
        } else {
            maxX = px; //max is b1 but in reserve0 units
            maxY = _b1;
        }
    }

//
//    function _unDecimalize(uint _value, uint _decimals) view internal returns (uint) {
//        return 18 > _decimals ? _value/(10**(18 - _decimals)) : _value*(10**(_decimals - 18));
//
//    }
//    // This is a helper function to put all the decimals to 18
//    function _decimalize(uint _value, uint _decimals) view internal returns (uint) {
//        return 18 > _decimals ? _value*(10**(18 - _decimals)) : _value/(10**(_decimals - 18));
//    }




}
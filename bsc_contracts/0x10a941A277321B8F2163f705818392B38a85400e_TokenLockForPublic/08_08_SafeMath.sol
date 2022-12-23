// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.0;

// a library for performing overflow-safe math, courtesy of DappHub (https://github.com/dapphub/ds-math)

library SafeMath {
    function add(uint x, uint y) internal pure returns (uint z) {
        unchecked {
            z = x + y;
            require(z >= x, 'ds-math-add-overflow');
        }
    }

    function sub(uint x, uint y) internal pure returns (uint z) {
        require(x >= y, 'ds-math-sub-underflow');
        z = x - y;
    }

    function mul(uint x, uint y) internal pure returns (uint z) {
        unchecked {
            z = x * y;
            require(y == 0 || z / y == x, 'ds-math-mul-overflow');
        }
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b != 0, 'ds-math-div-overflow');
        return a / b;
    }
}

// SPDX-License-Identifier: GPL-3.0-or-later
// Deployed with donations via Gitcoin GR9

pragma solidity 0.7.6;

// a library for performing overflow-safe math, courtesy of DappHub (https://github.com/dapphub/ds-math)

library SafeMath {
    int256 private constant _INT256_MIN = -2**255;

    function add(uint256 x, uint256 y) internal pure returns (uint256 z) {
        require((z = x + y) >= x, 'SM4E');
    }

    function sub(uint256 x, uint256 y) internal pure returns (uint256 z) {
        z = sub(x, y, 'SM12');
    }

    function sub(
        uint256 x,
        uint256 y,
        string memory message
    ) internal pure returns (uint256 z) {
        require((z = x - y) <= x, message);
    }

    function mul(uint256 x, uint256 y) internal pure returns (uint256 z) {
        require(y == 0 || (z = x * y) / y == x, 'SM2A');
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b > 0, 'SM43');
        return a / b;
    }

    function ceil_div(uint256 a, uint256 b) internal pure returns (uint256 c) {
        c = div(a, b);
        if (a != mul(b, c)) {
            return add(c, 1);
        }
    }

    function toUint32(uint256 n) internal pure returns (uint32) {
        require(n <= type(uint32).max, 'SM50');
        return uint32(n);
    }

    function toUint112(uint256 n) internal pure returns (uint112) {
        require(n <= type(uint112).max, 'SM51');
        return uint112(n);
    }

    function toInt256(uint256 unsigned) internal pure returns (int256 signed) {
        require(unsigned <= uint256(type(int256).max), 'SM34');
        signed = int256(unsigned);
    }

    // int256

    function add(int256 a, int256 b) internal pure returns (int256 c) {
        c = a + b;
        require((b >= 0 && c >= a) || (b < 0 && c < a), 'SM4D');
    }

    function sub(int256 a, int256 b) internal pure returns (int256 c) {
        c = a - b;
        require((b >= 0 && c <= a) || (b < 0 && c > a), 'SM11');
    }

    function mul(int256 a, int256 b) internal pure returns (int256 c) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
        if (a == 0) {
            return 0;
        }

        require(!(a == -1 && b == _INT256_MIN), 'SM29');

        c = a * b;
        require(c / a == b, 'SM29');
    }

    function div(int256 a, int256 b) internal pure returns (int256) {
        require(b != 0, 'SM43');
        require(!(b == -1 && a == _INT256_MIN), 'SM42');

        return a / b;
    }

    function neg_floor_div(int256 a, int256 b) internal pure returns (int256 c) {
        c = div(a, b);
        if ((a < 0 && b > 0) || (a >= 0 && b < 0)) {
            if (a != mul(b, c)) {
                c = sub(c, 1);
            }
        }
    }
}
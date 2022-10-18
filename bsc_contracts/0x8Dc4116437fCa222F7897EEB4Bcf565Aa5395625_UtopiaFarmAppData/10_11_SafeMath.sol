// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

contract SafeMath {
    function add(uint256 x, uint256 y) internal pure returns (uint256 z) {
        require((z = x + y) >= x, 'ds-math-add-overflow');
    }

    function sub(uint x, uint y) internal pure returns (uint256 z) {
        require((z = x - y) <= x, 'ds-math-sub-underflow');
    }

    function mul(uint256 x, uint256 y) internal pure returns (uint256 z) {
        require(y == 0 || (z = x * y) / y == x, 'ds-math-mul-overflow');
    }

    function div(uint256 x, uint256 y) internal pure returns(uint256 z) {
        require(y > 0, "factor should not be zero");
        z = x / y;
    }
}

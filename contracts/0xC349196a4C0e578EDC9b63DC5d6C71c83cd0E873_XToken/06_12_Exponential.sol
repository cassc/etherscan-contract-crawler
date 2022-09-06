// SPDX-License-Identifier: MIT

pragma solidity ^0.8.2;

import "./library/SafeMath.sol";

contract Exponential {
    uint256 constant expScale = 1e18;
    uint256 constant halfExpScale = expScale / 2;

    using SafeMath for uint256;

    function getExp(uint256 num, uint256 denom)
        public
        pure
        returns (uint256 rational)
    {
        rational = num.mul(expScale).div(denom);
    }

    function getDiv(uint256 num, uint256 denom)
        public
        pure
        returns (uint256 rational)
    {
        rational = num.mul(expScale).div(denom);
    }

    function addExp(uint256 a, uint256 b) public pure returns (uint256 result) {
        result = a.add(b);
    }

    function subExp(uint256 a, uint256 b) public pure returns (uint256 result) {
        result = a.sub(b);
    }

    function mulExp(uint256 a, uint256 b) public pure returns (uint256) {
        uint256 doubleScaledProduct = a.mul(b);

        uint256 doubleScaledProductWithHalfScale = halfExpScale.add(
            doubleScaledProduct
        );

        return doubleScaledProductWithHalfScale.div(expScale);
    }

    function divExp(uint256 a, uint256 b) public pure returns (uint256) {
        return getDiv(a, b);
    }

    function mulExp3(
        uint256 a,
        uint256 b,
        uint256 c
    ) external pure returns (uint256) {
        return mulExp(mulExp(a, b), c);
    }

    function mulScalar(uint256 a, uint256 scalar)
        public
        pure
        returns (uint256 scaled)
    {
        scaled = a.mul(scalar);
    }

    function mulScalarTruncate(uint256 a, uint256 scalar)
        public
        pure
        returns (uint256)
    {
        uint256 product = mulScalar(a, scalar);
        return truncate(product);
    }

    function mulScalarTruncateAddUInt(
        uint256 a,
        uint256 scalar,
        uint256 addend
    ) external pure returns (uint256) {
        uint256 product = mulScalar(a, scalar);
        return truncate(product).add(addend);
    }

    function divScalarByExpTruncate(uint256 scalar, uint256 divisor)
        public
        pure
        returns (uint256)
    {
        uint256 fraction = divScalarByExp(scalar, divisor);
        return truncate(fraction);
    }

    function divScalarByExp(uint256 scalar, uint256 divisor)
        public
        pure
        returns (uint256)
    {
        uint256 numerator = expScale.mul(scalar);
        return getExp(numerator, divisor);
    }

    function divScalar(uint256 a, uint256 scalar)
        external
        pure
        returns (uint256)
    {
        return a.div(scalar);
    }

    function truncate(uint256 exp) public pure returns (uint256) {
        return exp.div(expScale);
    }
}
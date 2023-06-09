// SPDX-License-Identifier: MIT
pragma solidity ^0.6.12;

import "openzeppelin-solidity/contracts/math/SafeMath.sol";

struct AttoDecimal {
    uint256 mantissa;
}

library AttoDecimalLib {
    using SafeMath for uint256;

    uint256 internal constant BASE = 10;
    uint256 internal constant EXPONENTIATION = 18;
    uint256 internal constant ONE_MANTISSA = BASE**EXPONENTIATION;
    uint256 internal constant SQUARED_ONE_MANTISSA = ONE_MANTISSA * ONE_MANTISSA;

    function convert(uint256 integer) internal pure returns (AttoDecimal memory) {
        return AttoDecimal({mantissa: integer.mul(ONE_MANTISSA)});
    }

    function add(AttoDecimal memory a, AttoDecimal memory b) internal pure returns (AttoDecimal memory) {
        return AttoDecimal({mantissa: a.mantissa.add(b.mantissa)});
    }

    function sub(AttoDecimal memory a, uint256 b) internal pure returns (AttoDecimal memory) {
        return AttoDecimal({mantissa: a.mantissa.sub(b.mul(ONE_MANTISSA))});
    }

    function sub(AttoDecimal memory a, AttoDecimal memory b) internal pure returns (AttoDecimal memory) {
        return AttoDecimal({mantissa: a.mantissa.sub(b.mantissa)});
    }

    function mul(AttoDecimal memory a, uint256 b) internal pure returns (AttoDecimal memory) {
        return AttoDecimal({mantissa: a.mantissa.mul(b)});
    }

    function div(uint256 a, uint256 b) internal pure returns (AttoDecimal memory) {
        return AttoDecimal({mantissa: a.mul(ONE_MANTISSA).div(b)});
    }

    function div(uint256 a, AttoDecimal memory b) internal pure returns (AttoDecimal memory) {
        return AttoDecimal({mantissa: a.mul(SQUARED_ONE_MANTISSA).div(b.mantissa)});
    }

    function div(AttoDecimal memory a, AttoDecimal memory b) internal pure returns (AttoDecimal memory) {
        return AttoDecimal({mantissa: a.mantissa.mul(ONE_MANTISSA).div(b.mantissa)});
    }

    function ceil(AttoDecimal memory a) internal pure returns (uint256) {
        return a.mantissa.div(ONE_MANTISSA).add(a.mantissa % ONE_MANTISSA > 0 ? 1 : 0);
    }

    function floor(AttoDecimal memory a) internal pure returns (uint256) {
        return a.mantissa.div(ONE_MANTISSA);
    }

    function lte(AttoDecimal memory a, AttoDecimal memory b) internal pure returns (bool) {
        return a.mantissa <= b.mantissa;
    }

    function toTuple(AttoDecimal memory a)
        internal
        pure
        returns (
            uint256 mantissa,
            uint256 base,
            uint256 exponentiation
        )
    {
        return (a.mantissa, BASE, EXPONENTIATION);
    }
}
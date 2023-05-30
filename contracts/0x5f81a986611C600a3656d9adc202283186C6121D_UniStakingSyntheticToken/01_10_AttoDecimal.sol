// SPDX-License-Identifier: UNLICENSED
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

    function convert(uint256 integer) internal pure returns (AttoDecimal memory) {
        return AttoDecimal({mantissa: integer.mul(ONE_MANTISSA)});
    }

    function add(AttoDecimal memory a, uint256 b) internal pure returns (AttoDecimal memory) {
        return  AttoDecimal({mantissa: a.mantissa.add(b.mul(ONE_MANTISSA))});
    }

    function add(AttoDecimal memory a, AttoDecimal memory b) internal pure returns (AttoDecimal memory) {
        return AttoDecimal({mantissa: a.mantissa.add(b.mantissa)});
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

    function div(AttoDecimal memory a, uint256 b) internal pure returns (AttoDecimal memory) {
        return AttoDecimal({mantissa: a.mantissa.div(b)});
    }

    function div(AttoDecimal memory a, AttoDecimal memory b) internal pure returns (AttoDecimal memory) {
        return AttoDecimal({mantissa: a.mantissa.mul(ONE_MANTISSA).div(b.mantissa)});
    }

    function idiv(uint256 a, AttoDecimal memory b) internal pure returns (uint256) {
        return a.mul(ONE_MANTISSA).div(b.mantissa);
    }

    function idivCeil(uint256 a, AttoDecimal memory b) internal pure returns (uint256) {
        uint256 dividend = a.mul(ONE_MANTISSA);
        bool addOne = dividend.mod(b.mantissa) > 0;
        return dividend.div(b.mantissa).add(addOne ? 1 : 0);
    }

    function ceil(AttoDecimal memory a) internal pure returns (uint256) {
        uint256 integer = floor(a);
        uint256 modulo = a.mantissa.mod(ONE_MANTISSA);
        return integer.add(modulo >= ONE_MANTISSA.div(2) ? 1 : 0);
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
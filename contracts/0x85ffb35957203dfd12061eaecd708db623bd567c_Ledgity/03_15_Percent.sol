pragma solidity ^0.6.12;

import "./SafeMath.sol";


library Percent {
    using SafeMath for uint256;

    struct Percent {
        uint128 numerator;
        uint128 denominator;
    }

    function encode(uint128 numerator, uint128 denominator) internal pure returns (Percent memory) {
        require(numerator <= denominator, "Percent: invalid percentage");
        return Percent(numerator, denominator);
    }

    function mul(Percent memory self, uint256 value) internal pure returns (uint256) {
        return value.mul(uint256(self.numerator)).div(uint256(self.denominator));
    }

    function lte(Percent memory self, Percent memory other) internal pure returns (bool) {
        return uint256(self.numerator).mul(other.denominator) <= uint256(other.numerator).mul(self.denominator);
    }
}
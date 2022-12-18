pragma solidity >=0.8.0;

library MathUtils {
    function diff(uint256 a, uint256 b) internal pure returns (uint256) {
        unchecked {
            return a > b ? a - b : b - a;
        }
    }

    function zeroCapSub(uint256 a, uint256 b) internal pure returns (uint256) {
        unchecked {
            return a > b ? a - b : 0;
        }
    }

    function frac(uint256 amount, uint256 num, uint256 denom) internal pure returns (uint256) {
        return amount * num / denom;
    }

    function min(uint256 a, uint256 b) internal pure returns (uint256) {
        return a < b ? a : b;
    }
}
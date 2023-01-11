pragma solidity =0.5.16;

import "./interfaces/ISolidlyBaseV1Pair.sol";
import "./interfaces/ITarotSolidlyPriceOracleV2.sol";

contract TarotSolidlyPriceOracleV2 is ITarotSolidlyPriceOracleV2 {
    uint32 public constant MIN_T = 900;

    function safe112(uint256 n) internal pure returns (uint112) {
        require(n < 2**112, "TarotSolidlyPriceOracleV2: SAFE112");
        return uint112(n);
    }

    function getResult(address pair) external returns (uint112 reserve0, uint112 reserve1, uint32 T) {
        (
            uint256 reserve0CumulativeCurrent,
            uint256 reserve1CumulativeCurrent,
            uint256 blockTimestampCurrent
        ) = ISolidlyBaseV1Pair(pair).currentCumulativePrices();
        uint256 observationLength = ISolidlyBaseV1Pair(pair).observationLength();
        (
            uint256 blockTimestampLast,
            uint256 reserve0CumulativeLast,
            uint256 reserve1CumulativeLast
        ) = ISolidlyBaseV1Pair(pair).observations(observationLength - 1);
        T = uint32(blockTimestampCurrent - blockTimestampLast);
        if (T < MIN_T) {
            (
                blockTimestampLast,
                reserve0CumulativeLast,
                reserve1CumulativeLast
            ) = ISolidlyBaseV1Pair(pair).observations(observationLength - 2);
            T = uint32(blockTimestampCurrent - blockTimestampLast);
        }
        reserve0 = safe112((reserve0CumulativeCurrent - reserve0CumulativeLast) / T);
        reserve1 = safe112((reserve1CumulativeCurrent - reserve1CumulativeLast) / T);
    }
}
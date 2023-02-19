pragma solidity >=0.5;

interface ITarotSolidlyPriceOracleV2 {
    function MIN_T() external pure returns (uint32);

    function getResult(address pair) external returns (uint112 reserve0, uint112 reserve1, uint32 T);
}
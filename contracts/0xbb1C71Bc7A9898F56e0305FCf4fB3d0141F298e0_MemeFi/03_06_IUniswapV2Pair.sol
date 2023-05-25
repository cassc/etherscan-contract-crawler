pragma solidity >=0.5.0;

interface IUniswapV2Pair {
    function balanceOf(address owner) external view returns (uint);
    function sync() external;
}
pragma solidity 0.6.12;

interface IUniswapOracle {
    function update(address token) external;

    function consult(address token, uint amountIn) external view returns (uint amountOut);
}